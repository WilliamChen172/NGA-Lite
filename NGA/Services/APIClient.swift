//
//  APIClient.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Logging

actor APIClient {
    static let shared = APIClient()
    private let log = Logger.for(.api)

    private var authToken: String?
    private var accessUid: Int?
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func setAuthToken(_ token: String?) {
        log.debug("setAuthToken called, hasToken=\(token != nil)")
        authToken = token
    }

    func setAccessUid(_ uid: Int?) {
        accessUid = uid
    }

    /// Logged in: app_api subject/list. Logged out: thread.php (MNGA-style, JSON).
    func fetchThreadList(fid: Int, page: Int, orderBy: String = Constants.API.orderByLastPost, recommendOnly: Bool = false) async throws -> [ForumThread] {
        if isLoggedIn {
            return try await fetchThreadListLoggedIn(fid: fid, page: page, orderBy: orderBy, recommendOnly: recommendOnly)
        } else {
            return try await fetchThreadListLoggedOut(fid: fid, page: page, orderBy: orderBy, recommendOnly: recommendOnly)
        }
    }

    /// Logged in: app_api post/list. Logged out: read.php (MNGA-style, JSON).
    func fetchPostList(tid: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        if isLoggedIn {
            return try await fetchPostListLoggedIn(tid: tid, page: page)
        } else {
            return try await fetchPostListLoggedOut(tid: tid, page: page)
        }
    }

    private var isLoggedIn: Bool {
        authToken != nil && accessUid != nil
    }

    // MARK: - Logged in (app_api)

    private func fetchThreadListLoggedIn(fid: Int, page: Int, orderBy: String, recommendOnly: Bool) async throws -> [ForumThread] {
        var body: [String: String] = [
            "fid": "\(fid)",
            "page": "\(page)",
            "order_by": orderBy,
            "app_id": Constants.API.nativeLoginAppId
        ]
        if recommendOnly { body["recommend"] = "1" }
        let json = try await requestJSON(endpoint: .subjectList, params: [:], body: body)
        let threads = try parseSubjectListResponse(json)
        log.debug("[subject/list] fid=\(fid) page=\(page) -> \(threads.count) threads")
        return threads
    }

    private func fetchPostListLoggedIn(tid: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        let body: [String: String] = [
            "tid": "\(tid)",
            "page": "\(page)",
            "app_id": Constants.API.nativeLoginAppId
        ]
        let json = try await requestJSON(endpoint: .postList, params: [:], body: body)
        let result = try parsePostListAppAPI(json)
        log.debug("[post/list] tid=\(tid) page=\(page) -> \(result.posts.count) posts")
        return result
    }

    // MARK: - Logged out (thread.php / read.php, MNGA-style, JSON)

    private func fetchThreadListLoggedOut(fid: Int, page: Int, orderBy: String, recommendOnly: Bool) async throws -> [ForumThread] {
        let bases = [Constants.API.baseURL] + Constants.API.alternateBaseURLs
        var lastError: Error?
        for base in bases {
            do {
                let json = try await fetchThreadPhpJSON(baseURL: base, fid: fid, page: page, orderBy: orderBy, recommendOnly: recommendOnly)
                let threads = try parseThreadListFromThreadPhp(json)
                log.debug("[thread.php] fid=\(fid) page=\(page) -> \(threads.count) threads (unauth)")
                return threads
            } catch {
                lastError = error
                log.warning("[thread.php] unauth failed for \(base): \(error.localizedDescription)")
            }
        }
        throw lastError ?? AppError.decodingFailed
    }

    private func fetchPostListLoggedOut(tid: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        let bases = [Constants.API.baseURL] + Constants.API.alternateBaseURLs
        var lastError: Error?
        for base in bases {
            do {
                let json = try await fetchReadPhpJSON(baseURL: base, tid: tid, page: page)
                let result = try parsePostListFromReadPhp(json)
                log.debug("[read.php] tid=\(tid) page=\(page) -> \(result.posts.count) posts (unauth)")
                return result
            } catch {
                lastError = error
                log.warning("[read.php] unauth failed for \(base): \(error.localizedDescription)")
            }
        }
        throw lastError ?? AppError.decodingFailed
    }

    /// 按 pid 拉取单楼，用于 B1 引用补全。使用 read.php，用法同 tid。
    func fetchPostByPid(pid: Int) async throws -> Post? {
        let bases = [Constants.API.baseURL] + Constants.API.alternateBaseURLs
        var lastError: Error?
        for base in bases {
            do {
                let json = try await fetchReadPhpJSONByPid(baseURL: base, pid: pid)
                if let post = parseSinglePostFromReadPhp(json) {
                    log.debug("[read.php] pid=\(pid) -> post \(post.pid)")
                    return post
                }
            } catch {
                lastError = error
                log.warning("[read.php] pid=\(pid) failed for \(base): \(error.localizedDescription)")
            }
        }
        if let err = lastError { throw err }
        return nil
    }

    private func parseSinglePostFromReadPhp(_ json: [String: Any]) -> Post? {
        guard !isLoginRequiredResponse(json) else { return nil }
        let dataObj = json["data"] as? [String: Any]
        var rObj = dataObj?["__R"] as? [String: Any]
        if rObj == nil, let items = dataObj?["item"] as? [[String: Any]] {
            rObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        guard let r = rObj, !r.isEmpty else { return nil }
        for key in r.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let postDict = r[key] as? [String: Any], let post = postFromDict(postDict) else { continue }
            return post
        }
        return nil
    }

    private func fetchThreadPhpJSON(baseURL: String, fid: Int, page: Int, orderBy: String, recommendOnly: Bool) async throws -> [String: Any] {
        let url = "\(baseURL)/thread.php"
        var body: [String: String] = [
            "fid": "\(fid)",
            "page": "\(page)",
            "__inchst": "UTF8",
            "lite": "js",
            "order_by": orderBy,
            "recommend": recommendOnly ? "1" : "0"
        ]
        let data = try await postToURL(url, body: body)
        return try parseScriptVarJSON(data)
    }

    private func fetchReadPhpJSON(baseURL: String, tid: Int, page: Int) async throws -> [String: Any] {
        let url = "\(baseURL)/read.php"
        let body: [String: String] = [
            "tid": "\(tid)",
            "page": "\(page)",
            "__inchst": "UTF8",
            "lite": "js",
            "v2": "1"
        ]
        let data = try await postToURL(url, body: body)
        return try parseScriptVarJSON(data)
    }

    private func fetchReadPhpJSONByPid(baseURL: String, pid: Int) async throws -> [String: Any] {
        let url = "\(baseURL)/read.php"
        let body: [String: String] = [
            "pid": "\(pid)",
            "__inchst": "UTF8",
            "lite": "js",
            "v2": "1"
        ]
        let data = try await postToURL(url, body: body)
        return try parseScriptVarJSON(data)
    }

    private func postToURL(_ urlString: String, body: [String: String]) async throws -> Data {
        guard let url = URL(string: urlString) else { throw AppError.decodingFailed }
        let bodyStr = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyStr.data(using: .utf8)
        request.setValue("NGA_WP_JW", forHTTPHeaderField: "User-Agent")
        request.setValue(urlString, forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let rawMsg = String(data: data, encoding: .utf8) ?? decodeGB18030(data) ?? ""
            if http.statusCode == 401 {
                NotificationCenter.default.post(name: Constants.NotificationName.unauthorized, object: nil)
                throw AppError.unauthorized
            }
            if http.statusCode == 403, rawMsg.contains("未登录") || rawMsg.contains("登录") {
                throw AppError.loginRequired
            }
            throw AppError.serverError(code: http.statusCode, message: String(rawMsg.prefix(200)))
        }
        return data
    }

    private func parseScriptVarJSON(_ data: Data) throws -> [String: Any] {
        let candidates: [(String, String)] = [
            ("UTF-8", String(data: data, encoding: .utf8) ?? ""),
            ("GB18030", decodeGB18030(data) ?? "")
        ].compactMap { enc, s in s.isEmpty ? nil : (enc, s) }

        for (encoding, raw) in candidates {
            var r = raw
            if r.hasPrefix("\u{FEFF}") { r = String(r.dropFirst(1)) }
            r = r.trimmingCharacters(in: .whitespacesAndNewlines)

            let jsonStr: String
            if let extracted = extractJSONFromScriptVar(r, prefix: "window.script_muti_get_var_store=") {
                jsonStr = extracted
            } else if let idx = r.firstIndex(of: "{"), let extracted = extractJSONByBraceMatch(String(r[idx...])) {
                jsonStr = extracted
            } else if r.trimmingCharacters(in: .whitespaces).hasPrefix("{") {
                jsonStr = r.trimmingCharacters(in: .whitespaces)
            } else if r.contains("window.script_muti_get_var_store=") {
                let start = r.range(of: "window.script_muti_get_var_store=")!
                let after = String(r[start.upperBound...])
                jsonStr = extractJSONFromScriptVar("window.script_muti_get_var_store=" + after, prefix: "window.script_muti_get_var_store=") ?? extractJSONByBraceMatch(after) ?? after
            } else {
                continue
            }

            let sanitized = sanitizeJSONControlChars(jsonStr)
            guard let parseData = sanitized.data(using: .utf8) else { continue }
            do {
                guard let json = try JSONSerialization.jsonObject(with: parseData) as? [String: Any],
                      json["data"] != nil || json["result"] != nil else {
                    continue
                }
                return json
            } catch {
                let nsErr = error as NSError
                let idx = (nsErr.userInfo["NSJSONSerializationErrorIndex"] as? NSNumber)?.intValue ?? 0
                let len = sanitized.count
                let utf8Bytes = sanitized.utf8.count
                let start = idx > len ? max(0, len - 250) : max(0, min(idx - 80, len - 1))
                let snippet: String
                if len > 0, let iStart = sanitized.index(sanitized.startIndex, offsetBy: start, limitedBy: sanitized.endIndex) {
                    let take = min(250, len - start)
                    let iEnd = sanitized.index(iStart, offsetBy: take, limitedBy: sanitized.endIndex) ?? sanitized.endIndex
                    snippet = String(sanitized[iStart..<iEnd])
                        .replacingOccurrences(of: "\n", with: "\\n")
                        .replacingOccurrences(of: "\r", with: "\\r")
                } else {
                    snippet = "len=\(len) idx=\(idx)"
                }
                log.warning("[parseScriptVarJSON] \(encoding) JSON error: \(nsErr.localizedDescription)")
                log.warning("[parseScriptVarJSON] idx=\(idx) chars=\(len) utf8=\(utf8Bytes) | ...\(snippet)...")
                continue
            }
        }

        let sample = String(data: data.prefix(300), encoding: .utf8) ?? String(data: data.prefix(300), encoding: .utf16) ?? "<binary>"
        log.error("[parseScriptVarJSON] failed, \(data.count)B, sample: \(sample)...")
        throw AppError.decodingFailed
    }

    /// Extracts top-level JSON object by brace matching from a string that may have trailing content.
    private func extractJSONByBraceMatch(_ s: String) -> String? {
        guard let i = s.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escape = false
        var quote: Character?
        var idx = s.startIndex
        while idx < s.endIndex {
            let c = s[idx]
            if escape { escape = false } else if c == "\\" && inString { escape = true }
            else if inString { if c == quote { inString = false; quote = nil } }
            else if c == "\"" || c == "'" { inString = true; quote = c }
            else if c == "{" { depth += 1 }
            else if c == "}" { depth -= 1; if depth == 0 { return String(s[i...idx]) } }
            idx = s.index(after: idx)
        }
        return nil
    }

    private func parseThreadListFromThreadPhp(_ json: [String: Any]) throws -> [ForumThread] {
        if isLoginRequiredResponse(json) { throw AppError.loginRequired }
        let dataObj = json["data"] as? [String: Any]
        var tObj = dataObj?["__T"] as? [String: Any]
        if tObj == nil, let items = dataObj?["item"] as? [[String: Any]] {
            tObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        guard let t = tObj, !t.isEmpty else {
            if dataObj != nil && dataObj?["__T"] == nil { return [] }
            throw AppError.decodingFailed
        }
        var threads: [ForumThread] = []
        for key in t.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let threadDict = t[key] as? [String: Any],
                  let thread = threadFromDict(threadDict) else { continue }
            threads.append(thread)
        }
        return threads
    }

    private func parsePostListFromReadPhp(_ json: [String: Any]) throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        if isLoginRequiredResponse(json) { throw AppError.loginRequired }
        let dataObj = json["data"] as? [String: Any]
        var rObj = dataObj?["__R"] as? [String: Any]
        if rObj == nil, let items = dataObj?["item"] as? [[String: Any]] {
            rObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        guard let r = rObj, !r.isEmpty else {
            if dataObj != nil && dataObj?["__R"] == nil { return (posts: [], authorMap: [:]) }
            throw AppError.decodingFailed
        }
        let tObj = dataObj?["__T"] as? [String: Any]
        let topicAuthor = tObj?["author"] as? String
        let topicAuthorId = (tObj?["authorid"] as? Int) ?? (tObj?["authorid"] as? String).flatMap { Int($0) }

        var posts: [Post] = []
        for key in r.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let postDict = r[key] as? [String: Any], var post = postFromDict(postDict) else { continue }
            if post.pid == 0, let author = topicAuthor, (post.author == nil || post.author == "UID:\(post.authorId ?? 0)") {
                post = Post(pid: post.pid, tid: post.tid, fid: post.fid, content: post.content, authorId: post.authorId, author: author, floor: post.floor, postDate: post.postDate, score: post.score, score2: post.score2, fromClient: post.fromClient)
            }
            posts.append(post)
        }
        let fid = posts.first?.fid ?? 0
        let authorMap = parseAuthorMap(dataObj: dataObj, fid: fid, topicAuthorId: topicAuthorId, topicAuthor: topicAuthor)
        return (posts, authorMap)
    }

    /// Vote on a post. value: 1 = 点赞, 2 = 点踩. value: 1 = 点赞 (upvote), 2 = 点踩 (downvote). MNGA uses nuke topic_recommend add.
    func votePost(tid: Int, pid: Int, value: Int) async throws -> Int {
        let body: [String: String] = [
            "__lib": "topic_recommend",
            "__act": "add",
            "value": "\(value)",
            "tid": "\(tid)",
            "pid": "\(pid)"
        ]
        let bodyStr = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
        var components = URLComponents(string: Constants.API.nukeURL)!
        components.queryItems = [URLQueryItem(name: "raw", value: "3")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyStr.data(using: .utf8)
        request.setValue("NGA_skull/7.3.1(iPhone; iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue(Constants.API.nukeURL, forHTTPHeaderField: "Referer")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        log.debug("[vote] tid=\(tid) pid=\(pid) value=\(value)")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if http.statusCode == 401 {
                log.warning("[vote] 401 Unauthorized")
                NotificationCenter.default.post(name: Constants.NotificationName.unauthorized, object: nil)
                throw AppError.unauthorized
            }
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AppError.serverError(code: http.statusCode, message: String(msg.prefix(200)))
        }
        let raw = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) ?? ""
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArr = json["data"] as? [Any],
              dataArr.count > 2,
              let delta = Int("\(dataArr[2])") else {
            return 0
        }
        return delta
    }

    /// Parses __U and __GROUPS from read.php / app_api into [uid: UserInForum].
    /// - __GROUPS: 级别名取自 groupsObj[memberid]["0"]（字典）或首元素（数组）
    /// - 威望: 使用 fame，展示时 ÷10（与 MNGA/nuke.php 一致）
    /// - topicAuthorId/author: 主楼作者名来自 __T，未登录时 __U 可能仅 UID:xxx
    private func parseAuthorMap(dataObj: [String: Any]?, fid: Int, topicAuthorId: Int? = nil, topicAuthor: String? = nil) -> [Int: UserInForum] {
        guard let uObj = dataObj?["__U"] as? [String: Any] else { return [:] }
        let groupsObj = (uObj["__GROUPS"] ?? dataObj?["__GROUPS"]) as? [String: Any]
        var map: [Int: UserInForum] = [:]
        for (key, val) in uObj {
            guard !key.hasPrefix("__"), let userDict = val as? [String: Any] else { continue }
            guard let uid = Int(key) else { continue }

            var username = userDict["username"] as? String
            if uid == topicAuthorId, let topicName = topicAuthor, (username == nil || username == "UID:\(uid)") {
                username = topicName
            }
            let avatar = userDict["avatar"] as? String
            let postnum = (userDict["postnum"] as? Int) ?? (userDict["postnum"] as? String).flatMap { Int($0) }
            let fame = (userDict["fame"] as? Int) ?? (userDict["fame"] as? String).flatMap { Int($0) }
            let memberid = (userDict["memberid"] as? Int) ?? (userDict["memberid"] as? String).flatMap { Int($0) }

            // __GROUPS: {"39":{"0":"用户组名","1":bit,"2":id}}，取 key "0"
            var levelName: String?
            if let mid = memberid {
                if let g = groupsObj?["\(mid)"] as? [String: Any], let name = g["0"] {
                    levelName = "\(name)"
                } else if let g = groupsObj?["\(mid)"] as? [Any], let first = g.first {
                    levelName = "\(first)"
                }
            }

            let user = User(uid: uid, username: username, nickname: nil, avatar: avatar)
            let forumContext = ForumUserContext(fid: fid, levelName: levelName, postnum: postnum, fame: fame)
            map[uid] = UserInForum(user: user, forumContext: forumContext)
        }
        return map
    }

    private func decodeGB18030(_ data: Data) -> String? {
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        return String(data: data, encoding: String.Encoding(rawValue: enc))
    }

    /// NGA returns error/__MESSAGE with "未登录" or 403 when login required for restricted forums.
    private func isLoginRequiredResponse(_ root: [String: Any]) -> Bool {
        if root["error"] != nil { return true }
        let dataObj = root["data"] as? [String: Any]
        let msg = dataObj?["__MESSAGE"] as? [String: Any]
        if let code = msg?["3"] as? Int, code == 403 { return true }
        if let code = msg?["3"] as? String, code == "403" { return true }
        for (_, v) in msg ?? [:] {
            let s = "\(v)"
            if s.contains("未登录") || s.contains("请登录") || s.contains("需要登录") { return true }
        }
        return false
    }

    /// Replaces raw control chars in JSON string values. NGA read.php returns unescaped tab/newline/quote in content.
    private func sanitizeJSONControlChars(_ json: String) -> String {
        var result = json
        result = result.replacingOccurrences(of: "\u{09}", with: "\\t")   // tab
        result = result.replacingOccurrences(of: "\u{0A}", with: "\\n")   // newline
        result = result.replacingOccurrences(of: "\u{0D}", with: "\\r")   // carriage return
        // Remove trailing commas before } or ] (invalid in strict JSON, NGA sometimes returns them)
        while result.contains(",}") || result.contains(",]") {
            result = result.replacingOccurrences(of: ",}", with: "}")
            result = result.replacingOccurrences(of: ",]", with: "]")
        }
        // Escape unescaped " inside string values (NGA post content often has literal quotes)
        result = escapeUnescapedQuotesInJSONStrings(result)
        return result
    }

    /// Fixes unescaped double-quotes inside JSON string values. NGA content has [url="..."] where "
    /// is not escaped. Only treat " as closing when next non-WS is : , } or " (NOT ] - content has ]).
    private func escapeUnescapedQuotesInJSONStrings(_ json: String) -> String {
        var result = ""
        var i = json.startIndex
        var inString = false
        var escape = false

        while i < json.endIndex {
            let c = json[i]

            if escape {
                result.append(c)
                escape = false
            } else if c == "\\" && inString {
                result.append(c)
                escape = true
            } else if c == "\"" {
                if inString {
                    var j = json.index(after: i)
                    while j < json.endIndex {
                        let ch = json[j]
                        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" {
                            j = json.index(after: j)
                        } else {
                            break
                        }
                    }
                    if j < json.endIndex {
                        let next = json[j]
                        if next == ":" || next == "," || next == "}" || next == "\"" {
                            result.append(c)
                            inString = false
                        } else {
                            result.append("\\")
                            result.append(c)
                        }
                    } else {
                        result.append(c)
                        inString = false
                    }
                } else {
                    result.append(c)
                    inString = true
                }
            } else {
                result.append(c)
            }
            i = json.index(after: i)
        }
        return result
    }

    /// Extracts the JSON object from scripts like "window.xxx={...};..." by brace matching.
    private func extractJSONFromScriptVar(_ raw: String, prefix: String) -> String? {
        guard raw.hasPrefix(prefix) else { return nil }
        var s = String(raw.dropFirst(prefix.count))
        s = s.trimmingCharacters(in: .whitespaces)
        guard let first = s.first, first == "{" else { return nil }
        var depth = 0
        var inString = false
        var escape = false
        var quote: Character?
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            if escape {
                escape = false
            } else if c == "\\" && inString {
                escape = true
            } else if inString {
                if c == quote {
                    inString = false
                    quote = nil
                }
            } else if c == "\"" || c == "'" {
                inString = true
                quote = c
            } else if c == "{" {
                depth += 1
            } else if c == "}" {
                depth -= 1
                if depth == 0 {
                    return String(s[...i])
                }
            }
            i = s.index(after: i)
        }
        return nil
    }

    private func parseSubjectListResponse(_ json: [String: Any]) throws -> [ForumThread] {
        if let code = (json["code"] as? Int) ?? (json["code"] as? String).flatMap(Int.init), code != 0 {
            let msg = json["msg"] as? String ?? "未知错误"
            if msg.contains("未登录") || msg.contains("登录") { throw AppError.loginRequired }
            throw AppError.serverError(code: code, message: msg)
        }
        // Prefer threadFromDict to extract img/cover from subject/list (decoder skips extra keys)
        let arr = extractThreadDictArray(from: json)
        let threads = arr.compactMap { threadFromDict($0) }
        if !threads.isEmpty { return threads }
        // Fallback: decoder
        if let resp = try? decoder.decode(ThreadListResponse.self, from: JSONSerialization.data(withJSONObject: json)),
           !resp.threadsList.isEmpty {
            return resp.threadsList
        }
        return []
    }

    private func parsePostListAppAPI(_ json: [String: Any]) throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        if let code = (json["code"] as? Int) ?? (json["code"] as? String).flatMap(Int.init), code != 0 {
            let msg = json["msg"] as? String ?? "未知错误"
            if msg.contains("未登录") || msg.contains("登录") { throw AppError.loginRequired }
            throw AppError.serverError(code: code, message: msg)
        }
        // app_api post/list: result is direct array of posts, each with embedded author
        if let resultArr = json["result"] as? [[String: Any]] {
            var posts: [Post] = []
            var authorMap: [Int: UserInForum] = [:]
            let fid = (json["fid"] as? Int) ?? (json["fid"] as? String).flatMap(Int.init) ?? 0
            for dict in resultArr {
                if let post = postFromDict(dict) {
                    posts.append(post)
                    if let aid = post.authorId, let authorDict = dict["author"] as? [String: Any],
                       authorMap[aid] == nil,
                       let info = userInForumFromAuthorDict(authorDict, fid: fid) {
                        authorMap[aid] = info
                    }
                }
            }
            return (posts, authorMap)
        }
        // Legacy: __R / data format (read.php style)
        var dataObj = (json["result"] as? [String: Any]) ?? (json["data"] as? [String: Any]) ?? json
        if dataObj["__R"] == nil, let inner = dataObj["data"] as? [String: Any] {
            dataObj = inner
        }
        var rObj = dataObj["__R"] as? [String: Any]
        if rObj == nil, let items = dataObj["item"] as? [[String: Any]] {
            rObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        if rObj == nil, let arr = dataObj["data"] as? [[String: Any]] {
            var posts: [Post] = []
            for dict in arr {
                if let post = postFromDict(dict) { posts.append(post) }
            }
            let fid = posts.first?.fid ?? 0
            let authorMap = parseAuthorMap(dataObj: dataObj, fid: fid)
            return (posts, authorMap)
        }
        guard let r = rObj, !r.isEmpty else {
            return (posts: [], authorMap: [:])
        }
        var posts: [Post] = []
        for key in r.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let postDict = r[key] as? [String: Any] else { continue }
            if let post = postFromDict(postDict) { posts.append(post) }
        }
        let fid = posts.first?.fid ?? 0
        let authorMap = parseAuthorMap(dataObj: dataObj, fid: fid)
        return (posts, authorMap)
    }

    /// Build UserInForum from app_api embedded author: { uid, username, avatar, member, postnum, fame }
    private func userInForumFromAuthorDict(_ dict: [String: Any], fid: Int) -> UserInForum? {
        let uid = (dict["uid"] as? Int) ?? (dict["uid"] as? String).flatMap(Int.init)
        guard let uid = uid else { return nil }
        let username = dict["username"] as? String
        let avatar = dict["avatar"] as? String
        let levelName = dict["member"] as? String
        let postnum = (dict["postnum"] as? Int) ?? (dict["postnum"] as? String).flatMap(Int.init)
        let fame = (dict["fame"] as? Int) ?? (dict["fame"] as? String).flatMap(Int.init)
        let user = User(uid: uid, username: username, nickname: nil, avatar: avatar)
        let forumContext = ForumUserContext(fid: fid, levelName: levelName, postnum: postnum, fame: fame)
        return UserInForum(user: user, forumContext: forumContext)
    }

    private func postFromDict(_ dict: [String: Any]) -> Post? {
        let pid = (dict["pid"] as? Int) ?? (dict["pid"] as? String).flatMap(Int.init) ?? 0
        let tid = (dict["tid"] as? Int) ?? (dict["tid"] as? String).flatMap(Int.init) ?? 0
        let fid = (dict["fid"] as? Int) ?? (dict["fid"] as? String).flatMap(Int.init) ?? 0
        let content = dict["content"] as? String
        var authorId = (dict["authorid"] as? Int) ?? (dict["authorid"] as? String).flatMap(Int.init)
        var author = dict["author"] as? String
        if authorId == nil || author == nil, let authorObj = dict["author"] as? [String: Any] {
            authorId = authorId ?? (authorObj["uid"] as? Int) ?? (authorObj["uid"] as? String).flatMap(Int.init)
            author = author ?? (authorObj["username"] as? String)
        }
        let floor = (dict["lou"] as? Int) ?? (dict["floor"] as? Int) ?? (dict["lou"] as? String).flatMap(Int.init) ?? (dict["floor"] as? String).flatMap(Int.init)
        let postDate = (dict["postdatetimestamp"] as? Int) ?? (dict["postdate"] as? Int) ?? (dict["postdatetimestamp"] as? String).flatMap(Int.init) ?? (dict["postdate"] as? String).flatMap(Int.init)
        let score = (dict["score"] as? Int) ?? (dict["vote_good"] as? Int) ?? (dict["score"] as? String).flatMap(Int.init) ?? (dict["vote_good"] as? String).flatMap(Int.init)
        let score2 = (dict["score_2"] as? Int) ?? (dict["vote_bad"] as? Int) ?? (dict["score_2"] as? String).flatMap(Int.init) ?? (dict["vote_bad"] as? String).flatMap(Int.init)
        let fromClient = dict["from_client"] as? String
        return Post(pid: pid, tid: tid, fid: fid, content: content, authorId: authorId, author: author, floor: floor, postDate: postDate, score: score, score2: score2, fromClient: fromClient)
    }

    /// Native 登录 (nuke.php)：app_id=1100, device, password AES 加密，__output=14
    func requestNativeLogin(name: String, type: String, password: String) async throws -> [String: Any] {
        guard let encrypted = AESHelper.encryptECBBase64(
            plainText: password,
            keyHex: Constants.API.nativeLoginAESKeyHex
        ) else {
            log.error("[nativeLogin] AES encrypt failed")
            throw AppError.decodingFailed
        }
        let device = DeviceIdHelper.getOrCreate()
        var bodyParams: [String: String] = [
            "__lib": "login",
            "__act": "login",
            "__output": "14",
            "app_id": Constants.API.nativeLoginAppId,
            "device": device,
            "name": name,
            "type": type,
            "password": encrypted,
            "__inchst": "UTF-8"
        ]
        let bodyStr = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")

        guard let url = URL(string: Constants.API.nukeURL) else { throw AppError.decodingFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyStr.data(using: .utf8)
        request.setValue(Constants.API.userAgent, forHTTPHeaderField: "User-Agent")

        var curlBody = bodyStr
            .components(separatedBy: "&")
            .map { part in part.hasPrefix("password=") ? "password=***REDACTED***" : part }
            .joined(separator: "&")
        log.debug("[nativeLogin] curl: curl -X POST '\(Constants.API.nukeURL)' -d '\(curlBody)'")
        log.debug("[nativeLogin] POST nuke.php name=\(name) type=\(type) device=\(device.prefix(20))...")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            log.debug("[nativeLogin] <- \(http.statusCode)")
        }
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? decodeGB18030(data) ?? ""
            log.error("[nativeLogin] \(http.statusCode) \(msg.prefix(300))")
            throw AppError.serverError(code: http.statusCode, message: String(msg.prefix(200)))
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            log.error("[nativeLogin] invalid JSON: \(String(data: data, encoding: .utf8)?.prefix(500) ?? "")")
            throw AppError.decodingFailed
        }
        log.debug("[nativeLogin] response OK (\(data.count) bytes)")
        return json
    }

    /// forum_favor2 get: POST nuke.php，Cookie/Authorization 鉴权即可，无需 sign
    func requestForumFavorGet() async throws -> [Forum] {
        guard authToken != nil, accessUid != nil else {
            log.warning("[forum_favor2] no token/uid, skipping")
            throw AppError.unauthorized
        }
        let body: [String: String] = ["__output": "14"]
        let (data, _) = try await perform(endpoint: .forumFavorGet, params: [:], body: body)
        return parseForumFavorResponse(data)
    }

    private func parseForumFavorResponse(_ data: Data) -> [Forum] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] else {
            log.warning("[forum_favor2] invalid JSON or no result")
            return []
        }
        if let arr = result as? [[String: Any]] {
            if let first = arr.first, first["groups"] != nil {
                return arr.flatMap { cat -> [Forum] in
                    (cat["groups"] as? [[String: Any]])?.flatMap { group -> [Forum] in
                        (group["forums"] as? [[String: Any]])?.compactMap { forumFromDict($0) } ?? []
                    } ?? []
                }
            }
            return arr.compactMap { forumFromDict($0) }
        }
        if let obj = result as? [String: Any] {
            return obj.compactMap { _, val -> Forum? in
                guard let dict = val as? [String: Any] else { return nil }
                return forumFromDict(dict)
            }
        }
        if let arr = result as? [Any] {
            // forum_favor2 实际返回 result: [[{fid,name,info,...}, ...]]
            if let inner = arr.first as? [Any] {
                return inner.compactMap { item in (item as? [String: Any]).flatMap { forumFromDict($0) } }
            }
            return arr.compactMap { item -> Forum? in
                if let dict = item as? [String: Any] { return forumFromDict(dict) }
                if let fid = item as? Int { return Forum(fid: fid, name: "版块\(fid)", name2: nil, description: nil, parent: nil, subForums: nil, icon: nil) }
                if let s = item as? String, let fid = Int(s) { return Forum(fid: fid, name: "版块\(fid)", name2: nil, description: nil, parent: nil, subForums: nil, icon: nil) }
                return nil
            }
        }
        log.warning("[forum_favor2] unknown result format")
        return []
    }

    private func forumFromDict(_ dict: [String: Any]) -> Forum? {
        guard let fid = (dict["fid"] as? Int) ?? (dict["fid"] as? String).flatMap(Int.init) else { return nil }
        let name = dict["name"] as? String ?? "版块\(fid)"
        return Forum(fid: fid, name: name, name2: nil, description: dict["info"] as? String, parent: nil, subForums: nil, icon: dict["icon"] as? String)
    }

    /// 推荐帖子：app_inter/recmd_topic（result: [[{tid,subject,thread_icon,topic:{...},parent:[fid,forumName]}]])
    func fetchRecmThreads() async throws -> [HomeRecmTopic] {
        try await fetchRecmdTopic(page: 1)
    }

    /// app_inter/recmd_topic: nuke.php 推荐帖子（最新数据）
    private func fetchRecmdTopic(page: Int = 1) async throws -> [HomeRecmTopic] {
        var body: [String: String] = [
            "__output": "14",
            "app_id": Constants.API.nativeLoginAppId,
            "page": "\(page)"
        ]
        if let token = authToken, let uid = accessUid {
            body["access_token"] = token
            body["access_uid"] = "\(uid)"
        }
        let (data, _) = try await perform(endpoint: .appInterRecmdTopic, params: [:], body: body)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.decodingFailed
        }
        return parseRecmdTopicResponse(json)
    }

    /// 解析 recmd_topic 响应：result: [[{tid,subject,thread_icon,topic:{fid,replies,...},topic.parent:[fid,forumName]}]]
    private func parseRecmdTopicResponse(_ json: [String: Any]) -> [HomeRecmTopic] {
        guard let result = json["result"] as? [Any],
              let inner = result.first as? [Any] else {
            return []
        }
        return inner.compactMap { item -> HomeRecmTopic? in
            guard let dict = item as? [String: Any] else { return nil }
            let tid = (dict["tid"] as? Int) ?? (dict["target_id"] as? Int)
                ?? (dict["tid"] as? String).flatMap(Int.init)
                ?? (dict["target_id"] as? String).flatMap(Int.init)
            guard let tid = tid else { return nil }
            let topic = dict["topic"] as? [String: Any]
            let fid = (dict["fid"] as? Int) ?? (topic?["fid"] as? Int)
                ?? (dict["fid"] as? String).flatMap(Int.init)
                ?? 0
            let subject = dict["subject"] as? String ?? topic?["subject"] as? String ?? ""
            let authorId = (topic?["authorid"] as? Int) ?? (topic?["authorid"] as? String).flatMap(Int.init)
            let author = topic?["author"] as? String
            let postDate = (topic?["postdate"] as? Int) ?? (topic?["postdate"] as? String).flatMap(Int.init)
            let replyCount = (topic?["replies"] as? Int) ?? (topic?["replies"] as? String).flatMap(Int.init)
            let lastPost = (topic?["lastpost"] as? Int) ?? (topic?["lastpost"] as? String).flatMap(Int.init)
            var img = dict["thread_icon"] as? String
            if img == nil, let attachs = dict["attachs"] as? [[String: Any]], let first = attachs.first, let url = first["attachurl"] as? String {
                img = url.hasPrefix("http") ? url : "https://img.nga.178.com/attachments/\(url)"
            }
            var forumName: String?
            if let parent = topic?["parent"] as? [Any], parent.count > 1, let name = parent[1] as? String {
                forumName = name
            }
            let thread = ForumThread(tid: tid, fid: fid, subject: subject, authorId: authorId, author: author, postDate: postDate, replyCount: replyCount, lastPost: lastPost)
            return HomeRecmTopic(thread: thread, imageUrl: img, forumName: forumName)
        }
    }

    /// subject/hot: 热帖
    func fetchHotThreads() async throws -> [HomeRecmTopic] {
        let json = try await requestJSON(endpoint: .subjectHot)
        return parseHomeRecmTopics(json)
    }

    private func extractThreadDictArray(from json: [String: Any]) -> [[String: Any]] {
        if let a = json["result"] as? [[String: Any]] { return a }
        if let a = json["data"] as? [[String: Any]] { return a }
        if let obj = json["result"] as? [String: Any] {
            if let a = obj["data"] as? [[String: Any]] { return a }
            if let a = obj["list"] as? [[String: Any]] { return a }
            if let a = obj["topics"] as? [[String: Any]] { return a }
            return obj.compactMap { _, v in v as? [String: Any] }
        }
        if let obj = json["data"] as? [String: Any] {
            if let a = obj["data"] as? [[String: Any]] { return a }
            if let a = obj["list"] as? [[String: Any]] { return a }
            return obj.compactMap { _, v in v as? [String: Any] }
        }
        return []
    }

    private func parseHomeRecmTopics(_ json: [String: Any]) -> [HomeRecmTopic] {
        let arr = extractThreadDictArray(from: json)
        return arr.compactMap { dict -> HomeRecmTopic? in
            guard let thread = threadFromDict(dict) else { return nil }
            let img = (dict["img"] as? String) ?? (dict["image"] as? String) ?? (dict["cover"] as? String)
            let forum = dict["forumname"] as? String ?? dict["forum_name"] as? String
            return HomeRecmTopic(thread: thread, imageUrl: img, forumName: forum)
        }
    }

    private func threadFromDict(_ dict: [String: Any]) -> ForumThread? {
        let topic = dict["topic"] as? [String: Any]
        let tid: Int? = intFrom(dict["tid"]) ?? intFrom(dict["target_id"])
            ?? intFrom(topic?["tid"])
        guard let tid = tid else { return nil }
        let fid = intFrom(dict["fid"]) ?? intFrom(topic?["fid"]) ?? 0
        let subject = (dict["subject"] as? String) ?? (topic?["subject"] as? String) ?? (dict["title"] as? String) ?? ""
        let authorId: Int? = intFrom(dict["authorid"]) ?? intFrom(topic?["authorid"])
        let author = (dict["author"] as? String) ?? (topic?["author"] as? String)
        let postDate: Int? = intFrom(dict["postdate"]) ?? intFrom(topic?["postdate"])
        let replyCount: Int? = intFrom(dict["reply_count"]) ?? intFrom(dict["replies"])
            ?? intFrom(topic?["reply_count"]) ?? intFrom(topic?["replies"])
        let lastPost: Int? = intFrom(dict["lastpost"]) ?? intFrom(topic?["lastpost"])
        let (firstImageUrl, imageCount) = extractThreadPreviewImage(dict)
        return ForumThread(tid: tid, fid: fid, subject: subject, authorId: authorId, author: author, postDate: postDate, replyCount: replyCount, lastPost: lastPost, firstImageUrl: firstImageUrl, imageCount: imageCount)
    }

    private func intFrom(_ value: Any?) -> Int? {
        guard let v = value else { return nil }
        if let i = v as? Int { return i }
        if let s = v as? String { return Int(s) }
        return nil
    }

    /// 从 thread dict 提取首图 URL 和图片数量（content 内 [img] + attachs）
    private func extractThreadPreviewImage(_ dict: [String: Any]) -> (url: String?, count: Int) {
        let imageBase = "https://img.nga.178.com/attachments/"
        var firstUrl: String?
        var count = 0
        let topic = dict["topic"] as? [String: Any]

        if let content = (dict["content"] as? String) ?? (topic?["content"] as? String) {
            let urls = PostContentParser.extractImageUrls(from: content)
            count += urls.count
            if firstUrl == nil, let u = urls.first { firstUrl = u }
        }
        let postMisc = (dict["post_misc_var"] as? [String: Any]) ?? (topic?["post_misc_var"] as? [String: Any])
        var attachs: [[String: Any]] = (dict["attachs"] as? [[String: Any]]) ?? (topic?["attachs"] as? [[String: Any]]) ?? []
        if attachs.isEmpty, let a = postMisc?["attachs"] as? [String: Any] {
            attachs = a.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }).compactMap { a[$0] as? [String: Any] }
        }
        if attachs.isEmpty, let a = (dict["attachs"] as? [String: Any]) ?? (topic?["attachs"] as? [String: Any]) {
            attachs = a.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }).compactMap { a[$0] as? [String: Any] }
        }
        for att in attachs {
            guard (att["type"] as? String) == "img" || (att["type"] as? Int) == 0 else { continue }
            count += 1
            if firstUrl == nil, let path = att["attachurl"] as? String {
                firstUrl = path.hasPrefix("http") ? path : imageBase + path
            }
        }
        if firstUrl == nil {
            firstUrl = (dict["thread_icon"] as? String)
                ?? (dict["img"] as? String) ?? (dict["image"] as? String) ?? (dict["cover"] as? String)
            if firstUrl == nil, let topic = dict["topic"] as? [String: Any] {
                firstUrl = (topic["thread_icon"] as? String)
                    ?? (topic["img"] as? String) ?? (topic["image"] as? String) ?? (topic["cover"] as? String)
            }
            if let u = firstUrl, !u.hasPrefix("http") { firstUrl = imageBase + u }
        }
        if firstUrl != nil, count == 0 { count = 1 }
        return (firstUrl, count)
    }

    func requestJSON(
        endpoint: Endpoint,
        params: [String: String] = [:],
        body: [String: String]? = nil
    ) async throws -> [String: Any] {
        let (data, _) = try await perform(endpoint: endpoint, params: params, body: body)
        var parseData = data
        if var raw = String(data: data, encoding: .utf8) {
            if raw.contains("window.script_muti_get_var_store=") {
                raw = raw.replacingOccurrences(of: "window.script_muti_get_var_store=", with: "")
                parseData = raw.data(using: .utf8) ?? data
            }
            if endpoint.lib == "login" {
                log.debug("[login] raw response (\(data.count) bytes): \(raw.prefix(2000))\(raw.count > 2000 ? "..." : "")")
            }
        }
        guard let json = try? JSONSerialization.jsonObject(with: parseData) as? [String: Any] else {
            logResponseOnDecodeFailure(endpoint: endpoint, data: data, error: nil)
            throw AppError.decodingFailed
        }
        if endpoint.lib == "login", let error = json["error"] as? [AnyHashable: Any] {
            log.debug("[login] parsed json has error: \(json)")
        }
        return json
    }

    func request<T: Decodable>(
        endpoint: Endpoint,
        params: [String: String] = [:],
        body: [String: String]? = nil
    ) async throws -> T {
        let (data, _) = try await perform(endpoint: endpoint, params: params, body: body)
        do {
            let decoded = try decoder.decode(T.self, from: data)
            log.debug("\(endpoint.lib)/\(endpoint.act) response OK (\(data.count) bytes)")
            return decoded
        } catch {
            logResponseOnDecodeFailure(endpoint: endpoint, data: data, error: error)
            throw AppError.decodingFailed
        }
    }

    private func logFullRequestForPostman(request: URLRequest, endpoint: Endpoint) {
        let url = request.url?.absoluteString ?? "unknown"
        let method = request.httpMethod ?? "GET"
        var curl = "curl -X \(method) '\(url)'"
        request.allHTTPHeaderFields?.forEach { k, v in
            curl += " \\\n  -H '\(k): \(v)'"
        }
        if let body = request.httpBody, var bodyStr = String(data: body, encoding: .utf8), !bodyStr.isEmpty {
            if endpoint.lib == "login" {
                bodyStr = bodyStr
                    .components(separatedBy: "&")
                    .map { part in
                        if part.hasPrefix("password=") { return "password=***REDACTED***" }
                        return part
                    }
                    .joined(separator: "&")
            }
            curl += " \\\n  -d '\(bodyStr)'"
        }
        log.debug("[Postman] \(endpoint.lib)/\(endpoint.act) full request:\n\(curl)")
    }

    private func logResponseOnDecodeFailure(endpoint: Endpoint, data: Data, error: Swift.Error?) {
        let label = "\(endpoint.lib)/\(endpoint.act)"
        let errMsg = error.map { ": \($0.localizedDescription)" } ?? ""
        log.error("\(label) decoding failed\(errMsg)")
        let maxBytes = 4000
        let body: String
        if let str = String(data: data, encoding: .utf8) {
            if str.count > maxBytes {
                body = String(str.prefix(maxBytes)) + "\n... (truncated, \(str.count) chars total)"
            } else {
                body = str
            }
        } else {
            body = "<binary data \(data.count) bytes, hex: \(data.prefix(64).map { String(format: "%02x", $0) }.joined())>"
        }
        log.error("\(label) raw response:\n\(body)")
    }

    private func perform(
        endpoint: Endpoint,
        params: [String: String],
        body: [String: String]?
    ) async throws -> (Data, URLResponse) {
        let request = try buildRequest(endpoint: endpoint, params: params, body: body)
        let url = request.url?.absoluteString ?? "unknown"
        log.debug("\(request.httpMethod ?? "?") \(endpoint.lib)/\(endpoint.act) -> \(url)")

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                log.debug("\(endpoint.lib)/\(endpoint.act) <- \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    log.warning("\(endpoint.lib)/\(endpoint.act) 401 Unauthorized")
                    NotificationCenter.default.post(name: Constants.NotificationName.unauthorized, object: nil)
                    throw AppError.unauthorized
                }
                if httpResponse.statusCode >= 400 {
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    log.error("\(endpoint.lib)/\(endpoint.act) \(httpResponse.statusCode) full response: \(message)")
                    if endpoint.lib == "login" {
                        if let gbk = decodeGB18030(data) {
                            log.error("[login] response (GBK decoded): \(gbk)")
                        }
                    }
                    throw AppError.serverError(code: httpResponse.statusCode, message: message)
                }
            }
            return (data, response)
        } catch {
            log.error("\(endpoint.lib)/\(endpoint.act) network error: \(error.localizedDescription)")
            throw error
        }
    }

    private func buildRequest(
        endpoint: Endpoint,
        params: [String: String],
        body: [String: String]?
    ) throws -> URLRequest {
        var queryItems = [
            URLQueryItem(name: "__lib", value: endpoint.lib),
            URLQueryItem(name: "__act", value: endpoint.act)
        ]
        if let version = endpoint.version {
            queryItems.append(URLQueryItem(name: "_v", value: "\(version)"))
        }
        if endpoint.useOutput14 {
            queryItems.append(URLQueryItem(name: "__output", value: "14"))
        }
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        var components = URLComponents(string: endpoint.baseURL)!
        var request: URLRequest

        if endpoint.requiresPost, let bodyParams = body ?? (params.isEmpty ? nil : params) {
            components.queryItems = queryItems
            request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyParams
                .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                .joined(separator: "&")
                .data(using: .utf8)
        } else {
            components.queryItems = queryItems
            request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
        }

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let token = authToken, let uid = accessUid {
            request.setValue("ngaPassportUid=\(uid); ngaPassportCid=\(token)", forHTTPHeaderField: "Cookie")
        }
        request.setValue(Constants.API.userAgent, forHTTPHeaderField: "User-Agent")
        logFullRequestForPostman(request: request, endpoint: endpoint)
        return request
    }
}

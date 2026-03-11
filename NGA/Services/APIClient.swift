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

    /// Fetches thread list from thread.php. MNGA-style: POST, __inchst=UTF8.
    /// orderBy: "lastpostdesc" (last reply first) or "postdatedesc" (newest first). Default lastpostdesc.
    /// Tries primary baseURL first, then alternates if needed.
    /// Response: window.script_muti_get_var_store={"data":{"__T":{"0":{...}}}}
    func fetchThreadList(fid: Int, page: Int, orderBy: String = Constants.API.orderByLastPost, recommendOnly: Bool = false) async throws -> [ForumThread] {
        let bases = [Constants.API.baseURL] + Constants.API.alternateBaseURLs
        var lastError: Error?
        for base in bases {
            let threadURL = "\(base)/thread.php"
            do {
                let threads = try await fetchThreadListFrom(baseURL: base, threadURL: threadURL, fid: fid, page: page, orderBy: orderBy, recommendOnly: recommendOnly)
                log.debug("[thread.php] fid=\(fid) page=\(page) -> \(threads.count) threads (base: \(base))")
                return threads
            } catch {
                lastError = error
                log.warning("[thread.php] failed for \(base): \(error.localizedDescription)")
            }
        }
        throw lastError ?? AppError.decodingFailed
    }

    private func fetchThreadListFrom(baseURL: String, threadURL: String, fid: Int, page: Int, orderBy: String, recommendOnly: Bool) async throws -> [ForumThread] {
        guard let url = URL(string: threadURL) else { throw AppError.decodingFailed }
        var bodyParams: [String: String] = [
            "fid": "\(fid)",
            "page": "\(page)",
            "__inchst": "UTF8",
            "lite": "js",
            "order_by": orderBy,
            "recommend": recommendOnly ? "1" : "0"
        ]
        if let token = authToken {
            bodyParams["access_token"] = token
        }
        if let uid = accessUid {
            bodyParams["access_uid"] = "\(uid)"
        }
        let bodyStr = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyStr.data(using: .utf8)
        request.setValue("NGA_skull/7.3.1(iPhone; iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        log.debug("[thread.php] POST fid=\(fid) page=\(page) -> \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let rawMsg = String(data: data, encoding: .utf8) ?? decodeGB18030(data) ?? String(data: data, encoding: .utf16) ?? ""
            if http.statusCode == 401 {
                log.warning("[thread.php] 401 Unauthorized")
                NotificationCenter.default.post(name: Constants.NotificationName.unauthorized, object: nil)
                throw AppError.unauthorized
            }
            if http.statusCode == 403, rawMsg.contains("未登录") || rawMsg.contains("登录") {
                throw AppError.loginRequired
            }
            throw AppError.serverError(code: http.statusCode, message: String(rawMsg.prefix(200)))
        }

        let raw: String
        if let s = String(data: data, encoding: .utf8) { raw = s }
        else if let s = decodeGB18030(data) { raw = s }
        else if let s = String(data: data, encoding: .utf16) { raw = s }
        else {
            log.error("[thread.php] response encoding failed")
            throw AppError.decodingFailed
        }
        return try parseThreadListResponse(raw: raw, data: data)
    }

    /// Fetches post list and author map from read.php. MNGA-style: POST, __inchst=UTF8, lite=js.
    /// Response: window.script_muti_get_var_store={"data":{"__R":{...},"__U":{...},"__GROUPS":{...}}}
    func fetchPostList(tid: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        let bases = [Constants.API.baseURL] + Constants.API.alternateBaseURLs
        var lastError: Error?
        for base in bases {
            let readURL = "\(base)/read.php"
            do {
                let result = try await fetchPostListFrom(baseURL: base, readURL: readURL, tid: tid, page: page)
                log.debug("[read.php] tid=\(tid) page=\(page) -> \(result.posts.count) posts, \(result.authorMap.count) authors (base: \(base))")
                return result
            } catch {
                lastError = error
                log.warning("[read.php] failed for \(base): \(error.localizedDescription)")
            }
        }
        throw lastError ?? AppError.decodingFailed
    }

    private func fetchPostListFrom(baseURL: String, readURL: String, tid: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        guard let url = URL(string: readURL) else { throw AppError.decodingFailed }
        var bodyParams: [String: String] = [
            "tid": "\(tid)",
            "page": "\(page)",
            "__inchst": "UTF8",
            "__output": "1",
            "lite": "js",
            "v2": "1"
        ]
        if let token = authToken {
            bodyParams["access_token"] = token
        }
        if let uid = accessUid {
            bodyParams["access_uid"] = "\(uid)"
        }
        let bodyStr = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyStr.data(using: .utf8)
        request.setValue("NGA_WP_JW", forHTTPHeaderField: "User-Agent")
        request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        log.debug("[read.php] POST tid=\(tid) page=\(page) -> \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let rawMsg = String(data: data, encoding: .utf8) ?? decodeGB18030(data) ?? String(data: data, encoding: .utf16) ?? ""
            if http.statusCode == 401 {
                log.warning("[read.php] 401 Unauthorized")
                NotificationCenter.default.post(name: Constants.NotificationName.unauthorized, object: nil)
                throw AppError.unauthorized
            }
            if http.statusCode == 403, rawMsg.contains("未登录") || rawMsg.contains("登录") {
                throw AppError.loginRequired
            }
            throw AppError.serverError(code: http.statusCode, message: String(rawMsg.prefix(200)))
        }

        let raw: String
        if let s = String(data: data, encoding: .utf8) { raw = s }
        else if let s = decodeGB18030(data) { raw = s }
        else if let s = String(data: data, encoding: .utf16) { raw = s }
        else {
            log.error("[read.php] response encoding failed")
            throw AppError.decodingFailed
        }
        return try parsePostListResponse(raw: raw)
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

    private func parsePostListResponse(raw: String) throws -> (posts: [Post], authorMap: [Int: UserInForum]) {
        let trimmedRaw = raw.hasPrefix("\u{FEFF}") ? String(raw.dropFirst(1)) : raw
        guard let jsonStr = extractJSONFromScriptVar(trimmedRaw, prefix: "window.script_muti_get_var_store=") else {
            log.error("[read.php] extractJSON failed, body prefix: \(raw.prefix(300))")
            throw AppError.decodingFailed
        }
        // NGA returns JSON with raw control chars (tab, newline) in string values - fix before parsing
        let sanitized = sanitizeJSONControlChars(jsonStr)
        guard let jsonData = sanitized.data(using: .utf8) else {
            log.error("[read.php] jsonStr.data(using:.utf8) failed, len=\(jsonStr.count)")
            throw AppError.decodingFailed
        }
        let root: [String: Any]
        do {
            guard let obj = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                log.error("[read.php] root cast failed")
                throw AppError.decodingFailed
            }
            root = obj
        } catch {
            log.error("[read.php] JSONSerialization failed: \(error), body len=\(jsonData.count), prefix: \(String(data: jsonData.prefix(200), encoding: .utf8) ?? "?")")
            throw AppError.decodingFailed
        }

        if isLoginRequiredResponse(root) {
            log.info("[read.php] login required for tid")
            throw AppError.loginRequired
        }

        let dataObj = root["data"] as? [String: Any]
        var rObj = dataObj?["__R"] as? [String: Any]
        if rObj == nil, let items = dataObj?["item"] as? [[String: Any]] {
            rObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        guard let r = rObj, !r.isEmpty else {
            if dataObj != nil && (dataObj?["__R"] == nil) {
                return (posts: [], authorMap: [:])
            }
            log.error("[read.php] no __R, body prefix: \(raw.prefix(300))")
            throw AppError.decodingFailed
        }

        var posts: [Post] = []
        for key in r.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let postDict = r[key] as? [String: Any],
                  let postData = try? JSONSerialization.data(withJSONObject: postDict) else { continue }
            if let post = try? decoder.decode(Post.self, from: postData) {
                posts.append(post)
            }
        }
        let fid = posts.first?.fid ?? 0
        let authorMap = parseAuthorMap(dataObj: dataObj, fid: fid)
        return (posts: posts, authorMap: authorMap)
    }

    /// Parses __U and __GROUPS from read.php into [uid: UserInForum].
    /// __GROUPS may be inside __U or a sibling of __U under data.
    private func parseAuthorMap(dataObj: [String: Any]?, fid: Int) -> [Int: UserInForum] {
        guard let uObj = dataObj?["__U"] as? [String: Any] else { return [:] }
        let groupsObj = (uObj["__GROUPS"] ?? dataObj?["__GROUPS"]) as? [String: Any]
        var map: [Int: UserInForum] = [:]
        for (key, val) in uObj {
            guard !key.hasPrefix("__"), let userDict = val as? [String: Any] else { continue }
            guard let uid = Int(key) else { continue }

            let username = userDict["username"] as? String
            let avatar = userDict["avatar"] as? String
            let postnum = (userDict["postnum"] as? Int) ?? (userDict["postnum"] as? String).flatMap { Int($0) }
            let reputation = userDict["reputation"] as? String
            let memberid = (userDict["memberid"] as? Int) ?? (userDict["memberid"] as? String).flatMap { Int($0) }

            var levelName: String?
            if let mid = memberid, let g = groupsObj?["\(mid)"] as? [Any], let first = g.first {
                levelName = "\(first)"
            }

            let user = User(uid: uid, username: username, nickname: nil, avatar: avatar)
            let forumContext = ForumUserContext(fid: fid, levelName: levelName, postnum: postnum, reputation: reputation)
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

    /// Replaces raw control chars in JSON string values. NGA read.php returns unescaped tab/newline in content.
    private func sanitizeJSONControlChars(_ json: String) -> String {
        var result = json
        result = result.replacingOccurrences(of: "\u{09}", with: "\\t")   // tab
        result = result.replacingOccurrences(of: "\u{0A}", with: "\\n")   // newline
        result = result.replacingOccurrences(of: "\u{0D}", with: "\\r")   // carriage return
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

    private func parseThreadListResponse(raw: String, data: Data) throws -> [ForumThread] {
        let trimmedRaw = raw.hasPrefix("\u{FEFF}") ? String(raw.dropFirst(1)) : raw
        guard let jsonStr = extractJSONFromScriptVar(trimmedRaw, prefix: "window.script_muti_get_var_store=") else {
            log.error("[thread.php] extractJSON failed, body prefix: \(raw.prefix(300))")
            throw AppError.decodingFailed
        }
        let sanitized = sanitizeJSONControlChars(jsonStr)
        guard let jsonData = sanitized.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            log.error("[thread.php] parse failed, body prefix: \(raw.prefix(300))")
            throw AppError.decodingFailed
        }
        if isLoginRequiredResponse(root) {
            log.info("[thread.php] login required for fid")
            throw AppError.loginRequired
        }

        let dataObj = root["data"] as? [String: Any]
        var tObj = dataObj?["__T"] as? [String: Any]
        if tObj == nil, let items = dataObj?["item"] as? [[String: Any]] {
            tObj = Dictionary(uniqueKeysWithValues: items.enumerated().map { ("\($0.offset)", $0.element) })
        }
        guard let t = tObj, !t.isEmpty else {
            if dataObj != nil && (dataObj?["__T"] == nil) { return [] }
            log.error("[thread.php] no __T, body prefix: \(raw.prefix(300))")
            throw AppError.decodingFailed
        }
        var threads: [ForumThread] = []
        for key in t.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
            guard let threadDict = t[key] as? [String: Any],
                  let threadData = try? JSONSerialization.data(withJSONObject: threadDict) else { continue }
            if let thread = try? decoder.decode(ForumThread.self, from: threadData) {
                threads.append(thread)
            }
        }
        return threads
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

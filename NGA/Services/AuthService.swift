//
//  AuthService.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Combine
import Logging
import WebKit

/// Intent to perform after login. Used for just-in-time auth (e.g. user taps reply before logging in).
enum PendingAction: Equatable {
    case replyToThread(threadId: Int)
    case createThread(forumId: Int, subject: String)
    case votePost(postId: Int, tid: Int, pid: Int, upvote: Bool)
    case favorThread(tid: Int, folderId: String)
    case unfavorThread(tid: Int)
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    private let log = Logger.for(.auth)

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var errorMessage: String?
    @Published var pendingAction: PendingAction?

    /// Tab selection for MainTabView. 0=首页, 1=社区, 2=消息, 3=我的.
    @Published var selectedTab: Int = 0
    /// Tab index when user was sent to 我的 for login. Used to switch back after login.
    @Published var sourceTabForLogin: Int?
    /// Intent to execute after login; consumed by matching views.
    @Published var postLoginIntent: PendingAction?
    /// Set when 401 triggers clearSession; root view shows "登录已过期" alert.
    @Published var needsReauthAlert = false

    private let apiClient = APIClient.shared

    private init() {
        NotificationCenter.default.addObserver(
            forName: Constants.NotificationName.unauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearSession()
        }
    }

    /// Call before any write operation. Returns true if user is logged in; otherwise saves intent and returns false.
    /// When false, caller should call requestLogin(fromTab:) to navigate to 我的.
    func requireAuthFor(_ action: PendingAction) -> Bool {
        if isAuthenticated { return true }
        pendingAction = action
        return false
    }

    /// Switch to 我的 tab for login. Call when requireAuthFor returns false.
    func requestLogin(fromTab tab: Int) {
        sourceTabForLogin = tab
        selectedTab = Constants.TabIndex.profile
    }

    /// Clear postLoginIntent after a view has consumed it.
    func clearPostLoginIntent() {
        postLoginIntent = nil
    }

    /// Called after login success; clears pending and returns it. Caller should set postLoginIntent and switch tab.
    @discardableResult
    func flushPendingAction() -> PendingAction? {
        let action = pendingAction
        pendingAction = nil
        return action
    }

    /// Call after WebView login: save uid/cid from cookies, fetch user via iflogin, then didCompleteLogin.
    func completeLoginFromWebView(uid: Int, cid: String) async {
        log.debug("[login] WebView login success uid=\(uid)")
        try? KeychainService.saveToken(cid)
        try? KeychainService.saveUid(uid)
        await apiClient.setAuthToken(cid)
        await apiClient.setAccessUid(uid)
        currentUser = User(uid: uid, username: nil, nickname: nil, avatar: nil)
        isAuthenticated = true

        do {
            let json = try await apiClient.requestJSON(endpoint: .iflogin, params: [:])
            let code = (json["code"] as? Int) ?? (json["code"] as? Double).map { Int($0) } ?? -1
            if code == 0, let data = json["data"] as? [String: Any],
               let uidResp = (data["uid"] as? Int) ?? (data["uid"] as? Double).map({ Int($0) }),
               uidResp > 0 {
                let username = data["username"] as? String
                let nickname = data["nickname"] as? String
                let avatar = data["avatar"] as? String
                let user = User(uid: uidResp, username: username, nickname: nickname, avatar: avatar)
                currentUser = user
                try? KeychainService.saveUserProfile(user)
            }
        } catch {
            log.warning("[login] iflogin after WebView failed: \(error.localizedDescription)")
        }
        didCompleteLogin()
    }

    /// Call after login success. Flushes pending action, sets postLoginIntent, switches back to source tab if there was a pending action.
    func didCompleteLogin() {
        let action = flushPendingAction()
        postLoginIntent = action
        if action != nil, let source = sourceTabForLogin {
            selectedTab = source
        }
        sourceTabForLogin = nil
    }

    func login(username: String, password: String) async throws {
        let loginId = username.trimmingCharacters(in: .whitespacesAndNewlines)
        log.debug("[login] attempt name=\(loginId)")
        errorMessage = nil

        // wolfcon 10.3 客户端登录: name + type (id/mail/phone)
        let loginType: String
        if loginId.contains("@") {
            loginType = "mail"
        } else if loginId.count == 11, loginId.allSatisfy(\.isNumber) {
            loginType = "phone"
        } else if loginId.allSatisfy(\.isNumber) {
            loginType = "id"
        } else {
            loginType = ""
        }
        log.debug("[login] loginType=\(loginType.isEmpty ? "omit" : loginType)")

        var params: [String: String] = [
            "name": loginId,
            "password": password,
            "__output": "14",
            "__inchst": "UTF-8"
        ]
        if !loginType.isEmpty {
            params["type"] = loginType
        }
        // wolfcon 13.2: __ngaClientChecksum 仅认证过的客户端需要；无认证码时不发送，否则触发「客户端验证错误」
        if !Constants.API.clientAuthCode.isEmpty {
            let timestamp = Int(Date().timeIntervalSince1970)
            let passwordCrc32 = CRC32Helper.checksum(password)
            let checksumInner = MD5Helper.hash("\(passwordCrc32)\(Constants.API.clientAuthCode)\(timestamp)")
            params["__ngaClientChecksum"] = "\(checksumInner)\(timestamp)"
            log.debug("[login] __ngaClientChecksum sent (has clientAuthCode)")
        } else {
            log.debug("[login] __ngaClientChecksum omitted (no clientAuthCode)")
        }
        log.debug("[login] request params (pwd redacted): name=\(loginId) type=\(loginType.isEmpty ? "nil" : loginType)")

        do {
            let response = try await apiClient.requestJSON(
                endpoint: .login,
                params: [:],
                body: params
            )

            // wolfcon: success has data.0='登录成功', data.1=uid, data.2=cookieid, data.3=userinfo
            // __output=14 may return different structure; also support app_api style code/uid/access_token
            if let data = response["data"] as? [AnyHashable: Any] {
                let uidVal: Any? = data["1"] ?? data[1]
                let uid = (uidVal as? Int) ?? (uidVal as? Double).map { Int($0) } ?? 0
                let cid: String? = (data["2"] ?? data[2]) as? String
                let userInfo: [String: Any]? = (data["3"] ?? data[3]) as? [String: Any]
                let usernameFromApi = userInfo?["username"] as? String
                let avatar = userInfo?["avatar"] as? String

                let user = User(
                    uid: uid,
                    username: usernameFromApi ?? loginId,
                    nickname: userInfo?["nickname"] as? String,
                    avatar: avatar
                )
                currentUser = user
                isAuthenticated = true

                if let cid = cid {
                    try? KeychainService.saveToken(cid)
                    await apiClient.setAuthToken(cid)
                }
                try? KeychainService.saveUid(uid)
                try? KeychainService.saveUserProfile(user)
                await apiClient.setAccessUid(uid)
                if let cid = cid {
                    try? KeychainService.saveCookies("ngaPassportUid=\(uid); ngaPassportCid=\(cid)")
                }
            } else if let code = (response["code"] as? Int) ?? (response["code"] as? Double).map({ Int($0) }), code == 0 {
                // app_api style fallback
                let uid = (response["uid"] as? Int) ?? (response["uid"] as? Double).map { Int($0) } ?? 0
                let usernameFromApi = response["username"] as? String
                let user = User(
                    uid: uid,
                    username: usernameFromApi ?? loginId,
                    nickname: response["nickname"] as? String,
                    avatar: response["avatar"] as? String
                )
                currentUser = user
                isAuthenticated = true
                if let token = response["access_token"] as? String {
                    try? KeychainService.saveToken(token)
                    await apiClient.setAuthToken(token)
                }
                try? KeychainService.saveUid(uid)
                try? KeychainService.saveUserProfile(user)
                await apiClient.setAccessUid(uid)
            } else if let error = response["error"] as? [AnyHashable: Any],
                      let errMsg: String = (error["0"] ?? error[0]) as? String {
                log.error("[login] server error response: \(String(describing: response))")
                throw AppError.serverError(code: -1, message: errMsg)
            } else {
                let message = response["msg"] as? String ?? "Login failed"
                log.error("[login] unexpected response: \(String(describing: response))")
                throw AppError.serverError(code: -1, message: message)
            }
        } catch AppError.decodingFailed {
            log.error("[login] decodingFailed - response was not valid JSON")
            errorMessage = "登录失败，请检查账号和密码（支持邮箱/用户ID/手机/账号）"
            throw AppError.decodingFailed
        } catch let error as AppError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw AppError.unknown(error)
        }
    }

    func logout() {
        Task {
            _ = try? await apiClient.request(endpoint: .logout, params: ["logout": "1"]) as [String: String]
            await apiClient.setAuthToken(nil)
            await apiClient.setAccessUid(nil)
        }
        try? KeychainService.deleteToken()
        try? KeychainService.deleteUid()
        try? KeychainService.deleteUserProfile()
        try? KeychainService.deleteCookies()
        clearWebViewCookies()
        pendingAction = nil
        currentUser = nil
        isAuthenticated = false
    }

    /// Clear NGA passport cookies from WKWebsiteDataStore so WebView login shows fresh form.
    private func clearWebViewCookies() {
        let store = WKWebsiteDataStore.default().httpCookieStore
        store.getAllCookies { cookies in
            let ngaNames = ["ngaPassportUid", "ngaPassportCid"]
            for c in cookies where ngaNames.contains(c.name) {
                store.delete(c) { self.log.debug("[logout] cleared cookie \(c.name)") }
            }
        }
    }

    /// Call when 401 is received to clear session without calling logout API.
    func clearSession() {
        Task {
            await apiClient.setAuthToken(nil)
            await apiClient.setAccessUid(nil)
        }
        try? KeychainService.deleteToken()
        try? KeychainService.deleteUid()
        try? KeychainService.deleteUserProfile()
        try? KeychainService.deleteCookies()
        clearWebViewCookies()
        pendingAction = nil
        currentUser = nil
        isAuthenticated = false
        needsReauthAlert = true
    }

    func restoreSession() async {
        guard let token = KeychainService.getToken() else {
            await apiClient.setAccessUid(nil)
            isAuthenticated = false
            currentUser = nil
            return
        }
        await apiClient.setAuthToken(token)
        guard let uid = KeychainService.getUid() else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        await apiClient.setAccessUid(uid)
        currentUser = KeychainService.getUserProfile() ?? User(uid: uid, username: nil, nickname: nil, avatar: nil)
        isAuthenticated = true

        do {
            let json = try await apiClient.requestJSON(endpoint: .iflogin, params: [:])
            let code = (json["code"] as? Int) ?? (json["code"] as? Double).map { Int($0) } ?? -1
            if code != 0 {
                log.info("[restoreSession] iflogin returned code=\(code), clearing session")
                clearSession()
                return
            }
            if let data = json["data"] as? [String: Any],
               let uidResp = (data["uid"] as? Int) ?? (data["uid"] as? Double).map({ Int($0) }),
               uidResp > 0 {
                let username = data["username"] as? String
                let nickname = data["nickname"] as? String
                let avatar = data["avatar"] as? String
                let user = User(uid: uidResp, username: username, nickname: nickname, avatar: avatar)
                currentUser = user
                try? KeychainService.saveUserProfile(user)
            }
        } catch {
            log.warning("[restoreSession] iflogin failed: \(error.localizedDescription), keeping session")
        }
    }
}

//
//  AuthService.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Combine
import Logging

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    private let log = Logger.for(.auth)

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var errorMessage: String?

    private let apiClient = APIClient.shared

    private init() {}

    func login(username: String, password: String) async throws {
        log.debug("login attempt for user=\(username)")
        errorMessage = nil

        let timestamp = Int(Date().timeIntervalSince1970)
        let clientSign = MD5Helper.hash("\(timestamp)\(Constants.API.appSecret)\(username)\(password)\(Constants.API.appId)")

        let params: [String: String] = [
            "login": "1",
            "email": username,
            "password": password,
            "t": "\(timestamp)",
            "client_sign": clientSign,
            "app_id": Constants.API.appId,
            "__output": "14"
        ]

        do {
            let response = try await apiClient.requestJSON(
                endpoint: .login,
                params: ["login": "1"],
                body: params
            )

            let code = (response["code"] as? Int) ?? (response["code"] as? Double).map { Int($0) } ?? -1
            if code == 0 {
                let uid = (response["uid"] as? Int) ?? (response["uid"] as? Double).map { Int($0) } ?? 0
                let user = User(
                    uid: uid,
                    username: username,
                    nickname: response["nickname"] as? String,
                    avatar: response["avatar"] as? String
                )
                currentUser = user
                isAuthenticated = true

                if let token = response["access_token"] as? String {
                    try? KeychainService.saveToken(token)
                    await apiClient.setAuthToken(token)
                }
            } else {
                let message = response["msg"] as? String ?? "Login failed"
                throw AppError.serverError(code: code, message: message)
            }
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
        }
        try? KeychainService.deleteToken()
        try? KeychainService.deleteCookies()
        currentUser = nil
        isAuthenticated = false
    }

    func restoreSession() async {
        if let token = KeychainService.getToken() {
            await apiClient.setAuthToken(token)
            isAuthenticated = true
            currentUser = User(uid: 0, username: nil, nickname: nil, avatar: nil)
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
}

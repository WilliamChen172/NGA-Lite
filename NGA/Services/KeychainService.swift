//
//  KeychainService.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import KeychainAccess

enum KeychainService {
    private static let keychain = Keychain(service: Constants.Keychain.serviceName)

    static func saveToken(_ token: String) throws {
        try keychain.set(token, key: Constants.Keychain.tokenKey)
    }

    static func getToken() -> String? {
        try? keychain.get(Constants.Keychain.tokenKey)
    }

    static func deleteToken() throws {
        try keychain.remove(Constants.Keychain.tokenKey)
    }

    static func saveUid(_ uid: Int) throws {
        try keychain.set("\(uid)", key: Constants.Keychain.uidKey)
    }

    static func getUid() -> Int? {
        guard let s = try? keychain.get(Constants.Keychain.uidKey), let i = Int(s) else { return nil }
        return i
    }

    static func deleteUid() throws {
        try? keychain.remove(Constants.Keychain.uidKey)
    }

    static func saveUserProfile(_ user: User?) throws {
        if let user = user, let json = try? JSONEncoder().encode(user), let str = String(data: json, encoding: .utf8) {
            try keychain.set(str, key: Constants.Keychain.userProfileKey)
        } else {
            try? keychain.remove(Constants.Keychain.userProfileKey)
        }
    }

    static func getUserProfile() -> User? {
        guard let str = try? keychain.get(Constants.Keychain.userProfileKey),
              let data = str.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return nil }
        return user
    }

    static func deleteUserProfile() throws {
        try? keychain.remove(Constants.Keychain.userProfileKey)
    }

    static func saveCookies(_ cookies: String) throws {
        try keychain.set(cookies, key: Constants.Keychain.cookieKey)
    }

    static func getCookies() -> String? {
        try? keychain.get(Constants.Keychain.cookieKey)
    }

    static func deleteCookies() throws {
        try? keychain.remove(Constants.Keychain.cookieKey)
    }
}

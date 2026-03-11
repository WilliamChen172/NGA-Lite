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

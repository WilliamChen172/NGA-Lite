//
//  Constants.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

enum Constants {
    enum API {
        /// Primary base URL. MNGA uses nga.178.com; ngabbs.com also works. Keep flexible.
        static let baseURL = "https://ngabbs.com"
        /// Alternate base URLs to try if primary fails (e.g. nga.178.com).
        static let alternateBaseURLs = ["https://nga.178.com", "https://bbs.nga.cn"]
        static let appAPIURL = "\(baseURL)/app_api.php"
        static let nukeURL = "\(baseURL)/nuke.php"
        static var threadURL: String { "\(baseURL)/thread.php" }

        // Auth parameters - placeholder values; update from NGA app analysis if needed
        static let appId = "nga_ios"
        static let appSecret = ""

        /// thread.php order_by values
        static let orderByLastPost = "lastpostdesc"   // 按最后回复时间
        static let orderByPostDate = "postdatedesc"  // 按发布时间
    }

    enum Keychain {
        static let serviceName = "Rosario.NGA"
        static let tokenKey = "nga_auth_token"
        static let cookieKey = "nga_cookies"
    }
}

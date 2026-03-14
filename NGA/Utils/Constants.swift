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
        /// 客户端认证码。wolfcon 13.2: 认证过的客户端需保密；无则留空，__ngaClientChecksum 用空字符串。
        static let clientAuthCode = ""
        /// Native 登录 (nuke.php) app_id，也用于 app_inter/recmd_topic 等
        static let nativeLoginAppId = "1100"
        /// AES-128 Key：wolfcon AppSecret 后 16 位
        static let nativeLoginAESKeyHex = "41dcf30175a7a80b"
        /// Sign 计算用 AppSecret（与 native 登录 key 同源）
        static let appSecretForSign = "41dcf30175a7a80b"

        /// wolfcon 13.1: User-Agent 格式 客户端软件名/版本 (硬件; 操作系统)，硬件+OS 尽量不超过20字节
        static let userAgent = "Rosario.NGA/1.0 (iPhone; iOS)"

        /// thread.php order_by values
        static let orderByLastPost = "lastpostdesc"   // 按最后回复时间
        static let orderByPostDate = "postdatedesc"  // 按发布时间
    }

    enum NotificationName {
        static let unauthorized = Notification.Name("NGA.Unauthorized")
    }

    enum TabIndex {
        static let home = 0
        static let forum = 1
        static let notifications = 2
        static let profile = 3
    }

    enum Keychain {
        static let serviceName = "Rosario.NGA"
        static let tokenKey = "nga_auth_token"
        static let uidKey = "nga_uid"
        static let userProfileKey = "nga_user_profile"
        static let cookieKey = "nga_cookies"
    }
}

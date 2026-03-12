//
//  DeviceIdHelper.swift
//  NGA
//
//  device 参数：iOS:{64位hex}，设备唯一 hash，持久化存储
//

import Foundation
import CryptoKit
import Logging
#if canImport(UIKit)
import UIKit
#endif

enum DeviceIdHelper {
    private static let log = Logger.for(.auth)

    /// 获取 device 字符串，格式 iOS:{64位hex}。首次生成后存 Keychain。
    static func getOrCreate() -> String {
        if let existing = KeychainService.getDeviceId() {
            log.debug("[deviceId] using cached \(existing.prefix(20))...")
            return existing
        }
        let newId = generate()
        try? KeychainService.saveDeviceId(newId)
        log.debug("[deviceId] generated new \(newId.prefix(20))...")
        return newId
    }

    private static func generate() -> String {
        let seed: String
        #if canImport(UIKit)
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            seed = idfv
        } else {
            seed = UUID().uuidString
        }
        #else
        seed = UUID().uuidString
        #endif
        let hash = SHA256.hash(data: Data(seed.utf8))
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return "iOS:\(hex)"
    }
}

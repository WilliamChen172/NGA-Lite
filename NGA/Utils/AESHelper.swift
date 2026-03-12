//
//  AESHelper.swift
//  NGA
//
//  Native 登录：password 用 AES-128-ECB 加密后 Base64 传输
//

import Foundation
import CryptoSwift

enum AESHelper {
    /// AES-128-ECB 加密，返回 Base64 字符串
    /// - Parameters:
    ///   - plainText: 明文
    ///   - keyHex: 16 字节 key 的 hex 字符串（32 字符）；若为 16 字符则重复一次补足
    static func encryptECBBase64(plainText: String, keyHex: String) -> String? {
        let expandedKey: String
        if keyHex.count == 16 {
            expandedKey = keyHex + keyHex
        } else if keyHex.count == 32 {
            expandedKey = keyHex
        } else {
            return nil
        }
        guard let keyData = expandedKey.hexToData(), keyData.count == 16 else { return nil }
        return encryptECBBase64(plainText: plainText, key: keyData)
    }

    static func encryptECBBase64(plainText: String, key: Data) -> String? {
        guard key.count == 16 else { return nil }
        do {
            let aes = try AES(key: Array(key), blockMode: ECB(), padding: .pkcs7)
            let encrypted = try aes.encrypt(Array(plainText.utf8))
            return Data(encrypted).base64EncodedString()
        } catch {
            return nil
        }
    }
}

private extension String {
    func hexToData() -> Data? {
        var data = Data(capacity: count / 2)
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: 2, limitedBy: endIndex) ?? endIndex
            guard next <= endIndex, let byte = UInt8(self[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }
}

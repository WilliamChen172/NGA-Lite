//
//  MD5.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import CryptoKit

enum MD5Helper {
    static func hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

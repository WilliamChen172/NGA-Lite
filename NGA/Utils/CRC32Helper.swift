//
//  CRC32Helper.swift
//  NGA
//
//  Created by William Chen on 3/12/26.
//

import Foundation
import zlib

enum CRC32Helper {
    /// CRC32 checksum of string (UTF-8 bytes). Per wolfcon 13.2: login uses password's crc32 instead of uid.
    static func checksum(_ string: String) -> UInt32 {
        let bytes = [UInt8](string.utf8)
        return UInt32(crc32(0, bytes, UInt32(bytes.count)))
    }
}

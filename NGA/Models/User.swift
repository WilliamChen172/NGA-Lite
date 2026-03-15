//
//  User.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

struct User: Identifiable, Codable {
    let uid: Int
    let username: String?
    let nickname: String?
    let avatar: String?

    var id: Int { uid }

    var displayName: String {
        nickname ?? username ?? "UID:\(uid)"
    }

    var avatarURL: URL? {
        guard let avatar = avatar, !avatar.isEmpty else { return nil }
        if avatar.hasPrefix("http") {
            return URL(string: avatar)
        }
        return URL(string: "https://img.nga.178.com/avatars/\(avatar)")
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case nickname
        case avatar
    }
}

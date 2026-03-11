//
//  Forum.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

struct Forum: Identifiable, Codable, Hashable {
    let fid: Int
    let name: String
    let name2: String?
    let description: String?
    let parent: Int?
    let subForums: [Forum]?

    var id: Int { fid }

    func hash(into hasher: inout Hasher) { hasher.combine(fid) }
    static func == (lhs: Forum, rhs: Forum) -> Bool { lhs.fid == rhs.fid }

    enum CodingKeys: String, CodingKey {
        case fid
        case name
        case name2
        case description
        case parent
        case subForums = "sub"
    }
}

// MARK: - NGA API Response Structures (home/category)
// API returns: result[].groups[].forums[] with fid as Int or String

struct ForumCategoryAPIGroup: Decodable {
    let name: String?
    let id: Int?
    let info: String?
    let forums: [ForumAPIItem]?
}

struct ForumAPIItem: Decodable {
    let fid: FIDValue
    let name: String
    let info: String?
    let id: FIDValue?
    let icon: String?

    enum CodingKeys: String, CodingKey {
        case fid, name, info, id, icon
    }
}

enum FIDValue: Decodable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let s = try? container.decode(String.self), let i = Int(s) {
            self = .int(i)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .int(0)
        }
    }

    var intValue: Int {
        switch self {
        case .int(let i): return i
        case .string(let s): return Int(s) ?? 0
        }
    }
}

struct ForumCategoryAPICategory: Decodable {
    let id: Int?
    let name: String?
    let groups: [ForumCategoryAPIGroup]?
}

struct ForumCategoryAPIResponse: Decodable {
    let result: [ForumCategoryAPICategory]?
}

// MARK: - Display models for grouped forum list (MNGA-style)
struct ForumCategoryDisplay: Identifiable {
    let id: Int
    let name: String
    let groups: [ForumGroupDisplay]
}

struct ForumGroupDisplay: Identifiable {
    let id: Int
    let name: String?
    let forums: [Forum]
}

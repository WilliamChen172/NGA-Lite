//
//  ForumUserContext.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import Foundation

/// 版块内用户属性，依赖 fid。同一用户在不同版块下 levelName、reputation 可能不同。
struct ForumUserContext {
    let fid: Int
    let levelName: String?
    let postnum: Int?
    let reputation: String? // raw "61_120,39_30"

    /// 解析威望求和，用于展示
    var displayReputation: Int? {
        guard let s = reputation, !s.isEmpty else { return nil }
        return s.split(separator: ",").compactMap { part in
            let p = part.split(separator: "_")
            return p.count >= 2 ? Int(p[1]) : nil
        }.reduce(0, +)
    }
}

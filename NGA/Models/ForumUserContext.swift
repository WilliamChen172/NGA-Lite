//
//  ForumUserContext.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import Foundation

/// 版块内用户属性，依赖 fid。同一用户在不同版块下 levelName、fame 可能不同。
struct ForumUserContext {
    let fid: Int
    let levelName: String?
    let postnum: Int?
    /// 威望原始值（MNGA/nuke.php: fame，展示时 ÷10）
    let fame: Int?

    /// 威望展示值 = fame / 10
    var displayReputation: Int? {
        guard let f = fame else { return nil }
        return f / 10
    }
}

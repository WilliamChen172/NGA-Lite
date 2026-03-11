//
//  MockData.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

/// Mock data for previews and testing. Aligns with thread.php / read.php API structures.
enum MockData {
    static let forums: [Forum] = [
        Forum(fid: -447601, name: "艾泽拉斯议事厅", name2: "议事厅", description: "魔兽主讨论区", parent: 1, subForums: nil),
        Forum(fid: 7, name: "游戏综合", name2: nil, description: "游戏讨论区", parent: nil, subForums: nil),
        Forum(fid: 2, name: "动漫综合", name2: nil, description: "动漫讨论", parent: nil, subForums: nil),
        Forum(fid: 3, name: "影视综合", name2: nil, description: "影视娱乐", parent: nil, subForums: nil),
        Forum(fid: 4, name: "数码科技", name2: nil, description: "科技产品", parent: nil, subForums: nil),
        Forum(fid: 5, name: "体育运动", name2: nil, description: "体育赛事", parent: nil, subForums: nil),
        Forum(fid: 6, name: "美食天地", name2: nil, description: "美食分享", parent: nil, subForums: nil),
        Forum(fid: 8, name: "生活杂谈", name2: nil, description: "日常生活", parent: nil, subForums: nil),
    ]

    /// Thread list mock (thread.php __T format). fid matches forums.
    static let threads: [ForumThread] = [
        ForumThread(tid: 5627431, fid: -447601, subject: "【讨论】2026年最期待的游戏", authorId: 7989705, author: "lintx", postDate: 1350226550, replyCount: 352, lastPost: 1374123445),
        ForumThread(tid: 5627432, fid: -447601, subject: "【攻略】新手入门指南完整版", authorId: 2, author: "攻略达人", postDate: 1350226600, replyCount: 89, lastPost: 1374123500),
        ForumThread(tid: 5627433, fid: -447601, subject: "【爆料】下周将有重大更新", authorId: 3, author: "消息灵通", postDate: 1350226650, replyCount: 256, lastPost: 1374123550),
        ForumThread(tid: 5627434, fid: -447601, subject: "大家觉得这个角色怎么样？", authorId: 4, author: "萌新提问", postDate: 1350226700, replyCount: 45, lastPost: 1374123600),
        ForumThread(tid: 5627435, fid: -447601, subject: "【分享】我的游戏收藏展示", authorId: 5, author: "收藏家", postDate: 1350226750, replyCount: 78, lastPost: 1374123650),
    ]

    static let posts: [Post] = [
        Post(pid: 1, tid: 5627431, fid: -447601, content: "<p>这是主楼内容，今年有很多好游戏值得期待！</p>", authorId: 7989705, author: "lintx", floor: 1, postDate: nil),
        Post(pid: 2, tid: 5627431, fid: -447601, content: "<p>同意！特别期待某某游戏的发售</p>", authorId: 6, author: "路人甲", floor: 2, postDate: nil),
        Post(pid: 3, tid: 5627431, fid: -447601, content: "<p>我觉得今年会是游戏大年</p>", authorId: 7, author: "资深玩家", floor: 3, postDate: nil),
    ]

    /// Mock author info for preview. Keys: authorIds from posts.
    static let authorMap: [Int: UserInForum] = [
        7989705: UserInForum(
            user: User(uid: 7989705, username: "lintx", nickname: nil, avatar: nil),
            forumContext: ForumUserContext(fid: -447601, levelName: "学徒", postnum: 352, reputation: "61_120")
        ),
        6: UserInForum(
            user: User(uid: 6, username: "路人甲", nickname: nil, avatar: nil),
            forumContext: ForumUserContext(fid: -447601, levelName: "新兵", postnum: 89, reputation: nil)
        ),
        7: UserInForum(
            user: User(uid: 7, username: "资深玩家", nickname: nil, avatar: nil),
            forumContext: ForumUserContext(fid: -447601, levelName: "大元帅", postnum: 1250, reputation: "61_500")
        ),
    ]

    static let user = User(uid: 1, username: "testuser", nickname: "测试用户", avatar: nil)
}

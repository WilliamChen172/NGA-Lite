//
//  ForumThread.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

struct ForumThread: Identifiable, Codable, Hashable {
    let tid: Int
    let fid: Int
    let subject: String
    let authorId: Int?
    let author: String?
    let postDate: Int?
    let replyCount: Int?
    let lastPost: Int?
    let firstImageUrl: String?
    let imageCount: Int

    var id: Int { tid }

    init(tid: Int, fid: Int, subject: String, authorId: Int?, author: String?, postDate: Int?, replyCount: Int?, lastPost: Int?, firstImageUrl: String? = nil, imageCount: Int = 0) {
        self.tid = tid
        self.fid = fid
        self.subject = subject
        self.authorId = authorId
        self.author = author
        self.postDate = postDate
        self.replyCount = replyCount
        self.lastPost = lastPost
        self.firstImageUrl = firstImageUrl
        self.imageCount = imageCount
    }

    func hash(into hasher: inout Hasher) { hasher.combine(tid) }
    static func == (lhs: ForumThread, rhs: ForumThread) -> Bool { lhs.tid == rhs.tid }

    enum CodingKeys: String, CodingKey {
        case tid
        case fid
        case subject
        case authorId = "authorid"
        case author
        case postDate = "postdate"
        case replyCount = "reply_count"
        case replies
        case lastPost = "lastpost"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tid = try c.decode(Int.self, forKey: .tid)
        fid = try c.decode(Int.self, forKey: .fid)
        subject = try c.decode(String.self, forKey: .subject)
        authorId = try c.decodeIfPresent(Int.self, forKey: .authorId)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        postDate = try c.decodeIfPresent(Int.self, forKey: .postDate)
        replyCount = try c.decodeIfPresent(Int.self, forKey: .replyCount)
            ?? c.decodeIfPresent(Int.self, forKey: .replies)
        lastPost = try c.decodeIfPresent(Int.self, forKey: .lastPost)
        firstImageUrl = nil
        imageCount = 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tid, forKey: .tid)
        try c.encode(fid, forKey: .fid)
        try c.encode(subject, forKey: .subject)
        try c.encodeIfPresent(authorId, forKey: .authorId)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encodeIfPresent(postDate, forKey: .postDate)
        try c.encodeIfPresent(replyCount, forKey: .replyCount)
        try c.encodeIfPresent(lastPost, forKey: .lastPost)
    }
}

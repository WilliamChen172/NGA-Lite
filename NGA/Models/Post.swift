//
//  Post.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

struct Post: Identifiable, Codable {
    let pid: Int
    let tid: Int
    let fid: Int
    let content: String?
    let authorId: Int?
    let author: String?
    let floor: Int?
    let postDate: Int?
    let score: Int?   // 点赞
    let score2: Int?  // 点踩
    let fromClient: String? // 发帖端，如 "7 iOS"、"8 Android"

    var id: Int { pid != 0 ? pid : -tid } // main post pid=0, use -tid to avoid collision

    enum CodingKeys: String, CodingKey {
        case pid
        case tid
        case fid
        case content
        case authorId = "authorid"
        case author
        case floor
        case postDate = "postdate"
        case postDateTimestamp = "postdatetimestamp"
        case score
        case score2 = "score_2"
        case fromClient = "from_client"
    }

    init(pid: Int, tid: Int, fid: Int, content: String?, authorId: Int?, author: String?, floor: Int?, postDate: Int?, score: Int? = nil, score2: Int? = nil, fromClient: String? = nil) {
        self.pid = pid
        self.tid = tid
        self.fid = fid
        self.content = content
        self.authorId = authorId
        self.author = author
        self.floor = floor
        self.postDate = postDate
        self.score = score
        self.score2 = score2
        self.fromClient = fromClient
    }

    func withScores(score: Int?, score2: Int?) -> Post {
        Post(pid: pid, tid: tid, fid: fid, content: content, authorId: authorId, author: author, floor: floor, postDate: postDate, score: score ?? self.score, score2: score2 ?? self.score2, fromClient: fromClient)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode pid - try Int first, then String
        if let pidInt = try? c.decode(Int.self, forKey: .pid) {
            pid = pidInt
        } else if let pidString = try? c.decode(String.self, forKey: .pid) {
            pid = Int(pidString) ?? 0
        } else {
            pid = 0
        }
        
        // Decode tid - try Int first, then String
        if let tidInt = try? c.decode(Int.self, forKey: .tid) {
            tid = tidInt
        } else if let tidString = try? c.decode(String.self, forKey: .tid) {
            tid = Int(tidString) ?? 0
        } else {
            tid = 0
        }
        
        // Decode fid - try Int first, then String
        if let fidInt = try? c.decode(Int.self, forKey: .fid) {
            fid = fidInt
        } else if let fidString = try? c.decode(String.self, forKey: .fid) {
            fid = Int(fidString) ?? 0
        } else {
            fid = 0
        }
        
        content = try c.decodeIfPresent(String.self, forKey: .content)
        
        // Decode authorId - try Int first, then String
        if let authorIdInt = try? c.decode(Int.self, forKey: .authorId) {
            authorId = authorIdInt
        } else if let authorIdString = try? c.decode(String.self, forKey: .authorId) {
            authorId = Int(authorIdString)
        } else {
            authorId = nil
        }
        
        author = try c.decodeIfPresent(String.self, forKey: .author)
        
        // Decode floor - try Int first, then String
        if let floorInt = try? c.decode(Int.self, forKey: .floor) {
            floor = floorInt
        } else if let floorString = try? c.decode(String.self, forKey: .floor) {
            floor = Int(floorString)
        } else {
            floor = nil
        }
        
        // Decode postDate - try multiple keys and types
        if let postDateInt = try? c.decode(Int.self, forKey: .postDate) {
            postDate = postDateInt
        } else if let postDateTimestampInt = try? c.decode(Int.self, forKey: .postDateTimestamp) {
            postDate = postDateTimestampInt
        } else if let postDateString = try? c.decode(String.self, forKey: .postDate) {
            postDate = Int(postDateString)
        } else if let postDateTimestampString = try? c.decode(String.self, forKey: .postDateTimestamp) {
            postDate = Int(postDateTimestampString)
        } else {
            postDate = nil
        }

        score = (try? c.decode(Int.self, forKey: .score)) ?? (try? c.decode(String.self, forKey: .score)).flatMap { Int($0) }
        score2 = (try? c.decode(Int.self, forKey: .score2)) ?? (try? c.decode(String.self, forKey: .score2)).flatMap { Int($0) }
        fromClient = try c.decodeIfPresent(String.self, forKey: .fromClient)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(pid, forKey: .pid)
        try c.encode(tid, forKey: .tid)
        try c.encode(fid, forKey: .fid)
        try c.encodeIfPresent(content, forKey: .content)
        try c.encodeIfPresent(authorId, forKey: .authorId)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encodeIfPresent(floor, forKey: .floor)
        try c.encodeIfPresent(postDate, forKey: .postDate)
        try c.encodeIfPresent(score, forKey: .score)
        try c.encodeIfPresent(score2, forKey: .score2)
        try c.encodeIfPresent(fromClient, forKey: .fromClient)
    }
}

//
//  TimeFormatter.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import Foundation

enum TimeFormatter {
    /// Formats timestamp as relative time: "刚刚", "5分钟前", "2小时前", "3天前", or "MM-dd"
    static func formatRelativeTime(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return "刚刚"
        } else if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else if seconds < 2592000 {
            return "\(seconds / 86400)天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }

    /// Formats timestamp as full date-time: "2026-03-10 21:39"
    static func formatFullTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    /// Alias for formatFullTimestamp (used by PostDetailView)
    static func formatFullDateTime(_ timestamp: Int) -> String {
        formatFullTimestamp(timestamp)
    }
}

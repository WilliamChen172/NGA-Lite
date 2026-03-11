//
//  APIConnectionTests.swift
//  NGATests
//
//  Created by William Chen on 3/11/26.
//

import Foundation
import Testing
@testable import NGA

/// Integration tests that verify connectivity to the NGA API.
/// Run these to diagnose connection issues. Requires network access.
struct APIConnectionTests {

    @Test("Home category endpoint returns data")
    func homeCategoryReturnsData() async throws {
        let forums = try await ForumService.shared.getForums()
        #expect(forums.count > 0, "Expected at least one forum from home/category API")
    }

    @Test("Home category forums have valid structure")
    func forumsHaveValidStructure() async throws {
        let forums = try await ForumService.shared.getForums()
        for forum in forums.prefix(10) {
            #expect(!forum.name.isEmpty, "Forum name should not be empty")
            #expect(forum.fid != 0 || forum.name.isEmpty == false, "Forum fid or name should be valid")
        }
    }

    @Test("All three NGA domains are reachable (bbs.nga.cn, ngabbs.com, nga.178.com)")
    func allDomainsReachable() async throws {
        let domains = ["https://bbs.nga.cn", "https://ngabbs.com", "https://nga.178.com"]
        let apiPath = "/app_api.php?__lib=home&__act=category&_v=2"
        var failures: [String] = []

        for domain in domains {
            guard let url = URL(string: domain + apiPath) else {
                failures.append("\(domain): Invalid URL")
                continue
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("NGA/1.0 (iOS) Test", forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let httpResponse = response as? HTTPURLResponse
                if httpResponse?.statusCode != 200 {
                    let body = String(data: data.prefix(100), encoding: .utf8) ?? "invalid"
                    failures.append("\(domain): status \(httpResponse?.statusCode ?? -1), body: \(body)")
                }
            } catch {
                failures.append("\(domain): \(error.localizedDescription)")
            }
        }

        #expect(failures.isEmpty, "Domain failures: \(failures.joined(separator: "; "))")
    }

    @Test("thread.php returns threads for a forum (fid=-447601)")
    func threadListReturnsData() async throws {
        let threads = try await ForumService.shared.getThreads(forumId: -447601, page: 1)
        #expect(threads.count > 0, "Expected at least one thread from thread.php for fid=-447601")
    }
}

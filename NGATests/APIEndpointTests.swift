//
//  APIEndpointTests.swift
//  NGATests
//
//  Tests every API call from the NGA API document. Run to identify which
//  endpoint fails when connection or server issues occur. Requires network.
//

import Foundation
import Testing
@testable import NGA

/// Per-endpoint spec from NGA API doc. Used to verify each API is reachable.
private struct EndpointSpec {
    let lib: String
    let act: String
    let version: Int?
    let method: String  // "GET" or "POST"
    let useNuke: Bool   // true = nuke.php, false = app_api.php
    let extraParams: [String: String]

    var label: String { "\(lib)/\(act)" }
}

private let allEndpoints: [EndpointSpec] = [
    // Check-in
    EndpointSpec(lib: "check_in", act: "check_in", version: nil, method: "GET", useNuke: false, extraParams: ["__output": "14"]),
    EndpointSpec(lib: "check_in", act: "get_stat", version: nil, method: "GET", useNuke: false, extraParams: ["__output": "14"]),
    // Home
    EndpointSpec(lib: "home", act: "category", version: 2, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "hasnew", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "bannerrecm", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "tagforums", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "appcolumns", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "ad", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "home", act: "recmthreads", version: 3, method: "GET", useNuke: false, extraParams: [:]),
    // Subject (list is POST)
    EndpointSpec(lib: "subject", act: "list", version: nil, method: "POST", useNuke: false, extraParams: ["fid": "7", "page": "1"]),
    EndpointSpec(lib: "subject", act: "topped", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "subject", act: "search", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "subject", act: "subscription", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "subject", act: "hot", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // User
    EndpointSpec(lib: "user", act: "subjects", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "user", act: "replys", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "user", act: "detail", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "user", act: "detailname", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Post (list, new, reply are POST)
    EndpointSpec(lib: "post", act: "list", version: nil, method: "POST", useNuke: false, extraParams: ["tid": "1", "page": "1"]),
    EndpointSpec(lib: "post", act: "titletype", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "post", act: "recommend", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "post", act: "check", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "post", act: "new", version: nil, method: "POST", useNuke: false, extraParams: ["fid": "7", "subject": "test", "content": "test"]),
    EndpointSpec(lib: "post", act: "reply", version: nil, method: "POST", useNuke: false, extraParams: ["tid": "1", "content": "test"]),
    EndpointSpec(lib: "post", act: "modify", version: nil, method: "POST", useNuke: false, extraParams: [:]),
    // Message
    EndpointSpec(lib: "message", act: "list", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "message", act: "leave", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "message", act: "send", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "message", act: "reply", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "message", act: "detail", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Gift
    EndpointSpec(lib: "gift", act: "list", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "gift", act: "userlist", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "gift", act: "send", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "gift", act: "setreceive", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Notify
    EndpointSpec(lib: "notify", act: "list", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "notify", act: "unreadcnt", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Nearby
    EndpointSpec(lib: "nearby", act: "updLocAndGetUsersNear", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Block
    EndpointSpec(lib: "block", act: "list", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Forum
    EndpointSpec(lib: "forum", act: "search", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Favor (all)
    EndpointSpec(lib: "favor", act: "all", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Game
    EndpointSpec(lib: "game", act: "query", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "game", act: "items", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "game", act: "scores", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // Match
    EndpointSpec(lib: "match", act: "list", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    EndpointSpec(lib: "match", act: "items", version: nil, method: "GET", useNuke: false, extraParams: [:]),
    // nuke.php
    EndpointSpec(lib: "login", act: "account", version: nil, method: "GET", useNuke: true, extraParams: ["login": "1"]),
    EndpointSpec(lib: "login", act: "account", version: nil, method: "GET", useNuke: true, extraParams: ["logout": "1"]),
    EndpointSpec(lib: "login", act: "iflogin", version: nil, method: "GET", useNuke: true, extraParams: [:]),
]

struct APIEndpointTests {

    @Test("Every API endpoint from the doc is reachable")
    func everyEndpointReachable() async throws {
        let base = Constants.API.baseURL
        let appAPI = "\(base)/app_api.php"
        let nukeURL = "\(base)/nuke.php"

        var connectionFailures: [(String, String)] = []
        var serverErrors: [(String, Int, String)] = []

        for spec in allEndpoints {
            let baseURL = spec.useNuke ? nukeURL : appAPI
            var components = URLComponents(string: baseURL)!
            var queryItems = [
                URLQueryItem(name: "__lib", value: spec.lib),
                URLQueryItem(name: "__act", value: spec.act)
            ]
            if let v = spec.version {
                queryItems.append(URLQueryItem(name: "_v", value: "\(v)"))
            }
            if spec.method == "GET" {
                for (k, v) in spec.extraParams {
                    queryItems.append(URLQueryItem(name: k, value: v))
                }
            }
            components.queryItems = queryItems

            guard let url = components.url else {
                connectionFailures.append((spec.label, "Invalid URL"))
                continue
            }

            var request = URLRequest(url: url)
            request.httpMethod = spec.method
            request.setValue("NGA/1.0 (iOS) Test", forHTTPHeaderField: "User-Agent")
            if spec.method == "POST" && !spec.extraParams.isEmpty {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = spec.extraParams
                    .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                    .joined(separator: "&")
                    .data(using: .utf8)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    connectionFailures.append((spec.label, "No HTTP response"))
                    continue
                }
                if http.statusCode >= 500 {
                    let body = String(data: data.prefix(150), encoding: .utf8) ?? "n/a"
                    serverErrors.append((spec.label, http.statusCode, body))
                }
                // 2xx, 401, 400, 404 etc. = reachable; connection OK
            } catch {
                connectionFailures.append((spec.label, error.localizedDescription))
            }
        }

        var messages: [String] = []
        if !connectionFailures.isEmpty {
            messages.append("Connection failures (unreachable):")
            for (label, err) in connectionFailures {
                messages.append("  - \(label): \(err)")
            }
        }
        if !serverErrors.isEmpty {
            messages.append("Server errors (5xx):")
            for (label, code, body) in serverErrors {
                messages.append("  - \(label): \(code), body: \(body.prefix(80))...")
            }
        }
        #expect(
            connectionFailures.isEmpty,
            "\(messages.joined(separator: "\n"))"
        )
        if !serverErrors.isEmpty {
            Issue.record("\(serverErrors.count) endpoint(s) returned 5xx (server-side): \(serverErrors.map { "\($0.0): \($0.1)" }.joined(separator: ", "))")
        }
    }

    @Test("Each endpoint reports status for debugging")
    func eachEndpointReportsStatus() async throws {
        let base = Constants.API.baseURL
        let appAPI = "\(base)/app_api.php"
        let nukeURL = "\(base)/nuke.php"
        var results: [(String, String)] = []

        for spec in allEndpoints {
            let baseURL = spec.useNuke ? nukeURL : appAPI
            var components = URLComponents(string: baseURL)!
            var queryItems = [
                URLQueryItem(name: "__lib", value: spec.lib),
                URLQueryItem(name: "__act", value: spec.act)
            ]
            if let v = spec.version {
                queryItems.append(URLQueryItem(name: "_v", value: "\(v)"))
            }
            if spec.method == "GET" {
                for (k, v) in spec.extraParams {
                    queryItems.append(URLQueryItem(name: k, value: v))
                }
            }
            components.queryItems = queryItems

            guard let url = components.url else {
                results.append((spec.label, "INVALID_URL"))
                continue
            }

            var request = URLRequest(url: url)
            request.httpMethod = spec.method
            request.setValue("NGA/1.0 (iOS) Test", forHTTPHeaderField: "User-Agent")
            if spec.method == "POST" && !spec.extraParams.isEmpty {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = spec.extraParams
                    .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                    .joined(separator: "&")
                    .data(using: .utf8)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let http = response as? HTTPURLResponse
                let code = http?.statusCode ?? -1
                let status: String
                if (200..<300).contains(code) { status = "OK(\(code))" }
                else if code == 401 { status = "UNAUTH(401)" }
                else if code == 400 { status = "BAD_REQ(400)" }
                else if code == 404 { status = "NOT_FOUND(404)" }
                else if code >= 500 { status = "SRV_ERR(\(code))" }
                else { status = "HTTP(\(code))" }
                results.append((spec.label, status))
            } catch {
                results.append((spec.label, "FAIL: \(error.localizedDescription)"))
            }
        }

        let report = results.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
        let failures = results.filter { $0.1.hasPrefix("FAIL") || $0.1.hasPrefix("INVALID") }
        #expect(failures.isEmpty, "Endpoint status report:\n\(report)")
    }
}

//
//  AppError.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

enum AppError: LocalizedError {
    case network(underlying: Error)
    case unauthorized
    case serverError(code: Int, message: String)
    case decodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingFailed:
            return "Failed to parse server response."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

//
//  LogSubsystem.swift
//  NGA
//
//  Subsystems for log categorization. Use to filter in Console.app.
//

import Foundation

enum LogSubsystem: String, CaseIterable {
    case app = "App"
    case api = "API"
    case auth = "Auth"
    case forum = "Forum"
    case keychain = "Keychain"
    case ui = "UI"
    case general = "General"
}

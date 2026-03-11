//
//  Logger.swift
//  NGA
//
//  Thin wrapper around swift-log. Create per subsystem via `Logger.for(_:)`.
//

import Foundation
import Logging

extension Logger {
    /// Logger for the given subsystem. Use for filtering in Console and log aggregation.
    static func `for`(_ subsystem: LogSubsystem) -> Logger {
        var log = Logger(label: "Rosario.NGA.\(subsystem.rawValue)")
        #if DEBUG
        log.logLevel = .debug
        #else
        log.logLevel = .info
        #endif
        return log
    }

    /// Log an error's description.
    func error(_ error: Swift.Error, file: String = #file, function: String = #function, line: UInt = #line) {
        self.error("\(error.localizedDescription)", file: file, function: function, line: line)
    }
}

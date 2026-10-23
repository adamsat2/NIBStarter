//
//  ValidationIssue.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public enum IssueSeverity: String, Sendable {
    case error = "error"
    case warning = "warning"
}

public struct ValidationIssue: Sendable, Equatable {
    public let filePath: String
    public let line: Int
    public let severity: IssueSeverity
    public let message: String
    
    public init(filePath: String, line: Int, severity: IssueSeverity, message: String) {
        self.filePath = filePath
        self.line = line
        self.severity = severity
        self.message = message
    }
    
    /// Formats the issue according to Xcode's build diagnostic specification:
    /// `<file>:<line>: <error|warning>: [NIBStarter] <message>`
    public var xcodeFormattedMessage: String {
        return "\(filePath):\(line): \(severity.rawValue): [NIBStarter] \(message)"
    }
}

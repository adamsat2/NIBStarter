//
//  SourceModel.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

/// Represents an outlet declared in source code.
public struct CodeOutlet: Hashable, Sendable {
    public let name: String
    public let fileURL: URL
    public let line: Int
}

/// Represents an action method declared in source code.
public struct CodeAction: Hashable, Sendable {
    /// Normalized selector name (e.g., "didTapSubmit:" or "didTapSubmit")
    public let selectorName: String
    public let fileURL: URL
    public let line: Int
}

/// Represents a class and all its declared outlets and actions across its definition and extensions.
public struct ClassCodeModel: Sendable {
    public let className: String
    public var outlets: Set<String>
    public var actions: Set<String>
    public var sourceFiles: Set<URL>
    
    public init(className: String, outlets: Set<String> = [], actions: Set<String> = [], sourceFiles: Set<URL> = []) {
        self.className = className
        self.outlets = outlets
        self.actions = actions
        self.sourceFiles = sourceFiles
    }
}

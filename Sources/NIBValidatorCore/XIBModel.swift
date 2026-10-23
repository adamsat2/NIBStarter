//
//  XIBModel.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

/// Represents a single @IBOutlet connection in a XIB.
public struct XIBOutlet: Sendable {
    public let propertyName: String
    public let destinationID: String
    public let lineNumber: Int
}

/// Represents a single @IBAction connection in a XIB targeting File's Owner.
public struct XIBAction: Sendable {
    public let selectorName: String
    public let destinationID: String
    public let lineNumber: Int
}

/// Aggregated data extracted from a single `.xib` file.
public struct XIBModel: Sendable {
    public let fileURL: URL
    public let ownerClass: String
    public let ownerID: String
    public let outlets: [XIBOutlet]
    public let actions: [XIBAction]
    
    /// True if an outlet with name "view" is hooked to File's Owner.
    public var hasViewOutlet: Bool {
        outlets.contains { $0.propertyName == "view" }
    }
}

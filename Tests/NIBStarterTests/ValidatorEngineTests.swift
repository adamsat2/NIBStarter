//
//  ValidatorEngineTests.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import XCTest
@testable import NIBValidatorCore

final class ValidatorEngineTests: XCTestCase {
    
    func testCatchOrphanedOutlet() {
        // Setup XIB with an outlet named 'brokenButton' that does not exist in code
        let xib = XIBModel(
            fileURL: URL(fileURLWithPath: "/Projects/App/LoginViewController.xib"),
            ownerClass: "LoginViewController",
            ownerID: "-1",
            outlets: [
                XIBOutlet(propertyName: "view", destinationID: "view-1", lineNumber: 10),
                XIBOutlet(propertyName: "brokenButton", destinationID: "btn-1", lineNumber: 25)
            ],
            actions: []
        )
        
        // Code model only has 'usernameField'
        let code = ClassCodeModel(
            className: "LoginViewController",
            outlets: ["usernameField"],
            actions: [],
            sourceFiles: [URL(fileURLWithPath: "/Projects/App/LoginViewController.swift")]
        )
        
        let issues = XIBValidator.validate(xibs: [xib], against: ["LoginViewController": code])
        
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(issues.first?.line, 25)
        XCTAssertTrue(issues.first?.message.contains("Orphaned outlet 'brokenButton'") ?? false)
    }
    
    func testCatchOrphanedAction() {
        // Setup XIB with action 'didTapOldButton:'
        let xib = XIBModel(
            fileURL: URL(fileURLWithPath: "/Projects/App/ProfileViewController.xib"),
            ownerClass: "ProfileViewController",
            ownerID: "-1",
            outlets: [
                XIBOutlet(propertyName: "view", destinationID: "view-1", lineNumber: 10)
            ],
            actions: [
                XIBAction(selectorName: "didTapOldButton:", destinationID: "-1", lineNumber: 42)
            ]
        )
        
        let code = ClassCodeModel(
            className: "ProfileViewController",
            outlets: [],
            actions: ["didTapSave:"],
            sourceFiles: [URL(fileURLWithPath: "/Projects/App/ProfileViewController.swift")]
        )
        
        let issues = XIBValidator.validate(xibs: [xib], against: ["ProfileViewController": code])
        
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(issues.first?.line, 42)
        XCTAssertTrue(issues.first?.message.contains("Orphaned action 'didTapOldButton:'") ?? false)
    }
    
    func testCatchMissingViewOutlet() {
        let xib = XIBModel(
            fileURL: URL(fileURLWithPath: "/Projects/App/EmptyViewController.xib"),
            ownerClass: "EmptyViewController",
            ownerID: "-1",
            outlets: [], // No 'view' outlet
            actions: []
        )
        
        let code = ClassCodeModel(className: "EmptyViewController")
        let issues = XIBValidator.validate(xibs: [xib], against: ["EmptyViewController": code])
        
        XCTAssertTrue(issues.contains { $0.message.contains("no root 'view' outlet connected") })
    }
    
    func testValidMatchingPassesWithZeroIssues() {
        let xib = XIBModel(
            fileURL: URL(fileURLWithPath: "/Projects/App/GoodViewController.xib"),
            ownerClass: "GoodViewController",
            ownerID: "-1",
            outlets: [
                XIBOutlet(propertyName: "view", destinationID: "v1", lineNumber: 5),
                XIBOutlet(propertyName: "titleLabel", destinationID: "lbl1", lineNumber: 12)
            ],
            actions: [
                XIBAction(selectorName: "saveTapped:", destinationID: "-1", lineNumber: 18)
            ]
        )
        
        let code = ClassCodeModel(
            className: "GoodViewController",
            outlets: ["titleLabel"],
            actions: ["saveTapped:"],
            sourceFiles: [URL(fileURLWithPath: "/Projects/App/GoodViewController.swift")]
        )
        
        let issues = XIBValidator.validate(xibs: [xib], against: ["GoodViewController": code])
        XCTAssertTrue(issues.isEmpty)
    }
}

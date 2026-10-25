//
//  CodeGeneratorTests.swift
//  NIBStarterTests
//
//  Created by Adam Stern on 25/10/2026.
//

import XCTest
import NIBStarterCLI

final class CodeGeneratorTests: XCTestCase {
    
    private var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if let dir = tempDirectory, FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        try super.tearDownWithError()
    }
    
    func testMacOSObjectiveCCodeGeneratorProducesValidMainMWithoutNSApplicationMain() throws {
        let appName = "TestMacApp"
        try CodeGenerator.generateStarterFiles(
            in: tempDirectory,
            appName: appName,
            platform: .macos,
            language: .objc
        )
        
        let mainMURL = tempDirectory.appendingPathComponent("main.m")
        XCTAssertTrue(FileManager.default.fileExists(atPath: mainMURL.path), "main.m should be generated for macOS Objective-C targets")
        
        let mainMContent = try String(contentsOf: mainMURL, encoding: .utf8)
        
        // Ensure NSApplicationMain is NOT present
        XCTAssertFalse(
            mainMContent.contains("NSApplicationMain"),
            "main.m should not invoke NSApplicationMain because it causes incorrect NIB fallback loading"
        )
        
        // Ensure explicit AppDelegate instantiation and run loop execution are present
        XCTAssertTrue(mainMContent.contains("[NSApplication sharedApplication]"))
        XCTAssertTrue(mainMContent.contains("AppDelegate *delegate = [[AppDelegate alloc] init]"))
        XCTAssertTrue(mainMContent.contains("app.delegate = delegate"))
        XCTAssertTrue(mainMContent.contains("[app run]"))
        
        // Verify supporting files
        let appDelegateHURL = tempDirectory.appendingPathComponent("AppDelegate.h")
        let appDelegateMURL = tempDirectory.appendingPathComponent("AppDelegate.m")
        let rootHURL = tempDirectory.appendingPathComponent("RootViewController.h")
        let rootMURL = tempDirectory.appendingPathComponent("RootViewController.m")
        let rootXibURL = tempDirectory.appendingPathComponent("RootViewController.xib")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: appDelegateHURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: appDelegateMURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootHURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootMURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootXibURL.path))
    }
}

//
//  CodeGeneratorTests.swift
//  NIBStarterTests
//
//  Created by Adam Stern on 25/10/2026.
//

import XCTest
@testable import NIBStarterCLI
import XcodeProj
import PathKit

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
    
    func testMacOSSwiftCodeGeneratorProducesExplicitMainEntryPoint() throws {
        let appName = "TestMacSwiftApp"
        try CodeGenerator.generateStarterFiles(
            in: tempDirectory,
            appName: appName,
            platform: .macos,
            language: .swift
        )
        
        let appDelegateURL = tempDirectory.appendingPathComponent("AppDelegate.swift")
        let rootVCURL = tempDirectory.appendingPathComponent("RootViewController.swift")
        let rootXibURL = tempDirectory.appendingPathComponent("RootViewController.xib")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: appDelegateURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootVCURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootXibURL.path))
        
        let appDelegateContent = try String(contentsOf: appDelegateURL, encoding: .utf8)
        XCTAssertTrue(appDelegateContent.contains("static func main()"))
        XCTAssertTrue(appDelegateContent.contains("let app = NSApplication.shared"))
        XCTAssertTrue(appDelegateContent.contains("app.delegate = delegate"))
        XCTAssertTrue(appDelegateContent.contains("app.run()"))
    }
    
    func testIOSObjectiveCCodeGeneratorCreatesSceneDelegateAndRootViewController() throws {
        let appName = "TestIOSObjCApp"
        try CodeGenerator.generateStarterFiles(
            in: tempDirectory,
            appName: appName,
            platform: .ios,
            language: .objc
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("RootViewController.h").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("RootViewController.m").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("RootViewController.xib").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("SceneDelegate.h").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("SceneDelegate.m").path))
    }
    
    func testDefaultViewControllerRemovedDuringScaffolding() throws {
        let defaultVC = """
        //
        //  ViewController.swift
        //  MyApp
        //
        import UIKit

        class ViewController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
            }
        }
        """
        let vcURL = tempDirectory.appendingPathComponent("ViewController.swift")
        try defaultVC.write(to: vcURL, atomically: true, encoding: .utf8)
        
        try CodeGenerator.generateStarterFiles(
            in: tempDirectory,
            appName: "MyApp",
            platform: .ios,
            language: .swift
        )
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: vcURL.path), "Default template ViewController.swift should be removed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("RootViewController.swift").path))
    }
    
    func testLanguageAndPlatformAutoDetection() throws {
        let projURL = tempDirectory.appendingPathComponent("SampleObjC.xcodeproj")
        let sourceDir = tempDirectory.appendingPathComponent("SampleObjC")
        try FileManager.default.createDirectory(at: projURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 77;
            objects = {
                INFOPLIST_KEY_NSMainStoryboardFile = Main;
                SDKROOT = macosx;
            };
            rootObject = 123456;
        }
        """
        try pbxprojContent.write(to: projURL.appendingPathComponent("project.pbxproj"), atomically: true, encoding: .utf8)
        try "#import <Cocoa/Cocoa.h>".write(to: sourceDir.appendingPathComponent("AppDelegate.m"), atomically: true, encoding: .utf8)
        
        XCTAssertEqual(ConvertCommand.detectPlatform(at: projURL, sourceDir: sourceDir), .macos)
        XCTAssertEqual(ConvertCommand.detectLanguage(at: projURL, sourceDir: sourceDir), .objc)
    }
    
    func testConvertCommandAcceptsXcodePluginTargetArgument() throws {
        let cmd = try ConvertCommand.parse([
            "--project", "/tmp/Test.xcodeproj",
            "--target", "TestApp",
            "ExtraPositionalTarget"
        ])
        XCTAssertEqual(cmd.project, "/tmp/Test.xcodeproj")
        XCTAssertEqual(cmd.target, ["TestApp"])
        XCTAssertEqual(cmd.extraArguments, ["ExtraPositionalTarget"])
    }
    
    func testLocalPackageReferencePreservation() {
        let original = """
        /* Begin XCSwiftPackageProductDependency section */
        \t\tAA11223344556677889900AA /* NIBStarter */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tpackage = BB11223344556677889900BB /* XCLocalSwiftPackageReference "../NIBStarter" */;
        \t\t\tproductName = NIBStarter;
        \t\t};
        /* End XCSwiftPackageProductDependency section */
        """
        let strippedByXcodeProj = """
        /* Begin XCSwiftPackageProductDependency section */
        \t\tAA11223344556677889900AA /* NIBStarter */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tproductName = NIBStarter;
        \t\t};
        /* End XCSwiftPackageProductDependency section */
        """
        let extracted = StoryboardStripper.extractLocalPackageReferences(from: original)
        let restored = StoryboardStripper.restoreLocalPackageReferences(in: strippedByXcodeProj, references: extracted)
        XCTAssertTrue(restored.contains("package = BB11223344556677889900BB /* XCLocalSwiftPackageReference \"../NIBStarter\" */;"))
    }
    
    func testCleanInvalidPluginFrameworkLinks() throws {
        let projURL = tempDirectory.appendingPathComponent("TestApp.xcodeproj")
        try FileManager.default.createDirectory(at: projURL, withIntermediateDirectories: true)
        let pbxprojURL = projURL.appendingPathComponent("project.pbxproj")
        
        let samplePbxproj = """
        /* Begin PBXBuildFile section */
        \t\tE5DE9543308EE56600724D19 /* NIBStarter in Frameworks */ = {isa = PBXBuildFile; productRef = E5DE9542308EE56600724D19 /* NIBStarter */; };
        \t\tE5DE954B308EE58500724D19 /* NIBValidatorPlugin in Frameworks */ = {isa = PBXBuildFile; productRef = 4E494256414C494441544F52 /* NIBValidatorPlugin */; };
        /* End PBXBuildFile section */
        /* Begin PBXFrameworksBuildPhase section */
        \t\tE5DE9521308EE50000724D19 /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tfiles = (
        \t\t\t\tE5DE954B308EE58500724D19 /* NIBValidatorPlugin in Frameworks */,
        \t\t\t\tE5DE9543308EE56600724D19 /* NIBStarter in Frameworks */,
        \t\t\t);
        \t\t};
        /* End PBXFrameworksBuildPhase section */
        /* Begin PBXNativeTarget section */
        \t\t111122223333444455556666 /* TestApp */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tname = TestApp;
        \t\t\tpackageProductDependencies = (
        \t\t\t\t4E494256414C494441544F52 /* NIBValidatorPlugin */,
        \t\t\t\tE5DE9542308EE56600724D19 /* NIBStarter */,
        \t\t\t);
        \t\t};
        /* End PBXNativeTarget section */
        /* Begin XCSwiftPackageProductDependency section */
        \t\t4E494256414C494441544F52 /* NIBValidatorPlugin */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tpackage = BB11223344556677889900BB /* XCRemoteSwiftPackageReference "NIBStarter" */;
        \t\t\tproductName = "plugin:NIBValidatorPlugin";
        \t\t};
        \t\tE5DE9542308EE56600724D19 /* NIBStarter */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tpackage = BB11223344556677889900BB /* XCRemoteSwiftPackageReference "NIBStarter" */;
        \t\t\tproductName = NIBStarter;
        \t\t};
        /* End XCSwiftPackageProductDependency section */
        """
        try samplePbxproj.write(to: pbxprojURL, atomically: true, encoding: .utf8)
        
        StoryboardStripper.cleanInvalidPluginFrameworkLinks(in: projURL)
        
        let updated = try String(contentsOf: pbxprojURL, encoding: .utf8)
        XCTAssertFalse(updated.contains("NIBValidatorPlugin"))
        XCTAssertTrue(updated.contains("productName = NIBStarter;"))
    }
}

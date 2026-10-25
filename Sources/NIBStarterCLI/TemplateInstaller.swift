//
//  TemplateInstaller.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation

public struct TemplateInstaller {
    
    // File templates must be placed inside ~/Library/Developer/Xcode/Templates/File Templates/<Category>
    private static var targetDirectories: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Library/Developer/Xcode/Templates/File Templates/NIBStarter")
        ]
    }
    
    // Legacy directory that should be cleaned up if present
    private static var legacyDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/Templates/NIBStarter")
    }
    
    public static func install() throws {
        let fileManager = FileManager.default
        
        // Clean up any legacy directory outside File Templates
        if fileManager.fileExists(atPath: legacyDirectory.path) {
            try? fileManager.removeItem(at: legacyDirectory)
        }
        
        for baseDir in targetDirectories {
            if fileManager.fileExists(atPath: baseDir.path) {
                try? fileManager.removeItem(at: baseDir)
            }
            try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
            
            try installTemplate(
                in: baseDir,
                folderName: "NibInstantiable UIViewController (Swift).xctemplate",
                summary: "NibInstantiable UIViewController (Swift)",
                platform: "com.apple.platform.iphoneos",
                sortOrder: "1",
                files: [
                    ("___FILEBASENAME___.swift", swiftUIViewControllerTemplate()),
                    ("___FILEBASENAME___.xib", iOSXibTemplate())
                ]
            )
            
            try installTemplate(
                in: baseDir,
                folderName: "NibInstantiable UIViewController (Objective-C).xctemplate",
                summary: "NibInstantiable UIViewController (Objective-C)",
                platform: "com.apple.platform.iphoneos",
                sortOrder: "2",
                files: [
                    ("___FILEBASENAME___.h", objCUIViewControllerHeaderTemplate()),
                    ("___FILEBASENAME___.m", objCUIViewControllerImplementationTemplate()),
                    ("___FILEBASENAME___.xib", iOSXibTemplate())
                ]
            )
            
            try installTemplate(
                in: baseDir,
                folderName: "NibInstantiable NSViewController (Swift).xctemplate",
                summary: "NibInstantiable NSViewController (Swift)",
                platform: "com.apple.platform.macosx",
                sortOrder: "3",
                files: [
                    ("___FILEBASENAME___.swift", swiftNSViewControllerTemplate()),
                    ("___FILEBASENAME___.xib", macOSXibTemplate())
                ]
            )
            
            try installTemplate(
                in: baseDir,
                folderName: "NibInstantiable NSViewController (Objective-C).xctemplate",
                summary: "NibInstantiable NSViewController (Objective-C)",
                platform: "com.apple.platform.macosx",
                sortOrder: "4",
                files: [
                    ("___FILEBASENAME___.h", objCNSViewControllerHeaderTemplate()),
                    ("___FILEBASENAME___.m", objCNSViewControllerImplementationTemplate()),
                    ("___FILEBASENAME___.xib", macOSXibTemplate())
                ]
            )
        }
    }
    
    public static func uninstall() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: legacyDirectory.path) {
            try? fileManager.removeItem(at: legacyDirectory)
        }
        for dir in targetDirectories {
            if fileManager.fileExists(atPath: dir.path) {
                try? fileManager.removeItem(at: dir)
            }
        }
    }
    
    // MARK: - Template Builder
    
    private static func installTemplate(
        in parentDir: URL,
        folderName: String,
        summary: String,
        platform: String,
        sortOrder: String,
        files: [(String, String)]
    ) throws {
        let dir = parentDir.appendingPathComponent(folderName)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let mainTemplateFile = files.first?.0 ?? "___FILEBASENAME___.swift"
        
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>SupportsSwiftPackage</key>
            <true/>
            <key>Kind</key>
            <string>Xcode.IDEFoundation.TextSubstitutionFileTemplateKind</string>
            <key>Description</key>
            <string>\(summary) conforming to NibInstantiable with an auto-wired XIB.</string>
            <key>Summary</key>
            <string>\(summary)</string>
            <key>SortOrder</key>
            <string>\(sortOrder)</string>
            <key>DefaultCompletionName</key>
            <string>MyViewController</string>
            <key>MainTemplateFile</key>
            <string>\(mainTemplateFile)</string>
            <key>Platforms</key>
            <array>
                <string>\(platform)</string>
            </array>
            <key>Options</key>
            <array>
                <dict>
                    <key>Identifier</key>
                    <string>productName</string>
                    <key>Required</key>
                    <true/>
                    <key>Name</key>
                    <string>Class:</string>
                    <key>Description</key>
                    <string>The name of the class to create</string>
                    <key>Type</key>
                    <string>text</string>
                    <key>NotPersisted</key>
                    <true/>
                </dict>
            </array>
        </dict>
        </plist>
        """
        
        try plist.write(to: dir.appendingPathComponent("TemplateInfo.plist"), atomically: true, encoding: .utf8)
        for (name, content) in files {
            try content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
    }
    
    // MARK: - Content Generators
    
    private static func swiftUIViewControllerTemplate() -> String {
        """
        //___FILEHEADER___

        import UIKit
        import NIBStarter

        final class ___FILEBASENAMEASIDENTIFIER___: UIViewController, NibInstantiable {
            override func viewDidLoad() {
                super.viewDidLoad()
                view.backgroundColor = .systemBackground
            }
        }
        """
    }
    
    private static func objCUIViewControllerHeaderTemplate() -> String {
        """
        //___FILEHEADER___

        #import <UIKit/UIKit.h>

        NS_ASSUME_NONNULL_BEGIN

        @interface ___FILEBASENAMEASIDENTIFIER___ : UIViewController
        @end

        NS_ASSUME_NONNULL_END
        """
    }
    
    private static func objCUIViewControllerImplementationTemplate() -> String {
        """
        //___FILEHEADER___

        #import "___FILEBASENAMEASIDENTIFIER___.h"
        #import <NIBStarterObjC/NIBStarterObjC.h>

        @implementation ___FILEBASENAMEASIDENTIFIER___

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor systemBackgroundColor];
        }

        @end
        """
    }
    
    private static func swiftNSViewControllerTemplate() -> String {
        """
        //___FILEHEADER___

        import AppKit
        import NIBStarter

        final class ___FILEBASENAMEASIDENTIFIER___: NSViewController, NibInstantiable {
            override func viewDidLoad() {
                super.viewDidLoad()
            }
        }
        """
    }
    
    private static func objCNSViewControllerHeaderTemplate() -> String {
        """
        //___FILEHEADER___

        #import <AppKit/AppKit.h>

        NS_ASSUME_NONNULL_BEGIN

        @interface ___FILEBASENAMEASIDENTIFIER___ : NSViewController
        @end

        NS_ASSUME_NONNULL_END
        """
    }
    
    private static func objCNSViewControllerImplementationTemplate() -> String {
        """
        //___FILEHEADER___

        #import "___FILEBASENAMEASIDENTIFIER___.h"
        #import <NIBStarterObjC/NIBStarterObjC.h>

        @implementation ___FILEBASENAMEASIDENTIFIER___

        - (void)viewDidLoad {
            [super viewDidLoad];
        }

        @end
        """
    }
    
    // MARK: - XIB Generators
    
    private static func iOSXibTemplate() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0" toolsVersion="22000" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES">
            <device id="retina6_12" orientation="portrait" appearance="light"/>
            <dependencies>
                <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="22000"/>
                <capability name="Safe area layout guides" minToolsVersion="9.0"/>
                <capability name="System colors in document resources" minToolsVersion="11.0"/>
                <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
            </dependencies>
            <objects>
                <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner" customClass="___FILEBASENAMEASIDENTIFIER___">
                    <connections>
                        <outlet property="view" destination="i5M-Pr-FkT" id="sfx-zR-JGt"/>
                    </connections>
                </placeholder>
                <placeholder placeholderIdentifier="IBFirstResponder" id="-2" customClass="UIResponder"/>
                <view clearsContextBeforeDrawing="NO" contentMode="scaleToFill" id="i5M-Pr-FkT">
                    <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                    <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                    <viewLayoutGuide key="safeArea" id="fnl-2z-Ty3"/>
                    <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                </view>
            </objects>
            <resources>
                <systemColor name="systemBackgroundColor">
                    <color white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </systemColor>
            </resources>
        </document>
        """
    }
    
    private static func macOSXibTemplate() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="3.0" toolsVersion="22000" targetRuntime="MacOSX.Cocoa" propertyAccessControl="none" useAutolayout="YES" customObjectInstantitationMethod="direct">
            <dependencies>
                <plugIn identifier="com.apple.InterfaceBuilder.CocoaPlugin" version="22000"/>
                <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
            </dependencies>
            <objects>
                <customObject id="-2" userLabel="File's Owner" customClass="___FILEBASENAMEASIDENTIFIER___">
                    <connections>
                        <outlet property="view" destination="c22-O7-iKe" id="b2m-3d-hWc"/>
                    </connections>
                </customObject>
                <customObject id="-1" userLabel="First Responder" customClass="FirstResponder"/>
                <customObject id="-3" userLabel="Application" customClass="NSObject"/>
                <customView id="c22-O7-iKe">
                    <rect key="frame" x="0.0" y="0.0" width="480" height="272"/>
                    <autoresizingMask key="autoresizingMask" flexibleMaxX="YES" flexibleMinY="YES"/>
                </customView>
            </objects>
        </document>
        """
    }
}

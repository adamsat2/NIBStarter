//
//  ConvertCommand.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser
import XcodeProj
import PathKit

public struct ConvertCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Converts an existing iOS or macOS project to NIBStarter by stripping Storyboards and setting up programmatic bootstrapping."
    )
    
    @Option(name: .shortAndLong, help: "Path to the .xcodeproj file. Defaults to auto-detecting in the current directory.")
    public var project: String?
    
    @Option(name: .long, help: "Platform for the project (ios or macos). Defaults to auto-detecting from project settings.")
    public var platform: ProjectPlatform?
    
    @Option(name: .shortAndLong, help: "Language to use for scaffolding (swift or objc). Defaults to auto-detecting from project files.")
    public var language: ProjectLanguage?
    
    @Flag(inversion: .prefixedNo, help: "Generate starter RootViewController and bootstrapping files.")
    public var scaffold: Bool = true
    
    @Option(name: [.long, .customShort("t")], help: .hidden)
    public var target: [String] = []
    
    @Argument(help: .hidden)
    public var extraArguments: [String] = []
    
    public init() {}
    
    public func run() throws {
        let fileManager = FileManager.default
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        let projectURL: URL
        if let projectPath = project {
            projectURL = URL(fileURLWithPath: projectPath, relativeTo: currentDir).standardizedFileURL
        } else {
            let contents = try fileManager.contentsOfDirectory(at: currentDir, includingPropertiesForKeys: nil)
            guard let autoFound = contents.first(where: { $0.pathExtension == "xcodeproj" }) else {
                throw ValidationError("No .xcodeproj found in the current directory. Specify one using --project <path>.")
            }
            projectURL = autoFound
        }
        
        let appName = projectURL.deletingPathExtension().lastPathComponent
        let finalDir = Self.resolveTargetSourceDirectory(projectURL: projectURL, appName: appName)
        
        // Auto-detect platform and language BEFORE stripping storyboards (since storyboard keys in pbxproj help identify iOS vs macOS)
        let resolvedPlatform = platform ?? Self.detectPlatform(at: projectURL, sourceDir: finalDir)
        let resolvedLanguage = language ?? Self.detectLanguage(at: projectURL, sourceDir: finalDir)
        
        print("[NIBStarter] Converting project: \(projectURL.lastPathComponent)")
        print("  Platform: \(resolvedPlatform.rawValue.uppercased()) | Language: \(resolvedLanguage.rawValue)")
        
        // Strip Storyboards
        let stripper = StoryboardStripper(projectURL: projectURL)
        try stripper.strip()
        print("  - Stripped Storyboard references and build settings from project file")
        print("  - Cleaned Storyboard keys from Info.plist")
        print("  - Removed physical Storyboard files from disk")
        
        // Scaffold starter files
        if scaffold {
            let generatedURLs = try CodeGenerator.generateStarterFiles(
                in: finalDir,
                appName: appName,
                platform: resolvedPlatform,
                language: resolvedLanguage
            )
            
            try Self.trackGeneratedFilesIfNeeded(
                projectURL: projectURL,
                targetDir: finalDir,
                appName: appName,
                generatedURLs: generatedURLs
            )
            
            print("  - Generated \(resolvedPlatform.rawValue.uppercased()) \(resolvedLanguage == .swift ? "Swift" : "Objective-C") RootViewController and matching .xib")
            print("  - Configured bootstrapping entry point")
        }
        
        // Clean up any accidental plugin links in Frameworks, Libraries, and Embedded Content
        StoryboardStripper.cleanInvalidPluginFrameworkLinks(in: projectURL)
        
        print("\n[NIBStarter] Conversion complete. Build and run your project in Xcode (Cmd + R).")
    }
    
    public static func resolveTargetSourceDirectory(projectURL: URL, appName: String) -> URL {
        let fileManager = FileManager.default
        let appDirectory = projectURL.deletingLastPathComponent()
        let directCandidate = appDirectory.appendingPathComponent(appName)
        
        let markerFiles = [
            "AppDelegate.swift", "AppDelegate.m", "AppDelegate.h",
            "SceneDelegate.swift", "SceneDelegate.m", "SceneDelegate.h",
            "ViewController.swift", "ViewController.m", "ViewController.h",
            "main.m"
        ]
        
        if fileManager.fileExists(atPath: directCandidate.path) {
            return directCandidate
        }
        
        if let subdirs = try? fileManager.contentsOfDirectory(
            at: appDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for subdir in subdirs {
                let name = subdir.lastPathComponent
                if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") || name.hasSuffix("Tests") || name == "DerivedData" {
                    continue
                }
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: subdir.path, isDirectory: &isDir), isDir.boolValue {
                    if markerFiles.contains(where: { fileManager.fileExists(atPath: subdir.appendingPathComponent($0).path) }) {
                        return subdir
                    }
                }
            }
        }
        
        return appDirectory
    }
    
    public static func detectPlatform(at projectURL: URL, sourceDir: URL? = nil) -> ProjectPlatform {
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        if let content = try? String(contentsOf: pbxprojURL, encoding: .utf8) {
            if content.contains("INFOPLIST_KEY_NSMainStoryboardFile") || content.contains("INFOPLIST_KEY_NSMainNibFile") {
                return .macos
            }
            if content.contains("INFOPLIST_KEY_UIMainStoryboardFile") || content.contains("INFOPLIST_KEY_UISceneStoryboardFile") {
                return .ios
            }
            if content.contains("SDKROOT = macosx") {
                return .macos
            }
            if content.contains("SDKROOT = iphoneos") {
                return .ios
            }
            if content.contains("IPHONEOS_DEPLOYMENT_TARGET") && !content.contains("MACOSX_DEPLOYMENT_TARGET") {
                return .ios
            }
            if content.contains("MACOSX_DEPLOYMENT_TARGET") && !content.contains("IPHONEOS_DEPLOYMENT_TARGET") {
                return .macos
            }
        }
        
        let searchDir = sourceDir ?? projectURL.deletingLastPathComponent()
        if let enumerator = FileManager.default.enumerator(
            at: searchDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard ["swift", "h", "m", "mm"].contains(ext) else { continue }
                if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                    if fileContent.contains("import AppKit") || fileContent.contains("import Cocoa") ||
                       fileContent.contains("<Cocoa/Cocoa.h>") || fileContent.contains("<AppKit/AppKit.h>") {
                        return .macos
                    }
                    if fileContent.contains("import UIKit") || fileContent.contains("<UIKit/UIKit.h>") {
                        return .ios
                    }
                }
            }
        }
        
        return .ios
    }
    
    public static func detectLanguage(at projectURL: URL, sourceDir: URL? = nil) -> ProjectLanguage {
        let searchDir = sourceDir ?? projectURL.deletingLastPathComponent()
        let fileManager = FileManager.default
        
        var objcFileCount = 0
        var swiftFileCount = 0
        var hasObjCEntryFiles = false
        var hasSwiftEntryFiles = false
        
        let objcEntryNames: Set<String> = ["AppDelegate.m", "SceneDelegate.m", "ViewController.m", "main.m"]
        let swiftEntryNames: Set<String> = ["AppDelegate.swift", "SceneDelegate.swift", "ViewController.swift"]
        
        if let enumerator = fileManager.enumerator(
            at: searchDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let name = fileURL.lastPathComponent
                if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") || name == "DerivedData" {
                    enumerator.skipDescendants()
                    continue
                }
                if objcEntryNames.contains(name) {
                    hasObjCEntryFiles = true
                }
                if swiftEntryNames.contains(name) {
                    hasSwiftEntryFiles = true
                }
                let ext = fileURL.pathExtension.lowercased()
                if ext == "m" || ext == "mm" {
                    objcFileCount += 1
                } else if ext == "swift" {
                    swiftFileCount += 1
                }
            }
        }
        
        if hasObjCEntryFiles && !hasSwiftEntryFiles {
            return .objc
        }
        if hasSwiftEntryFiles && !hasObjCEntryFiles {
            return .swift
        }
        if objcFileCount > 0 && swiftFileCount == 0 {
            return .objc
        }
        if objcFileCount > swiftFileCount {
            return .objc
        }
        
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        if let content = try? String(contentsOf: pbxprojURL, encoding: .utf8) {
            if (content.contains("AppDelegate.m") || content.contains("ViewController.m") || content.contains("main.m")) &&
               !content.contains("AppDelegate.swift") {
                return .objc
            }
        }
        
        return .swift
    }
    
    public static func trackMainMIfNeeded(projectURL: URL, targetDir: URL, appName: String) throws {
        let mainMURL = targetDir.appendingPathComponent("main.m")
        try trackGeneratedFilesIfNeeded(
            projectURL: projectURL,
            targetDir: targetDir,
            appName: appName,
            generatedURLs: [mainMURL]
        )
    }
    
    public static func trackGeneratedFilesIfNeeded(
        projectURL: URL,
        targetDir: URL,
        appName: String,
        generatedURLs: [URL]
    ) throws {
        let projectPath = Path(projectURL.path)
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        let originalPbxprojText = (try? String(contentsOf: pbxprojURL, encoding: .utf8)) ?? ""
        let localPackageRefs = StoryboardStripper.extractLocalPackageReferences(from: originalPbxprojText)
        
        guard let xcodeProj = try? XcodeProj(path: projectPath) else { return }
        let pbxproj = xcodeProj.pbxproj
        let sourceRoot = Path(projectURL.deletingLastPathComponent().path)
        
        let target = pbxproj.nativeTargets.first { $0.name == appName } ?? pbxproj.nativeTargets.first
        
        // In Xcode 16+, projects using PBXFileSystemSynchronizedRootGroup automatically compile & bundle all files in the synchronized folder.
        let hasSynchronizedGroup = !(target?.fileSystemSynchronizedGroups ?? []).isEmpty ||
            originalPbxprojText.contains("PBXFileSystemSynchronizedRootGroup")
        if hasSynchronizedGroup {
            return
        }
        
        let targetGroup = pbxproj.groups.first { group in
            group.name == appName || group.path == appName || group.path == targetDir.lastPathComponent
        } ?? (try? pbxproj.rootGroup())
        
        guard let group = targetGroup else { return }
        
        var didModify = false
        for fileURL in generatedURLs {
            let filePath = Path(fileURL.path)
            guard filePath.exists else { continue }
            let fileName = fileURL.lastPathComponent
            let ext = fileURL.pathExtension.lowercased()
            
            let existingRef = pbxproj.fileReferences.first { ref in
                let candidate = ref.name ?? ref.path ?? ""
                return candidate == fileName || URL(fileURLWithPath: candidate).lastPathComponent == fileName
            }
            
            let fileRef: PBXFileReference
            if let existing = existingRef {
                fileRef = existing
            } else if let added = try? group.addFile(at: filePath, sourceRoot: sourceRoot) {
                fileRef = added
                didModify = true
            } else {
                continue
            }
            
            if ext == "swift" || ext == "m" || ext == "mm" {
                if let sourcesPhase = try? target?.sourcesBuildPhase() {
                    let alreadyInSources = sourcesPhase.files?.contains { $0.file?.uuid == fileRef.uuid } ?? false
                    if !alreadyInSources {
                        _ = try? sourcesPhase.add(file: fileRef)
                        didModify = true
                    }
                }
            } else if ext == "xib" {
                if let resourcesPhase = try? target?.resourcesBuildPhase() {
                    let alreadyInResources = resourcesPhase.files?.contains { $0.file?.uuid == fileRef.uuid } ?? false
                    if !alreadyInResources {
                        _ = try? resourcesPhase.add(file: fileRef)
                        didModify = true
                    }
                }
            }
        }
        
        if didModify {
            if let encodedData = try? pbxproj.dataRepresentation(),
               var encodedText = String(data: encodedData, encoding: .utf8) {
                encodedText = StoryboardStripper.restoreLocalPackageReferences(in: encodedText, references: localPackageRefs)
                encodedText = StoryboardStripper.stripStoryboardBuildSettingsFromText(encodedText)
                try Data(encodedText.utf8).write(to: pbxprojURL)
            } else {
                try xcodeProj.writePBXProj(path: projectPath, override: true, outputSettings: PBXOutputSettings())
            }
        }
    }
}

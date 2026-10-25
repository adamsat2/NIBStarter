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

struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Converts an existing iOS or macOS project to NIBStarter by stripping Storyboards and setting up programmatic bootstrapping."
    )
    
    @Option(name: .shortAndLong, help: "Path to the .xcodeproj file. Defaults to auto-detecting in the current directory.")
    var project: String?
    
    @Option(name: .long, help: "Platform for the project (ios or macos). Defaults to auto-detecting from project settings.")
    var platform: ProjectPlatform?
    
    @Option(name: .shortAndLong, help: "Language to use for scaffolding (swift or objc).")
    var language: ProjectLanguage = .swift
    
    @Flag(inversion: .prefixedNo, help: "Generate starter RootViewController and bootstrapping files.")
    var scaffold: Bool = true
    
    func run() throws {
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
        
        print("[NIBStarter] Converting project: \(projectURL.lastPathComponent)")
        
        // Detect platform if not passed explicitly
        let resolvedPlatform = platform ?? detectPlatform(at: projectURL)
        print("  Platform: \(resolvedPlatform.rawValue.uppercased()) | Language: \(language.rawValue)")
        
        // Strip Storyboards
        let stripper = StoryboardStripper(projectURL: projectURL)
        try stripper.strip()
        print("  ✓ Stripped Storyboard references and build settings from project file")
        print("  ✓ Cleaned Storyboard keys from Info.plist")
        print("  ✓ Removed physical Storyboard files from disk")
        
        // Scaffold starter files
        if scaffold {
            let appDirectory = projectURL.deletingLastPathComponent()
            let appName = projectURL.deletingPathExtension().lastPathComponent
            let targetSourceDir = appDirectory.appendingPathComponent(appName)
            let finalDir = fileManager.fileExists(atPath: targetSourceDir.path) ? targetSourceDir : appDirectory
            
            try CodeGenerator.generateStarterFiles(
                in: finalDir,
                appName: appName,
                platform: resolvedPlatform,
                language: language
            )
            
            if language == .objc && resolvedPlatform == .macos {
                try Self.trackMainMIfNeeded(projectURL: projectURL, targetDir: finalDir, appName: appName)
            }
            
            print("  ✓ Generated \(resolvedPlatform.rawValue.uppercased()) \(language == .swift ? "Swift" : "Objective-C") RootViewController & matching .xib")
            print("  ✓ Configured bootstrapping entry point")
        }
        
        print("\n[NIBStarter] Conversion complete! Open your project and press Cmd + R.")
    }
    
    static func trackMainMIfNeeded(projectURL: URL, targetDir: URL, appName: String) throws {
        let projectPath = Path(projectURL.path)
        let xcodeProj = try XcodeProj(path: projectPath)
        let pbxproj = xcodeProj.pbxproj
        let sourceRoot = Path(projectURL.deletingLastPathComponent().path)
        let mainMURL = targetDir.appendingPathComponent("main.m")
        let mainMPath = Path(mainMURL.path)
        
        guard mainMPath.exists else { return }
        
        let target = pbxproj.nativeTargets.first { $0.name == appName } ?? pbxproj.nativeTargets.first
        
        let hasSynchronizedGroup = target?.fileSystemSynchronizedGroups?.contains(where: { syncGroup in
            syncGroup.path == appName || syncGroup.path == targetDir.lastPathComponent
        }) ?? false
        
        if hasSynchronizedGroup {
            return
        }
        
        let existingRef = pbxproj.fileReferences.first { ref in
            (ref.name ?? ref.path) == "main.m"
        }
        
        let fileRef: PBXFileReference
        if let existing = existingRef {
            fileRef = existing
        } else {
            let targetGroup = pbxproj.groups.first { group in
                group.name == appName || group.path == appName
            } ?? (try? pbxproj.rootGroup())
            
            guard let group = targetGroup else { return }
            fileRef = try group.addFile(at: mainMPath, sourceRoot: sourceRoot)
        }
        
        if let target = target, let sourcesPhase = try target.sourcesBuildPhase() {
            _ = try sourcesPhase.add(file: fileRef)
        }
        
        try xcodeProj.write(path: projectPath)
    }
    
    private func detectPlatform(at url: URL) -> ProjectPlatform {
        guard let proj = try? XcodeProj(path: Path(url.path)),
              let target = proj.pbxproj.nativeTargets.first,
              let config = target.buildConfigurationList?.buildConfigurations.first,
              let sdk = config.buildSettings["SDKROOT"] as? String else {
            return .ios
        }
        return sdk.lowercased().contains("macos") ? .macos : .ios
    }
}

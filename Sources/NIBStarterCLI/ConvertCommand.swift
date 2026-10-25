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
            
            print("  ✓ Generated \(resolvedPlatform.rawValue.uppercased()) \(language == .swift ? "Swift" : "Objective-C") RootViewController & matching .xib")
            print("  ✓ Configured bootstrapping entry point")
        }
        
        print("\n[NIBStarter] Conversion complete! Open your project and press Cmd + R.")
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

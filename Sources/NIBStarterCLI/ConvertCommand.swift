//
//  ConvertCommand.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser

struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Converts an existing iOS project to NIBStarter by stripping Storyboards and setting up programmatic bootstrapping."
    )
    
    @Option(name: .shortAndLong, help: "Path to the .xcodeproj file. Defaults to auto-detecting in the current directory.")
    var project: String?
    
    @Flag(inversion: .prefixedNo, help: "Generate starter RootViewController (.swift & .xib) and updated SceneDelegate.")
    var scaffold: Bool = true
    
    func run() throws {
        let fileManager = FileManager.default
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        // Locate .xcodeproj
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
        
        // Strip Storyboards from PBXProj, Plists, and Disk
        let stripper = StoryboardStripper(projectURL: projectURL)
        try stripper.strip()
        print("  ✓ Stripped Main.storyboard references and build settings from project file")
        print("  ✓ Cleaned UIMainStoryboardFile & UISceneStoryboardFile from Info.plist")
        print("  ✓ Removed physical Main.storyboard files from disk")
        
        // Scaffold starter files
        if scaffold {
            let appDirectory = projectURL.deletingLastPathComponent()
            let appName = projectURL.deletingPathExtension().lastPathComponent
            let targetSourceDir = appDirectory.appendingPathComponent(appName)
            
            let finalDir = fileManager.fileExists(atPath: targetSourceDir.path) ? targetSourceDir : appDirectory
            try CodeGenerator.generateStarterFiles(in: finalDir, appName: appName)
            
            print("  ✓ Generated RootViewController.swift & RootViewController.xib")
            print("  ✓ Configured SceneDelegate.swift with NibStarter.bootstrap")
        }
        
        print("\n[NIBStarter] Conversion complete! Open your project and press Cmd + R.")
    }
}

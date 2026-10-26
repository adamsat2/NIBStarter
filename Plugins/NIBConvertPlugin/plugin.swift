//
//  plugin.swift
//  NIBConvertPlugin
//
//  Created by Adam Stern on 05/04/2026.
//

import PackagePlugin
import Foundation

@main
struct NIBConvertPlugin: CommandPlugin {
    
    func performCommand(context: PluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        
        var forwardedArgs: [String] = ["convert"]
        if let projectPath = extractor.extractOption(named: "project").last ?? extractor.extractOption(named: "p").last {
            forwardedArgs += ["--project", projectPath]
        }
        if let platform = extractor.extractOption(named: "platform").last {
            forwardedArgs += ["--platform", platform]
        }
        if let lang = extractor.extractOption(named: "language").last ?? extractor.extractOption(named: "l").last {
            forwardedArgs += ["--language", lang]
        }
        if extractor.extractFlag(named: "no-scaffold") > 0 {
            forwardedArgs.append("--no-scaffold")
        }
        
        let tool = try (try? context.tool(named: "nibstarter")) ?? context.tool(named: "NIBStarterCLI")
        let process = Process()
        process.executableURL = tool.url
        process.currentDirectoryURL = context.package.directoryURL
        process.arguments = forwardedArgs
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }
        
        if process.terminationStatus != 0 {
            Diagnostics.error("nibstarter convert failed with exit code \(process.terminationStatus)")
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBConvertPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        
        let fileManager = FileManager.default
        let rawDir = context.xcodeProject.directoryURL
        let projectDir = rawDir.pathExtension == "xcodeproj" ? rawDir.deletingLastPathComponent() : rawDir
        
        let xcodeProjPath: String
        if rawDir.pathExtension == "xcodeproj" {
            xcodeProjPath = rawDir.path
        } else {
            let contents = (try? fileManager.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil)) ?? []
            xcodeProjPath = contents.first(where: { $0.pathExtension == "xcodeproj" })?.path
                ?? projectDir.appendingPathComponent("\(context.xcodeProject.displayName).xcodeproj").path
        }
        
        var forwardedArgs: [String] = ["convert", "--project", xcodeProjPath]
        
        if let platform = extractor.extractOption(named: "platform").last {
            forwardedArgs += ["--platform", platform]
        }
        
        if let lang = extractor.extractOption(named: "language").last ?? extractor.extractOption(named: "l").last {
            forwardedArgs += ["--language", lang]
        } else {
            // Also check XcodeTarget inputFiles if available; ConvertCommand will additionally inspect the filesystem and pbxproj
            let hasObjCInTargets = context.xcodeProject.targets.contains { target in
                target.inputFiles.contains { file in
                    let ext = file.url.pathExtension.lowercased()
                    return ext == "m" || ext == "mm"
                }
            }
            if hasObjCInTargets {
                forwardedArgs += ["--language", "objc"]
            }
        }
        
        if extractor.extractFlag(named: "no-scaffold") > 0 {
            forwardedArgs.append("--no-scaffold")
        }
        
        let tool = try (try? context.tool(named: "nibstarter")) ?? context.tool(named: "NIBStarterCLI")
        
        let process = Process()
        process.executableURL = tool.url
        process.currentDirectoryURL = projectDir
        process.arguments = forwardedArgs
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }
        
        if process.terminationStatus != 0 {
            Diagnostics.error("nibstarter convert failed with exit code \(process.terminationStatus)")
        }
    }
}
#endif

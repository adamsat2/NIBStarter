//
//  plugin.swift
//  NIBStarter
//
//  Created by Adam Stern on 26/10/2026.
//

import Foundation
import PackagePlugin

@main
struct NIBConvertPlugin: CommandPlugin {
    
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        let remainingArgs = extractor.remainingArguments
        
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["convert"] + remainingArgs
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }
        
        guard process.terminationStatus == 0 else {
            throw NIBConvertPluginError.executionFailed(exitCode: process.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBConvertPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        var remainingArgs = extractor.remainingArguments
        
        // Auto-detect if target contains Objective-C files when --language is not passed
        if !remainingArgs.contains("--language") && !remainingArgs.contains("-l") {
            let hasObjC = context.xcodeProject.targets.contains { target in
                target.inputFiles.contains { file in
                    let ext = file.url.pathExtension.lowercased()
                    return ext == "m" || ext == "mm"
                }
            }
            if hasObjC {
                remainingArgs += ["--language", "objc"]
            }
        }
        
        let tool = try context.tool(named: "nibstarter")
        
        let fileManager = FileManager.default
        let projectDir = context.xcodeProject.directoryURL
        let contents = (try? fileManager.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil)) ?? []
        let xcodeProj = contents.first(where: { $0.pathExtension == "xcodeproj" })?.path
            ?? projectDir.appendingPathComponent("\(context.xcodeProject.displayName).xcodeproj").path
        
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["convert", "--project", xcodeProj] + remainingArgs
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        if !output.isEmpty {
            print(output)
        }
        
        guard process.terminationStatus == 0 else {
            throw NIBConvertPluginError.executionFailed(exitCode: process.terminationStatus, output: output)
        }
    }
}
#endif

enum NIBConvertPluginError: Error, CustomStringConvertible {
    case executionFailed(exitCode: Int32, output: String)
    
    var description: String {
        switch self {
        case .executionFailed(let code, let output):
            return "NIBStarter conversion failed (exit code \(code)): \(output)"
        }
    }
}

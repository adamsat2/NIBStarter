//
//  plugin.swift
//  NIBStarter
//
//  Created by Adam Stern on 26/10/2026.
//

import Foundation
import PackagePlugin

@main
struct NIBInstallTemplatesPlugin: CommandPlugin {
    
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        let remainingArgs = extractor.remainingArguments
        
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["install-templates"] + remainingArgs
        
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
            throw NIBInstallTemplatesPluginError.executionFailed(exitCode: process.terminationStatus, output: output)
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBInstallTemplatesPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        let remainingArgs = extractor.remainingArguments
        
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["install-templates"] + remainingArgs
        
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
            throw NIBInstallTemplatesPluginError.executionFailed(exitCode: process.terminationStatus, output: output)
        }
    }
}
#endif

enum NIBInstallTemplatesPluginError: Error, CustomStringConvertible {
    case executionFailed(exitCode: Int32, output: String)
    
    var description: String {
        switch self {
        case .executionFailed(let code, let output):
            return "NIBStarter template installation failed (exit code \(code)): \(output)"
        }
    }
}

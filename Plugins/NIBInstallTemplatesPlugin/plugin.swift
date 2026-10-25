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
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["install-templates"] + arguments
        
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
            throw NIBInstallTemplatesPluginError.executionFailed(exitCode: process.terminationStatus)
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBInstallTemplatesPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["install-templates"] + arguments
        
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
            throw NIBInstallTemplatesPluginError.executionFailed(exitCode: process.terminationStatus)
        }
    }
}
#endif

enum NIBInstallTemplatesPluginError: Error, CustomStringConvertible {
    case executionFailed(exitCode: Int32)
    
    var description: String {
        switch self {
        case .executionFailed(let code):
            return "NIBStarter template installation failed with exit code \(code)."
        }
    }
}

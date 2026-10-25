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
        let tool = try context.tool(named: "nibstarter")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["convert"] + arguments
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NIBConvertPluginError.executionFailed(exitCode: process.terminationStatus)
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBConvertPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "nibstarter")
        
        let fileManager = FileManager.default
        let projectDir = context.xcodeProject.directoryURL
        let contents = (try? fileManager.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil)) ?? []
        let xcodeProj = contents.first(where: { $0.pathExtension == "xcodeproj" })?.path
            ?? projectDir.appendingPathComponent("\(context.xcodeProject.displayName).xcodeproj").path
        
        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["convert", "--project", xcodeProj] + arguments
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NIBConvertPluginError.executionFailed(exitCode: process.terminationStatus)
        }
    }
}
#endif

enum NIBConvertPluginError: Error, CustomStringConvertible {
    case executionFailed(exitCode: Int32)
    
    var description: String {
        switch self {
        case .executionFailed(let code):
            return "NIBStarter conversion failed with exit code \(code)."
        }
    }
}

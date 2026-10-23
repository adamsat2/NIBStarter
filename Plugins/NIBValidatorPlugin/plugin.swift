//
//  plugin.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation
import PackagePlugin

@main
struct NIBValidatorPlugin: BuildToolPlugin {
    
    /// Entry point for Swift Package targets
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // Resolve the compiled CLI tool binary from dependencies
        let validatorTool = try context.tool(named: "nib-validator")
        
        // Scan the directory containing the target's source files
        let targetDirectory = target.directoryURL.path
        
        return [
            .prebuildCommand(
                displayName: "Validating NIB connections for \(target.name)",
                executable: validatorTool.url,
                arguments: [
                    "--path", targetDirectory,
                    "--strict"
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBValidatorPlugin: XcodeBuildToolPlugin {
    
    /// Entry point when invoked directly inside an `.xcodeproj` consumer app
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let validatorTool = try context.tool(named: "nib-validator")
        
        // In an Xcode project, scan the project root directory
        let projectDirectory = context.xcodeProject.directoryURL.path
        
        return [
            .prebuildCommand(
                displayName: "Validating NIB connections in \(context.xcodeProject.displayName)",
                executable: validatorTool.url,
                arguments: [
                    "--path", projectDirectory,
                    "--strict"
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL
            )
        ]
    }
}
#endif

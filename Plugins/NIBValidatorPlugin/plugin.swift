//
//  plugin.swift
//  NIBValidatorPlugin
//
//  Created by Adam Stern on 20/10/2026.
//

import PackagePlugin
import Foundation

@main
struct NIBValidatorPlugin: BuildToolPlugin {
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }
        
        let validatorTool = try (try? context.tool(named: "nib-validator")) ?? context.tool(named: "NIBValidator")
        let sourceDir = sourceTarget.directoryURL
        
        return [
            .buildCommand(
                displayName: "NIBStarter: Validating XIB Contracts for \(target.name)",
                executable: validatorTool.url,
                arguments: [sourceDir.path],
                inputFiles: sourceTarget.sourceFiles.map(\.url)
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBValidatorPlugin: XcodeBuildToolPlugin {
    
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let validatorTool = try (try? context.tool(named: "nib-validator")) ?? context.tool(named: "NIBValidator")
        let projectDir = context.xcodeProject.directoryURL
        
        let trackedFiles = target.inputFiles.map(\.url)
        
        return [
            .buildCommand(
                displayName: "NIBStarter: Validating XIB Contracts for \(target.displayName)",
                executable: validatorTool.url,
                arguments: [projectDir.path],
                inputFiles: trackedFiles
            )
        ]
    }
}
#endif

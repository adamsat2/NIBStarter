//
//  plugin.swift
//  NIBInstallTemplatesPlugin
//
//  Created by Adam Stern on 05/04/2026.
//

import PackagePlugin
import Foundation

@main
struct NIBInstallTemplatesPlugin: CommandPlugin {
    
    func performCommand(context: PluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        
        var forwardedArgs = ["install-templates"]
        if extractor.extractFlag(named: "uninstall") > 0 {
            forwardedArgs.append("--uninstall")
        }
        
        let tool = try (try? context.tool(named: "nibstarter")) ?? context.tool(named: "NIBStarterCLI")
        try runTool(tool.url, arguments: forwardedArgs)
    }
    
    private func runTool(_ url: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        
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
            Diagnostics.error("nibstarter install-templates failed with exit code \(process.terminationStatus)")
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBInstallTemplatesPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        
        var forwardedArgs = ["install-templates"]
        if extractor.extractFlag(named: "uninstall") > 0 {
            forwardedArgs.append("--uninstall")
        }
        
        let tool = try (try? context.tool(named: "nibstarter")) ?? context.tool(named: "NIBStarterCLI")
        try runTool(tool.url, arguments: forwardedArgs)
    }
}
#endif

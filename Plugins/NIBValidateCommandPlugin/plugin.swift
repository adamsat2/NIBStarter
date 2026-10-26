//
//  plugin.swift
//  NIBValidateCommandPlugin
//
//  Created by Adam Stern on 26/10/2026.
//

import PackagePlugin
import Foundation

@main
struct NIBValidateCommandPlugin: CommandPlugin {
    
    func performCommand(context: PluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        let isStrict = extractor.extractFlag(named: "strict") > 0
        
        let tool = try (try? context.tool(named: "nib-validator")) ?? context.tool(named: "NIBValidator")
        try runValidator(executableURL: tool.url, directoryURL: context.package.directoryURL, strict: isStrict)
    }
    
    private func runValidator(executableURL: URL, directoryURL: URL, strict: Bool) throws {
        let process = Process()
        process.executableURL = executableURL
        process.currentDirectoryURL = directoryURL
        var args = [directoryURL.path]
        if strict {
            args.append("--strict")
        }
        process.arguments = args
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if let outStr = String(data: outData, encoding: .utf8), !outStr.isEmpty {
            print(outStr)
        }
        
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        if let errStr = String(data: errData, encoding: .utf8), !errStr.isEmpty {
            for line in errStr.components(separatedBy: .newlines) where !line.isEmpty {
                Diagnostics.error(line)
            }
        }
        
        if process.terminationStatus != 0 {
            Diagnostics.error("NIBStarter XIB validation failed.")
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NIBValidateCommandPlugin: XcodeCommandPlugin {
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        _ = extractor.extractOption(named: "t")
        let isStrict = extractor.extractFlag(named: "strict") > 0
        
        let rawDir = context.xcodeProject.directoryURL
        let projectDir = rawDir.pathExtension == "xcodeproj" ? rawDir.deletingLastPathComponent() : rawDir
        
        let tool = try (try? context.tool(named: "nib-validator")) ?? context.tool(named: "NIBValidator")
        try runValidator(executableURL: tool.url, directoryURL: projectDir, strict: isStrict)
    }
}
#endif

//
//  main.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser
import XcodeProj

struct NIBStarterCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nibstarter",
        abstract: "A CLI tool to automate Storyboard stripping, programmatic setup, and Xcode template installation.",
        version: "1.0.0",
        subcommands: [
            // TODO: hook up Convert.self and InstallTemplates.self here
        ]
    )
}

// Entry point for the executable
NIBStarterCLI.main()

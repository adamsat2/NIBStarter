//
//  main.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser

struct NIBStarterCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nibstarter",
        abstract: "A CLI tool to automate Storyboard stripping, programmatic setup, and Xcode template installation.",
        version: "1.0.0",
        subcommands: [
            ConvertCommand.self,
        ],
        defaultSubcommand: ConvertCommand.self
    )
}

// Entry point for the executable
NIBStarterCLI.main()

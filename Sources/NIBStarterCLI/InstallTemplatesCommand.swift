//
//  InstallTemplatesCommand.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser

struct InstallTemplatesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install-templates",
        abstract: "Installs the NibInstantiable View Controller template into Xcode's File Templates library."
    )
    
    @Flag(name: .long, help: "Uninstall previously installed NIBStarter Xcode templates.")
    var uninstall: Bool = false
    
    func run() throws {
        if uninstall {
            try TemplateInstaller.uninstall()
            print("[NIBStarter] Successfully uninstalled NIBStarter Xcode templates.")
        } else {
            try TemplateInstaller.install()
            print("[NIBStarter] Template installed successfully!")
            print("  Location: ~/Library/Developer/Xcode/Templates/File Templates/NIBStarter")
            print("  Restart Xcode to see 'NibInstantiable View Controller' in File -> New File...")
        }
    }
}

//
//  main.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation
import NIBValidatorCore

print("=== NIBStarter Validator: XIB Scan ===")

// Determine target directory from CLI arguments or default to current directory
let arguments = CommandLine.arguments
let scanPath: String
if arguments.count > 1 {
    scanPath = arguments[1]
} else {
    // Default to the project root directory
    scanPath = FileManager.default.currentDirectoryPath
}

let rootURL = URL(fileURLWithPath: scanPath)
print("Scanning directory: \(rootURL.path)")

// Crawl for .xib files
let xibFiles = XIBCrawler.findXIBFiles(in: rootURL)
print("Found \(xibFiles.count) .xib file(s).\n")

// Parse each XIB file
for url in xibFiles {
    print("----------------------------------------")
    print("File: \(url.lastPathComponent)")
    
    let parser = XIBParser(fileURL: url)
    guard let model = parser.parse() else {
        print("  Notice: Skipped (No custom class assigned to File's Owner)")
        continue
    }
    
    print("  File's Owner Class: \(model.ownerClass)")
    print("  Has 'view' outlet:  \(model.hasViewOutlet ? "Yes" : "NO (Warning: Will crash at runtime)")")
    
    print("  Outlets (\(model.outlets.count)):")
    for outlet in model.outlets {
        print("    - Line \(outlet.lineNumber): @IBOutlet var \(outlet.propertyName)")
    }
    
    print("  Actions (\(model.actions.count)):")
    for action in model.actions {
        print("    - Line \(action.lineNumber): @IBAction func \(action.selectorName)")
    }
}

print("----------------------------------------")
print("Scan complete.")

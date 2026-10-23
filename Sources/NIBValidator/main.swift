//
//  main.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation
import NIBValidatorCore

let arguments = CommandLine.arguments

// Parse CLI flags
var scanPath: String?
var strictMode = false

var iterator = arguments.dropFirst().makeIterator()
while let arg = iterator.next() {
    switch arg {
    case "--strict":
        strictMode = true
    case "--path":
        scanPath = iterator.next()
    default:
        if scanPath == nil && !arg.hasPrefix("-") {
            scanPath = arg
        }
    }
}

let targetDirectory = scanPath ?? FileManager.default.currentDirectoryPath
let rootURL = URL(fileURLWithPath: targetDirectory)

print("[NIBStarter] Scanning project at: \(rootURL.path)")

// Crawl and parse all .xib files
let xibFiles = XIBCrawler.findXIBFiles(in: rootURL)
let xibModels = xibFiles.compactMap { url -> XIBModel? in
    let parser = XIBParser(fileURL: url)
    return parser.parse()
}

// Scan and parse all source files (.swift, .h, .m)
let codeLookup = SourceScanner.scanProject(at: rootURL)

// Validate connections
let issues = XIBValidator.validate(xibs: xibModels, against: codeLookup, strict: strictMode)

// Output diagnostics
var errorCount = 0
var warningCount = 0

for issue in issues {
    // Printing to stderr ensures Xcode's build engine intercepts compiler diagnostics immediately
    fputs("\(issue.xcodeFormattedMessage)\n", stderr)
    if issue.severity == .error {
        errorCount += 1
    } else {
        warningCount += 1
    }
}

if issues.isEmpty {
    print("[NIBStarter] Validation passed: \(xibModels.count) XIB file(s) verified with 0 issues.")
    exit(0)
} else {
    print("[NIBStarter] Validation completed with \(errorCount) error(s) and \(warningCount) warning(s).")
    // Return non-zero status code if errors exist to fail Xcode build phases
    exit(errorCount > 0 ? 1 : 0)
}

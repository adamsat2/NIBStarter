//
//  XIBCrawler.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public struct XIBCrawler {
    /// Folders that should never be searched.
    private static let ignoredDirectories: Set<String> = [
        ".git",
        ".build",
        "DerivedData",
        "Pods",
        "Carthage",
        ".swiftpm"
    ]
    
    /// Recursively scans a root directory URL and returns all `.xib` file URLs.
    public static func findXIBFiles(in rootURL: URL) -> [URL] {
        let fileManager = FileManager.default
        var xibURLs: [URL] = []
        
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            // Check if this directory is in the ignore list to skip traversing its children
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
               resourceValues.isDirectory == true {
                if ignoredDirectories.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                    continue
                }
            }
            
            if fileURL.pathExtension == "xib" {
                xibURLs.append(fileURL)
            }
        }
        
        return xibURLs
    }
}

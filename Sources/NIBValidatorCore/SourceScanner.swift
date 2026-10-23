//
//  SourceScanner.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public struct SourceScanner {
    
    private static let ignoredDirectories: Set<String> = [
        ".git", ".build", "DerivedData", "Pods", "Carthage", ".swiftpm"
    ]
    
    /// Scans a root directory and returns a lookup table of [ClassName: ClassCodeModel].
    public static func scanProject(at rootURL: URL) -> [String: ClassCodeModel] {
        var classTable: [String: ClassCodeModel] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }
        
        for case let fileURL as URL in enumerator {
            if let isDir = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDir == true {
                if ignoredDirectories.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                    continue
                }
            }
            
            let ext = fileURL.pathExtension.lowercased()
            guard ext == "swift" || ext == "h" || ext == "m" else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            
            let parsedModels: [ClassCodeModel]
            if ext == "swift" {
                parsedModels = SwiftSourceParser.parse(source: content, fileURL: fileURL)
            } else {
                parsedModels = ObjCSourceParser.parse(source: content, fileURL: fileURL)
            }
            
            for model in parsedModels {
                if var existing = classTable[model.className] {
                    existing.outlets.formUnion(model.outlets)
                    existing.actions.formUnion(model.actions)
                    existing.sourceFiles.formUnion(model.sourceFiles)
                    classTable[model.className] = existing
                } else {
                    classTable[model.className] = model
                }
            }
        }
        
        return classTable
    }
}

//
//  StoryboardStripper.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import PathKit
import XcodeProj

public struct StoryboardStripper {
    
    public let projectURL: URL
    
    public init(projectURL: URL) {
        self.projectURL = projectURL
    }
    
    public func strip() throws {
        // Target storyboard names across iOS (Main) and macOS (MainMenu, Main)
        let storyboardNames: Set<String> = ["Main.storyboard", "MainMenu.storyboard"]
        let defaultViewControllerNames: Set<String> = ["ViewController.swift", "ViewController.h", "ViewController.m"]
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        let originalPbxprojText = try? String(contentsOf: pbxprojURL, encoding: .utf8)
        let localPackageRefs = Self.extractLocalPackageReferences(from: originalPbxprojText ?? "")
        
        var targetFilePaths: [String] = []
        
        do {
            let path = Path(projectURL.path)
            let xcodeProj = try XcodeProj(path: path)
            let pbxproj = xcodeProj.pbxproj
            
            let fileRefs = pbxproj.fileReferences.filter { ref in
                Self.matchesStoryboard(name: ref.name, path: ref.path, storyboardNames: storyboardNames) ||
                Self.matchesDefaultViewController(name: ref.name, path: ref.path, names: defaultViewControllerNames)
            }
            
            let variantGroups = pbxproj.variantGroups.filter { vg in
                Self.matchesStoryboard(name: vg.name, path: vg.path, storyboardNames: storyboardNames) ||
                vg.children.contains { child in
                    Self.matchesStoryboard(name: child.name, path: child.path, storyboardNames: storyboardNames)
                }
            }
            
            let variantChildRefs = variantGroups.flatMap { $0.children }
            for ref in fileRefs + variantChildRefs {
                if let p = ref.path {
                    targetFilePaths.append(p)
                }
                if let n = ref.name {
                    targetFilePaths.append(n)
                }
            }
            
            let targetUUIDs = fileRefs.map { $0.uuid }
            let groupUUIDs = variantGroups.map { $0.uuid }
            let childUUIDs = variantChildRefs.map { $0.uuid }
            let allTargetUUIDs = Set(targetUUIDs).union(groupUUIDs).union(childUUIDs)
            
            for target in pbxproj.nativeTargets {
                if let resourcesPhase = try target.resourcesBuildPhase() {
                    let buildFilesToRemove = resourcesPhase.files?.filter { buildFile in
                        guard let fileRef = buildFile.file else { return false }
                        return allTargetUUIDs.contains(fileRef.uuid)
                    } ?? []
                    
                    for buildFile in buildFilesToRemove {
                        resourcesPhase.files?.removeAll { $0.uuid == buildFile.uuid }
                        pbxproj.delete(object: buildFile)
                    }
                }
                
                if let sourcesPhase = try target.sourcesBuildPhase() {
                    let sourceFilesToRemove = sourcesPhase.files?.filter { buildFile in
                        guard let fileRef = buildFile.file else { return false }
                        return allTargetUUIDs.contains(fileRef.uuid)
                    } ?? []
                    
                    for buildFile in sourceFilesToRemove {
                        sourcesPhase.files?.removeAll { $0.uuid == buildFile.uuid }
                        pbxproj.delete(object: buildFile)
                    }
                }
                
                // Strip both iOS and macOS build setting storyboard keys at target level
                if let configList = target.buildConfigurationList {
                    for config in configList.buildConfigurations {
                        Self.stripStoryboardKeys(from: &config.buildSettings)
                    }
                }
            }
            
            // Also strip build setting storyboard keys at project level
            for project in pbxproj.projects {
                if let configList = project.buildConfigurationList {
                    for config in configList.buildConfigurations {
                        Self.stripStoryboardKeys(from: &config.buildSettings)
                    }
                }
            }
            
            // Also strip across all XCBuildConfiguration objects in pbxproj
            for config in pbxproj.buildConfigurations {
                Self.stripStoryboardKeys(from: &config.buildSettings)
            }
            
            for group in pbxproj.groups {
                group.children.removeAll { allTargetUUIDs.contains($0.uuid) }
            }
            for ref in fileRefs {
                pbxproj.delete(object: ref)
            }
            for vg in variantGroups {
                for child in vg.children {
                    pbxproj.delete(object: child)
                }
                pbxproj.delete(object: vg)
            }
            
            if let encodedData = try pbxproj.dataRepresentation(),
               var encodedText = String(data: encodedData, encoding: .utf8) {
                encodedText = Self.restoreLocalPackageReferences(in: encodedText, references: localPackageRefs)
                encodedText = Self.stripStoryboardReferencesFromPbxprojText(encodedText)
                try Data(encodedText.utf8).write(to: pbxprojURL)
            } else {
                try xcodeProj.writePBXProj(path: path, override: true, outputSettings: PBXOutputSettings())
            }
        } catch {
            // Fallback text cleanup if XcodeProj fails on a future objectVersion
            if var fallbackText = originalPbxprojText {
                fallbackText = Self.stripStoryboardReferencesFromPbxprojText(fallbackText)
                try Data(fallbackText.utf8).write(to: pbxprojURL)
            } else {
                throw error
            }
        }
        
        let rootDir = projectURL.deletingLastPathComponent()
        cleanPhysicalInfoPlists(in: rootDir)
        deleteFilesFromDisk(in: rootDir, names: storyboardNames, extraRelativePaths: targetFilePaths)
    }
    
    /// Ensures `NIBValidatorPlugin` from `NIBStarter` is registered in the app target's
    /// `packageProductDependencies` (`Run Build Tool Plug-ins` phase) when `NIBStarter` is linked.
    public static func ensureValidatorBuildToolPlugin(in projectURL: URL, appName: String) {
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
        guard var text = try? String(contentsOf: pbxprojURL, encoding: .utf8) else { return }
        
        // If NIBValidatorPlugin is already wired up in XCSwiftPackageProductDependency, nothing to do
        if text.contains("productName = \"plugin:NIBValidatorPlugin\"") ||
           text.contains("productName = NIBValidatorPlugin") {
            return
        }
        
        // Find the existing NIBStarter or NIBStarterObjC package reference line inside XCSwiftPackageProductDependency
        guard let depStart = text.range(of: "/* Begin XCSwiftPackageProductDependency section */"),
              let depEnd = text.range(of: "/* End XCSwiftPackageProductDependency section */") else {
            return
        }
        
        let depSection = String(text[depStart.upperBound..<depEnd.lowerBound])
        var nibPackageLine: String?
        let depBlocks = depSection.components(separatedBy: "};")
        for block in depBlocks {
            if block.contains("productName = NIBStarter;") || block.contains("productName = NIBStarterObjC;") {
                for line in block.components(separatedBy: "\n") {
                    if line.trimmingCharacters(in: .whitespaces).hasPrefix("package = ") {
                        nibPackageLine = line
                        break
                    }
                }
            }
        }
        
        guard let packageLine = nibPackageLine else { return }
        
        // Generate a deterministic 24-hex UUID for the plugin dependency
        let pluginDepUUID = "4E494256414C494441544F52" // "NIBVALIDATOR" in ASCII hex
        let newDepBlock = """
        \t\t\(pluginDepUUID) /* NIBValidatorPlugin */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tisPlugin = 1;
        \(packageLine)
        \t\t\tproductName = "plugin:NIBValidatorPlugin";
        \t\t};
        """
        
        // Insert newDepBlock before /* End XCSwiftPackageProductDependency section */
        text.replaceSubrange(depEnd.lowerBound..<depEnd.lowerBound, with: newDepBlock + "\n")
        
        // Add the pluginDepUUID into the app target's packageProductDependencies = ( ... ); list
        if let targetStart = text.range(of: "/* Begin PBXNativeTarget section */"),
           let targetEnd = text.range(of: "/* End PBXNativeTarget section */") {
            var targetSection = String(text[targetStart.upperBound..<targetEnd.lowerBound])
            if let pkgDepsRange = targetSection.range(of: "packageProductDependencies = (\n") {
                let entry = "\t\t\t\t\(pluginDepUUID) /* NIBValidatorPlugin */,\n"
                targetSection.insert(contentsOf: entry, at: pkgDepsRange.upperBound)
                text.replaceSubrange(targetStart.upperBound..<targetEnd.lowerBound, with: targetSection)
                try? Data(text.utf8).write(to: pbxprojURL)
            }
        }
    }
    
    private static func stripStoryboardKeys(from buildSettings: inout BuildSettings) {
        let keys = [
            "INFOPLIST_KEY_UIMainStoryboardFile",
            "INFOPLIST_KEY_NSMainStoryboardFile",
            "INFOPLIST_KEY_NSMainNibFile",
            "INFOPLIST_KEY_UISceneStoryboardFile",
            "UIMainStoryboardFile",
            "NSMainStoryboardFile",
            "NSMainNibFile"
        ]
        for key in keys {
            buildSettings.removeValue(forKey: key)
        }
        // Also remove any build setting key with platform suffixes such as INFOPLIST_KEY_UIMainStoryboardFile[sdk=...]
        let dynamicKeys = buildSettings.keys.filter { key in
            key.hasPrefix("INFOPLIST_KEY_UIMainStoryboardFile") ||
            key.hasPrefix("INFOPLIST_KEY_NSMainStoryboardFile") ||
            key.hasPrefix("INFOPLIST_KEY_NSMainNibFile") ||
            key.hasPrefix("INFOPLIST_KEY_UISceneStoryboardFile")
        }
        for key in dynamicKeys {
            buildSettings.removeValue(forKey: key)
        }
    }
    
    private static func matchesStoryboard(name: String?, path: String?, storyboardNames: Set<String>) -> Bool {
        let lowercasedTargets = Set(storyboardNames.map { $0.lowercased() })
        for candidate in [name, path].compactMap({ $0 }) {
            if lowercasedTargets.contains(candidate.lowercased()) {
                return true
            }
            let lastComponent = URL(fileURLWithPath: candidate).lastPathComponent.lowercased()
            if lowercasedTargets.contains(lastComponent) {
                return true
            }
        }
        return false
    }
    
    private static func matchesDefaultViewController(name: String?, path: String?, names: Set<String>) -> Bool {
        for candidate in [name, path].compactMap({ $0 }) {
            let lastComponent = URL(fileURLWithPath: candidate).lastPathComponent
            if names.contains(lastComponent) {
                return true
            }
        }
        return false
    }
    
    static func stripStoryboardBuildSettingsFromText(_ text: String) -> String {
        return stripStoryboardReferencesFromPbxprojText(text)
    }
    
    static func stripStoryboardReferencesFromPbxprojText(_ text: String) -> String {
        let keysToStrip = [
            "INFOPLIST_KEY_UIMainStoryboardFile",
            "INFOPLIST_KEY_NSMainStoryboardFile",
            "INFOPLIST_KEY_NSMainNibFile",
            "INFOPLIST_KEY_UISceneStoryboardFile"
        ]
        let lines = text.components(separatedBy: "\n")
        let filtered = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            for key in keysToStrip {
                if trimmed.hasPrefix(key) || trimmed.hasPrefix("\"\(key)") {
                    return false
                }
            }
            // Strip any remaining single-line PBXBuildFile / PBXFileReference / group children lines for Main.storyboard or MainMenu.storyboard
            if (trimmed.contains("Main.storyboard") || trimmed.contains("MainMenu.storyboard")) &&
               !trimmed.contains("LaunchScreen.storyboard") {
                if trimmed.contains("isa = PBXBuildFile;") ||
                   trimmed.contains("isa = PBXFileReference;") ||
                   trimmed.hasPrefix("/* Main.storyboard */") ||
                   trimmed.hasPrefix("/* MainMenu.storyboard */") ||
                   trimmed.hasSuffix("/* Main.storyboard */,") ||
                   trimmed.hasSuffix("/* MainMenu.storyboard */,") ||
                   trimmed.hasSuffix("/* Main.storyboard in Resources */,") ||
                   trimmed.hasSuffix("/* MainMenu.storyboard in Resources */,") {
                    return false
                }
            }
            return true
        }
        return filtered.joined(separator: "\n")
    }
    
    /// Preserves `package = <UUID> /* XCLocalSwiftPackageReference ... */;` inside `XCSwiftPackageProductDependency`
    /// blocks, which `XcodeProj` otherwise drops when re-encoding local Swift package dependencies.
    static func extractLocalPackageReferences(from pbxprojText: String) -> [String: String] {
        var result: [String: String] = [:]
        guard let sectionStart = pbxprojText.range(of: "/* Begin XCSwiftPackageProductDependency section */"),
              let sectionEnd = pbxprojText.range(of: "/* End XCSwiftPackageProductDependency section */") else {
            return result
        }
        let section = String(pbxprojText[sectionStart.upperBound..<sectionEnd.lowerBound])
        let lines = section.components(separatedBy: "\n")
        var currentBlockHeader: String?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix("= {") {
                currentBlockHeader = trimmed
            } else if trimmed == "};" {
                currentBlockHeader = nil
            } else if let header = currentBlockHeader, trimmed.hasPrefix("package = ") {
                result[header] = line
            }
        }
        return result
    }
    
    static func restoreLocalPackageReferences(in pbxprojText: String, references: [String: String]) -> String {
        guard !references.isEmpty,
              let sectionStart = pbxprojText.range(of: "/* Begin XCSwiftPackageProductDependency section */"),
              let sectionEnd = pbxprojText.range(of: "/* End XCSwiftPackageProductDependency section */") else {
            return pbxprojText
        }
        let prefix = String(pbxprojText[..<sectionStart.upperBound])
        let suffix = String(pbxprojText[sectionEnd.lowerBound...])
        let section = String(pbxprojText[sectionStart.upperBound..<sectionEnd.lowerBound])
        
        var updatedLines: [String] = []
        var currentHeader: String?
        var currentBlockHasPackage = false
        
        for line in section.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix("= {") {
                currentHeader = trimmed
                currentBlockHasPackage = false
                updatedLines.append(line)
            } else if trimmed == "};" {
                if let header = currentHeader, !currentBlockHasPackage, let packageLine = references[header] {
                    updatedLines.append(packageLine)
                }
                currentHeader = nil
                currentBlockHasPackage = false
                updatedLines.append(line)
            } else {
                if trimmed.hasPrefix("package = ") {
                    currentBlockHasPackage = true
                }
                updatedLines.append(line)
            }
        }
        
        return prefix + updatedLines.joined(separator: "\n") + suffix
    }
    
    private func cleanPhysicalInfoPlists(in rootURL: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") || name == "DerivedData" {
                enumerator.skipDescendants()
                continue
            }
            guard name.hasSuffix(".plist") else { continue }
            guard let data = try? Data(contentsOf: url),
                  var plistDict = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else {
                continue
            }
            
            var modified = false
            
            // Remove iOS and macOS storyboard keys
            if plistDict.removeValue(forKey: "UIMainStoryboardFile") != nil { modified = true }
            if plistDict.removeValue(forKey: "NSMainStoryboardFile") != nil { modified = true }
            if plistDict.removeValue(forKey: "NSMainNibFile") != nil { modified = true }
            
            // Clean Scene Configurations (iOS)
            if var sceneManifest = plistDict["UIApplicationSceneManifest"] as? [String: Any],
               var sceneConfigs = sceneManifest["UISceneConfigurations"] as? [String: Any],
               var appConfigs = sceneConfigs["UIWindowSceneSessionRoleApplication"] as? [[String: Any]] {
                
                for i in 0..<appConfigs.count {
                    if appConfigs[i].removeValue(forKey: "UISceneStoryboardFile") != nil {
                        modified = true
                    }
                }
                
                sceneConfigs["UIWindowSceneSessionRoleApplication"] = appConfigs
                sceneManifest["UISceneConfigurations"] = sceneConfigs
                plistDict["UIApplicationSceneManifest"] = sceneManifest
            }
            
            if modified, let updatedData = try? PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0) {
                try? updatedData.write(to: url)
            }
        }
    }
    
    private func deleteFilesFromDisk(in rootURL: URL, names: Set<String>, extraRelativePaths: [String] = []) {
        let fileManager = FileManager.default
        let lowercasedNames = Set(names.map { $0.lowercased() })
        var toDelete: Set<URL> = []
        
        // Check explicit relative paths recorded from pbxproj first (only for storyboards)
        for relPath in extraRelativePaths {
            let lastComp = URL(fileURLWithPath: relPath).lastPathComponent.lowercased()
            guard lowercasedNames.contains(lastComp) else { continue }
            let directURL = rootURL.appendingPathComponent(relPath).standardizedFileURL
            if fileManager.fileExists(atPath: directURL.path) {
                toDelete.insert(directURL)
            }
        }
        
        // Also enumerate all subdirectories of rootURL
        if let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                let name = url.lastPathComponent
                if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") || name == "DerivedData" {
                    enumerator.skipDescendants()
                    continue
                }
                if lowercasedNames.contains(name.lowercased()) {
                    toDelete.insert(url.standardizedFileURL)
                }
            }
        }
        
        for url in toDelete {
            let parentDir = url.deletingLastPathComponent()
            try? fileManager.removeItem(at: url)
            // If parent .lproj folder is now empty, remove it as well
            if parentDir.pathExtension == "lproj",
               let remaining = try? fileManager.contentsOfDirectory(atPath: parentDir.path),
               remaining.filter({ !$0.hasPrefix(".") }).isEmpty {
                try? fileManager.removeItem(at: parentDir)
            }
        }
    }
}

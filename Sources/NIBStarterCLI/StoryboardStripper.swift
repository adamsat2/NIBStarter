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
        let path = Path(projectURL.path)
        let xcodeProj = try XcodeProj(path: path)
        let pbxproj = xcodeProj.pbxproj
        
        var filesToDeleteFromDisk: [String] = []
        
        // Identify File References and Variant Groups named "Main.storyboard"
        let fileRefs = pbxproj.fileReferences.filter { $0.name == "Main.storyboard" || $0.path == "Main.storyboard" }
        let variantGroups = pbxproj.variantGroups.filter { $0.name == "Main.storyboard" }
        
        let allTargetUUIDs = Set(fileRefs.map(\.uuid) + variantGroups.map(\.uuid))
        
        // Collect disk paths before removing references
        for ref in fileRefs {
            if let p = ref.path { filesToDeleteFromDisk.append(p) }
        }
        for vg in variantGroups {
            for child in vg.children {
                if let p = child.path { filesToDeleteFromDisk.append(p) }
            }
        }
        
        // Remove from PBXResourcesBuildPhase across all native targets
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
            
            // Remove modern Build Settings storyboard keys (Xcode 13+)
            if let configList = target.buildConfigurationList {
                for config in configList.buildConfigurations {
                    config.buildSettings.removeValue(forKey: "INFOPLIST_KEY_UIMainStoryboardFile")
                }
            }
        }
        
        // Remove from PBXGroups and delete objects from project
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
        
        // Write back updated PBXProj
        try xcodeProj.write(path: path)
        
        // Clean Physical Info.plist files on disk
        cleanPhysicalInfoPlists(in: projectURL.deletingLastPathComponent())
        
        // Delete physical Main.storyboard files on disk
        deleteFilesFromDisk(in: projectURL.deletingLastPathComponent())
    }
    
    private func cleanPhysicalInfoPlists(in rootURL: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return }
        
        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasSuffix(".plist") else { continue }
            guard var plistDict = try? PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any] else { continue }
            
            var modified = false
            
            // Remove UIMainStoryboardFile
            if plistDict.removeValue(forKey: "UIMainStoryboardFile") != nil {
                modified = true
            }
            
            // Clean UIApplicationSceneManifest -> UISceneConfigurations -> UIWindowSceneSessionRoleApplication
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
    
    private func deleteFilesFromDisk(in rootURL: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return }
        
        var toDelete: [URL] = []
        for case let url as URL in enumerator {
            if url.lastPathComponent == "Main.storyboard" {
                toDelete.append(url)
            }
        }
        
        for url in toDelete {
            try? fileManager.removeItem(at: url)
        }
    }
}

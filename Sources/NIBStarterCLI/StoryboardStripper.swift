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
        
        // Target storyboard names across iOS (Main) and macOS (MainMenu, Main)
        let storyboardNames: Set<String> = ["Main.storyboard", "MainMenu.storyboard"]
        
        let fileRefs = pbxproj.fileReferences.filter { ref in
            guard let name = ref.name ?? ref.path else { return false }
            return storyboardNames.contains(name)
        }
        
        let variantGroups = pbxproj.variantGroups.filter { vg in
            guard let name = vg.name ?? vg.path else { return false }
            return storyboardNames.contains(name)
        }
        
        let targetUUIDs = fileRefs.map { $0.uuid }
        let groupUUIDs = variantGroups.map { $0.uuid }
        let allTargetUUIDs = Set(targetUUIDs).union(groupUUIDs)
        
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
            
            // Strip both iOS and macOS build setting storyboard keys
            if let configList = target.buildConfigurationList {
                for config in configList.buildConfigurations {
                    config.buildSettings.removeValue(forKey: "INFOPLIST_KEY_UIMainStoryboardFile")
                    config.buildSettings.removeValue(forKey: "INFOPLIST_KEY_NSMainStoryboardFile")
                }
            }
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
        
        try xcodeProj.write(path: path)
        
        cleanPhysicalInfoPlists(in: projectURL.deletingLastPathComponent())
        deleteFilesFromDisk(in: projectURL.deletingLastPathComponent(), names: storyboardNames)
    }
    
    private func cleanPhysicalInfoPlists(in rootURL: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return }
        
        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasSuffix(".plist") else { continue }
            guard var plistDict = try? PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any] else { continue }
            
            var modified = false
            
            // Remove iOS and macOS storyboard keys
            if plistDict.removeValue(forKey: "UIMainStoryboardFile") != nil { modified = true }
            if plistDict.removeValue(forKey: "NSMainStoryboardFile") != nil { modified = true }
            
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
    
    private func deleteFilesFromDisk(in rootURL: URL, names: Set<String>) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return }
        
        var toDelete: [URL] = []
        for case let url as URL in enumerator {
            if names.contains(url.lastPathComponent) {
                toDelete.append(url)
            }
        }
        for url in toDelete {
            try? fileManager.removeItem(at: url)
        }
    }
}

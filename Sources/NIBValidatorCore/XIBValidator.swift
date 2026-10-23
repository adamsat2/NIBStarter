//
//  XIBValidator.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public struct XIBValidator {
    
    /// Cross-references a list of parsed XIB models against the project's source code lookup table.
    ///
    /// - Parameters:
    ///   - xibs: All parsed `XIBModel` instances from the project.
    ///   - codeLookup: A map of `[ClassName: ClassCodeModel]` from `SourceScanner`.
    ///   - strict: If `true`, missing controller classes emit errors; if `false`, warnings.
    /// - Returns: A list of `ValidationIssue` items.
    public static func validate(
        xibs: [XIBModel],
        against codeLookup: [String: ClassCodeModel],
        strict: Bool = true
    ) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        for xib in xibs {
            let xibPath = xib.fileURL.path
            
            // Mandatory View Outlet Check
            if !xib.hasViewOutlet {
                issues.append(ValidationIssue(
                    filePath: xibPath,
                    line: 1,
                    severity: .error,
                    message: "File's Owner '\(xib.ownerClass)' has no root 'view' outlet connected. This will crash at runtime."
                ))
            }
            
            // Class Existence Check
            guard let codeModel = codeLookup[xib.ownerClass] else {
                // If the class is defined in an external framework or SDK, we warn rather than fail
                // unless strict mode is enabled.
                let severity: IssueSeverity = strict ? .warning : .warning
                issues.append(ValidationIssue(
                    filePath: xibPath,
                    line: 1,
                    severity: severity,
                    message: "Custom class '\(xib.ownerClass)' assigned to File's Owner was not found in scanned source files."
                ))
                continue
            }
            
            // Outlet Cross-Reference Check
            for outlet in xib.outlets {
                // 'view' is an inherited property from UIViewController/NSViewController, so skip checking user class
                if outlet.propertyName == "view" {
                    continue
                }
                
                if !codeModel.outlets.contains(outlet.propertyName) {
                    issues.append(ValidationIssue(
                        filePath: xibPath,
                        line: outlet.lineNumber,
                        severity: .error,
                        message: "Orphaned outlet '\(outlet.propertyName)' connected to '\(xib.ownerClass)', but no matching @IBOutlet was found in code. This will cause NSUnknownKeyException at runtime."
                    ))
                }
            }
            
            // Action Cross-Reference Check
            for action in xib.actions {
                // Clean the selector name for resilient matching:
                // e.g. "didTapSubmit:" -> "didTapSubmit"
                let cleanSelector = action.selectorName.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                
                let matchesSelector = codeModel.actions.contains(action.selectorName) ||
                                      codeModel.actions.contains(cleanSelector)
                
                if !matchesSelector {
                    issues.append(ValidationIssue(
                        filePath: xibPath,
                        line: action.lineNumber,
                        severity: .error,
                        message: "Orphaned action '\(action.selectorName)' targeted at '\(xib.ownerClass)', but no matching @IBAction was found in code."
                    ))
                }
            }
        }
        
        return issues
    }
}

//
//  Untitled.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation
import SwiftSyntax
import SwiftParser

public final class SwiftSourceParser {
    
    /// Parses a Swift source string and returns all classes/extensions found with their @IBOutlets and @IBActions.
    public static func parse(source: String, fileURL: URL) -> [ClassCodeModel] {
        let sourceFile = Parser.parse(source: source)
        let visitor = ClassVisitor(fileURL: fileURL)
        visitor.walk(sourceFile)
        return visitor.classes
    }
}

// MARK: - Syntax Visitor

private final class ClassVisitor: SyntaxVisitor {
    let fileURL: URL
    var classes: [ClassCodeModel] = []
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(viewMode: .sourceAccurate)
    }
    
    // Visit class declarations: `class ProfileViewController: UIViewController { ... }`
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        let members = extractMembers(from: node.memberBlock.members)
        classes.append(ClassCodeModel(
            className: className,
            outlets: members.outlets,
            actions: members.actions,
            sourceFiles: [fileURL]
        ))
        return .visitChildren
    }
    
    // Visit extensions: `extension ProfileViewController { ... }`
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.extendedType.trimmedDescription
        let members = extractMembers(from: node.memberBlock.members)
        classes.append(ClassCodeModel(
            className: className,
            outlets: members.outlets,
            actions: members.actions,
            sourceFiles: [fileURL]
        ))
        return .visitChildren
    }
    
    private func extractMembers(from members: MemberBlockItemListSyntax) -> (outlets: Set<String>, actions: Set<String>) {
        var outlets: Set<String> = []
        var actions: Set<String> = []
        
        for member in members {
            // Check variable declarations for @IBOutlet
            if let varDecl = member.decl.as(VariableDeclSyntax.self), hasAttribute("IBOutlet", in: varDecl.attributes) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        outlets.insert(identifier.identifier.text)
                    }
                }
            }
            
            // Check function declarations for @IBAction
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self), hasAttribute("IBAction", in: funcDecl.attributes) {
                let baseName = funcDecl.name.text
                let paramCount = funcDecl.signature.parameterClause.parameters.count
                
                // Normalization: In Interface Builder XIBs, action selectors appear as:
                // "tapButton:" (1 param), "tapButton:forEvent:" (2 params), or "tapButton" (0 params).
                if paramCount == 0 {
                    actions.insert(baseName)
                    actions.insert("\(baseName)()")
                } else if paramCount == 1 {
                    actions.insert("\(baseName):")
                    actions.insert(baseName) // Also keep base name for resilient matching
                } else {
                    actions.insert("\(baseName):")
                    actions.insert(baseName)
                }
            }
        }
        
        return (outlets, actions)
    }
    
    private func hasAttribute(_ name: String, in attributes: AttributeListSyntax) -> Bool {
        return attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self) else { return false }
            return attr.attributeName.trimmedDescription == name
        }
    }
}

//
//  XIBParser.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public final class XIBParser: NSObject, XMLParserDelegate {
    
    private let fileURL: URL?
    private let xmlData: Data?
    private var parser: XMLParser?
    
    // State tracked during XML traversal
    private var ownerClass: String?
    private var ownerID: String = "-1" // Apple's standard default ID for File's Owner
    private var isInsideFilesOwner = false
    
    private var outlets: [XIBOutlet] = []
    private var actions: [XIBAction] = []
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.xmlData = nil
        super.init()
    }
    
    /// Initializes the parser directly with in-memory XML data (for testing).
    public init(xmlData: Data, virtualURL: URL = URL(fileURLWithPath: "/virtual/Test.xib")) {
        self.fileURL = virtualURL
        self.xmlData = xmlData
        super.init()
    }

    /// Parses the file and returns a structured `XIBModel`, or `nil` if not a valid/controller XIB.
    public func parse() -> XIBModel? {
        let data: Data
        if let xmlData = self.xmlData {
            data = xmlData
        } else if let fileURL = self.fileURL, let fileData = try? Data(contentsOf: fileURL) {
            data = fileData
        } else {
            return nil
        }
        
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        self.parser = xmlParser
        
        guard xmlParser.parse() else { return nil }
        
        guard let customClass = ownerClass, !customClass.isEmpty else {
            return nil
        }
        
        return XIBModel(
            fileURL: fileURL ?? URL(fileURLWithPath: "/virtual/Test.xib"),
            ownerClass: customClass,
            ownerID: ownerID,
            outlets: outlets,
            actions: actions
        )
    }
    
    // MARK: - XMLParserDelegate
    
    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let currentLine = parser.lineNumber
        
        // Identify File's Owner
        if elementName == "placeholder" {
            let isFilesOwner = attributeDict["placeholderIdentifier"] == "IBFilesOwner" ||
                               attributeDict["userLabel"] == "File's Owner"
            if isFilesOwner {
                isInsideFilesOwner = true
                if let customClass = attributeDict["customClass"] {
                    self.ownerClass = customClass
                }
                if let id = attributeDict["id"] {
                    self.ownerID = id
                }
            }
        }
        
        // Extract Outlets belonging to File's Owner
        if elementName == "outlet" && isInsideFilesOwner {
            if let property = attributeDict["property"] {
                let dest = attributeDict["destination"] ?? ""
                outlets.append(XIBOutlet(propertyName: property, destinationID: dest, lineNumber: currentLine))
            }
        }
        
        // Extract Actions targeting File's Owner
        if elementName == "action" {
            let destination = attributeDict["destination"] ?? ""
            // An action targets File's Owner if its destination matches the owner's ID (typically "-1")
            if destination == ownerID || destination == "-1" {
                if let selector = attributeDict["selector"] {
                    actions.append(XIBAction(selectorName: selector, destinationID: destination, lineNumber: currentLine))
                }
            }
        }
    }
    
    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "placeholder" && isInsideFilesOwner {
            isInsideFilesOwner = false
        }
    }
}

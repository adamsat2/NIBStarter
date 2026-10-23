//
//  XIBParserTests.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import XCTest
@testable import NIBValidatorCore

final class XIBParserTests: XCTestCase {
    
    // Sample raw XIB XML matching Xcode's format
    private let sampleXibXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0" toolsVersion="22000" targetRuntime="iOS.CocoaTouch">
        <objects>
            <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner" customClass="ProfileViewController" customModule="TestApp">
                <connections>
                    <outlet property="view" destination="i5M-Pr-FkT" id="sfx-zR-JGt"/>
                    <outlet property="nameLabel" destination="abc-123" id="out-1"/>
                    <outlet property="avatarImageView" destination="def-456" id="out-2"/>
                </connections>
            </placeholder>
            <view contentMode="scaleToFill" id="i5M-Pr-FkT">
                <subviews>
                    <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" id="btn-1">
                        <connections>
                            <action selector="didTapSaveButton:" destination="-1" eventType="touchUpInside" id="act-1"/>
                        </connections>
                    </button>
                </subviews>
            </view>
        </objects>
    </document>
    """
    
    func testXIBParserExtractsOwnerAndConnections() throws {
        let data = try XCTUnwrap(sampleXibXML.data(using: .utf8))
        let parser = XIBParser(xmlData: data)
        let model = try XCTUnwrap(parser.parse())
        
        // Verify Owner Class
        XCTAssertEqual(model.ownerClass, "ProfileViewController")
        
        // Verify View Outlet
        XCTAssertTrue(model.hasViewOutlet)
        
        // Verify Outlets
        let outletNames = model.outlets.map(\.propertyName)
        XCTAssertEqual(outletNames, ["view", "nameLabel", "avatarImageView"])
        
        // Verify Actions
        let actionNames = model.actions.map(\.selectorName)
        XCTAssertEqual(actionNames, ["didTapSaveButton:"])
    }
    
    func testXIBParserDetectsMissingViewOutlet() throws {
        let missingViewXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0">
            <objects>
                <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner" customClass="BrokenViewController">
                    <connections>
                        <outlet property="titleLabel" destination="123" id="out-1"/>
                    </connections>
                </placeholder>
            </objects>
        </document>
        """
        
        let data = try XCTUnwrap(missingViewXML.data(using: .utf8))
        let parser = XIBParser(xmlData: data)
        let model = try XCTUnwrap(parser.parse())
        
        XCTAssertEqual(model.ownerClass, "BrokenViewController")
        XCTAssertFalse(model.hasViewOutlet, "Should flag missing view outlet connection")
    }
}

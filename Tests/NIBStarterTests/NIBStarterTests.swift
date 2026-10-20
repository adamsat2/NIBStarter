//
//  NIBStarterTests.swift
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//


import XCTest
@testable import NIBStarter

#if canImport(UIKit)
import UIKit

// A mock controller to test protocol conformance
final class TestViewController: UIViewController, NibInstantiable {}

final class NIBStarterTests: XCTestCase {
    
    @MainActor
    func testNibNameResolution() {
        // Confirms that the static nibName string matches the class name exactly
        XCTAssertEqual(TestViewController.nibName, "TestViewController")
    }
    
    @MainActor
    func testBundleResolution() {
        // Confirms that the bundle points to the test bundle holding this class
        let expectedBundle = Bundle(for: TestViewController.self)
        XCTAssertEqual(TestViewController.bundle, expectedBundle)
    }
    
    @MainActor
    func testLegacyBootstrapperSetsRootController() {
        var window: UIWindow?
        let root = UIViewController()
        
        NibStarter.bootstrapLegacy(window: &window, root: root)
        
        XCTAssertNotNil(window)
        XCTAssertEqual(window?.rootViewController, root)
        XCTAssertFalse(window?.isHidden ?? true)
    }
}
#endif

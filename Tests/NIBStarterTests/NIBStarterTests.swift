//
//  NIBStarterTests.swift
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

import XCTest
@testable import NIBStarter
@testable import NIBStarterObjC

// MARK: - iOS / UIKit Tests
#if canImport(UIKit)
import UIKit

@MainActor
final class MockProfileViewController: UIViewController, NibInstantiable {}

@MainActor
final class CustomNamedViewController: UIViewController, NibInstantiable {
    static var nibName: String {
        return "CustomProfileView"
    }
}

final class NIBStarterUIKitTests: XCTestCase {
    
    @MainActor
    func testNibNameResolution() {
        XCTAssertEqual(MockProfileViewController.nibName, "MockProfileViewController")
    }
    
    @MainActor
    func testCustomNibNameOverride() {
        XCTAssertEqual(CustomNamedViewController.nibName, "CustomProfileView")
    }
    
    @MainActor
    func testBundleResolution() {
        let expectedBundle = Bundle(for: MockProfileViewController.self)
        XCTAssertEqual(MockProfileViewController.bundle, expectedBundle)
    }
    
    @MainActor
    func testSwiftInstantiationBindsNibAndBundle() {
        let controller = MockProfileViewController.instantiateFromNib()
        XCTAssertEqual(controller.nibName, "MockProfileViewController")
        XCTAssertEqual(controller.nibBundle, Bundle(for: MockProfileViewController.self))
    }
    
    @MainActor
    func testCustomSwiftInstantiationBindsCustomNib() {
        let controller = CustomNamedViewController.instantiateFromNib()
        XCTAssertEqual(controller.nibName, "CustomProfileView")
    }
    
    @MainActor
    func testObjectiveCCategoryInstantiation() {
        let controller = MockProfileViewController.nib_instantiate()
        XCTAssertEqual(controller.nibName, "MockProfileViewController")
        XCTAssertEqual(controller.nibBundle, Bundle(for: MockProfileViewController.self))
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

// MARK: - macOS / AppKit Tests
#if canImport(AppKit)
import AppKit

@MainActor
final class MockMacViewController: NSViewController, NibInstantiable {}

@MainActor
final class CustomMacViewController: NSViewController, NibInstantiable {
    static var nibName: String {
        return "CustomMacView"
    }
}

final class NIBStarterAppKitTests: XCTestCase {
    
    @MainActor
    func testMacNibNameResolution() {
        XCTAssertEqual(MockMacViewController.nibName, "MockMacViewController")
    }
    
    @MainActor
    func testMacCustomNibNameOverride() {
        XCTAssertEqual(CustomMacViewController.nibName, "CustomMacView")
    }
    
    @MainActor
    func testMacInstantiationBindsNibAndBundle() {
        let controller = MockMacViewController.instantiateFromNib()
        XCTAssertEqual(controller.nibName, "MockMacViewController")
        XCTAssertEqual(controller.nibBundle, Bundle(for: MockMacViewController.self))
    }
    
    @MainActor
    func testMacObjectiveCCategoryInstantiation() {
        let controller = MockMacViewController.nib_instantiate()
        XCTAssertEqual(controller.nibName, "MockMacViewController")
        XCTAssertEqual(controller.nibBundle, Bundle(for: MockMacViewController.self))
    }
    
    @MainActor
    func testAppKitBootstrapper() {
        let root = NSViewController()
        let windowController = NibStarter.bootstrapAppKit(root: root, title: "NIBStarterMac")
        
        XCTAssertNotNil(windowController.window)
        XCTAssertEqual(windowController.window?.title, "NIBStarterMac")
        XCTAssertEqual(windowController.window?.contentViewController, root)
    }
}
#endif

//
//  NibInstantiable.swift
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias PlatformViewController = NSViewController
#endif

/// A protocol enabling any UIViewController or NSViewController
/// to instantiate itself from a matching XIB/NIB file without hardcoded strings.
@MainActor
public protocol NibInstantiable: AnyObject {
    /// The filename of the NIB without the `.xib` or `.nib` extension.
    static var nibName: String { get }
    
    /// The bundle containing the NIB file.
    static var bundle: Bundle { get }
    
    /// Instantiates and returns an instance of the controller hooked up to its NIB.
    @MainActor
    static func instantiateFromNib() -> Self
}

// MARK: - UIKit Implementation (iOS & iPadOS)
#if canImport(UIKit)
public extension NibInstantiable where Self: UIViewController {
    
    static var nibName: String {
        return String(describing: self)
    }
    
    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    @MainActor
    static func instantiateFromNib() -> Self {
        // We cast to UIViewController.Type to avoid the Swift compiler requirement
        // for subclasses to implement `required init(nibName:bundle:)`.
        let controller = (self as UIViewController.Type).init(nibName: nibName, bundle: bundle)
        return controller as! Self
    }
}
#endif

// MARK: - AppKit Implementation (macOS)
#if canImport(AppKit)
public extension NibInstantiable where Self: NSViewController {
    
    static var nibName: String {
        return String(describing: self)
    }
    
    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    @MainActor
    static func instantiateFromNib() -> Self {
        let controller = (self as NSViewController.Type).init(nibName: NSNib.Name(nibName), bundle: bundle)
        return controller as! Self
    }
}
#endif

//
//  NibStarter.swift
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit

/// Entry-point namespace providing lifecycle and window configuration helpers.
public enum NibStarter {
    
    /// Bootstraps the application window for an iOS `UIWindowScene` lifecycle.
    ///
    /// Usage inside `SceneDelegate.swift`:
    /// ```swift
    /// func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UISceneConnectionOptions) {
    ///     NibStarter.bootstrap(scene: scene, window: &window, root: MainViewController.instantiateFromNib())
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scene: The incoming generic `UIScene` from `scene(_:willConnectTo:options:)`.
    ///   - window: An in-out reference to the `SceneDelegate`'s optional `window` property.
    ///   - root: The root view controller to display.
    @MainActor
    public static func bootstrap(
        scene: UIScene,
        window: inout UIWindow?,
        root: UIViewController
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let newWindow = UIWindow(windowScene: windowScene)
        newWindow.rootViewController = root
        newWindow.makeKeyAndVisible()
        
        window = newWindow
    }
    
    /// Bootstraps the application window for a legacy iOS `AppDelegate` (apps without scenes).
    ///
    /// - Parameters:
    ///   - window: An in-out reference to the `AppDelegate`'s optional `window` property.
    ///   - root: The root view controller to display.
    @MainActor
    public static func bootstrapLegacy(
        window: inout UIWindow?,
        root: UIViewController
    ) {
        let newWindow = UIWindow(frame: UIScreen.main.bounds)
        newWindow.rootViewController = root
        newWindow.makeKeyAndVisible()
        
        window = newWindow
    }
}
#endif

// MARK: - AppKit Bootstrapper (macOS)
#if canImport(AppKit)
import AppKit

public enum NibStarter {
    
    /// Bootstraps a macOS application window containing the root view controller.
    ///
    /// Usage inside `AppDelegate.swift`:
    /// ```swift
    /// func applicationDidFinishLaunching(_ notification: Notification) {
    ///     let windowController = NibStarter.bootstrapAppKit(root: MainViewController.instantiateFromNib())
    ///     self.windowController = windowController
    /// }
    /// ```
    ///
    /// - Parameter root: The root `NSViewController` to display.
    /// - Returns: An `NSWindowController` managing the presented window.
    @MainActor
    @discardableResult
    public static func bootstrapAppKit(
        root: NSViewController,
        title: String = "App",
        contentRect: NSRect = NSRect(x: 0, y: 0, width: 800, height: 600)
    ) -> NSWindowController {
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.center()
        window.contentViewController = root
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let windowController = NSWindowController(window: window)
        return windowController
    }
}
#endif

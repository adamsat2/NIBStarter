//
//  CodeGenerator.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation
import ArgumentParser

public enum ProjectPlatform: String, ExpressibleByArgument, CaseIterable, Sendable {
    case ios
    case macos
}

public enum ProjectLanguage: String, ExpressibleByArgument, CaseIterable, Sendable {
    case swift
    case objc
}

public struct CodeGenerator {
    
    @discardableResult
    public static func generateStarterFiles(
        in targetDir: URL,
        appName: String,
        platform: ProjectPlatform,
        language: ProjectLanguage
    ) throws -> [URL] {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        removeDefaultViewControllerIfUntouched(in: targetDir)
        
        switch platform {
        case .ios:
            return try generateIOSFiles(in: targetDir, appName: appName, language: language)
        case .macos:
            return try generateMacOSFiles(in: targetDir, appName: appName, language: language)
        }
    }
    
    /// Removes Xcode's default template `ViewController.swift`, `ViewController.h`, and `ViewController.m`
    /// if they still contain only the stock template boilerplate.
    public static func removeDefaultViewControllerIfUntouched(in targetDir: URL) {
        let fileManager = FileManager.default
        let vcSwift = targetDir.appendingPathComponent("ViewController.swift")
        if let content = try? String(contentsOf: vcSwift, encoding: .utf8) {
            let nonCommentLines = content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("//") }
            if nonCommentLines.count <= 20 && content.contains("class ViewController") && !content.contains("NibInstantiable") {
                try? fileManager.removeItem(at: vcSwift)
            }
        }
        
        let vcM = targetDir.appendingPathComponent("ViewController.m")
        let vcH = targetDir.appendingPathComponent("ViewController.h")
        if let mContent = try? String(contentsOf: vcM, encoding: .utf8) {
            let nonCommentLines = mContent
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("//") }
            if nonCommentLines.count <= 25 && mContent.contains("@implementation ViewController") {
                try? fileManager.removeItem(at: vcM)
                try? fileManager.removeItem(at: vcH)
            }
        }
    }
    
    private static func writeInPlace(_ content: String, to url: URL) throws {
        try Data(content.utf8).write(to: url)
    }
    
    // MARK: - iOS Scaffolding
    
    private static func generateIOSFiles(in targetDir: URL, appName: String, language: ProjectLanguage) throws -> [URL] {
        var generatedURLs: [URL] = []
        
        let xib = """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0" toolsVersion="22000" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES">
            <device id="retina6_12" orientation="portrait" appearance="light"/>
            <dependencies>
                <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="22000"/>
                <capability name="Safe area layout guides" minToolsVersion="9.0"/>
                <capability name="System colors in document resources" minToolsVersion="11.0"/>
                <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
            </dependencies>
            <objects>
                <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner" customClass="RootViewController">
                    <connections>
                        <outlet property="view" destination="i5M-Pr-FkT" id="sfx-zR-JGt"/>
                    </connections>
                </placeholder>
                <placeholder placeholderIdentifier="IBFirstResponder" id="-2" customClass="UIResponder"/>
                <view clearsContextBeforeDrawing="NO" contentMode="scaleToFill" id="i5M-Pr-FkT">
                    <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                    <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                    <subviews>
                        <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Welcome to NIBStarter" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="lbl-1">
                            <rect key="frame" x="20" y="414" width="353" height="24"/>
                            <fontDescription key="fontDescription" type="boldSystem" pointSize="20"/>
                            <nil key="textColor"/>
                            <nil key="highlightedColor"/>
                        </label>
                    </subviews>
                    <viewLayoutGuide key="safeArea" id="fnl-2z-Ty3"/>
                    <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                    <constraints>
                        <constraint firstItem="lbl-1" firstAttribute="leading" secondItem="fnl-2z-Ty3" secondAttribute="leading" constant="20" id="c1-leading"/>
                        <constraint firstItem="fnl-2z-Ty3" firstAttribute="trailing" secondItem="lbl-1" secondAttribute="trailing" constant="20" id="c1-trailing"/>
                        <constraint firstItem="lbl-1" firstAttribute="centerY" secondItem="i5M-Pr-FkT" secondAttribute="centerY" id="c1-centerY"/>
                    </constraints>
                </view>
            </objects>
        </document>
        """
        let xibURL = targetDir.appendingPathComponent("RootViewController.xib")
        try writeInPlace(xib, to: xibURL)
        generatedURLs.append(xibURL)
        
        switch language {
        case .swift:
            let vc = """
            import UIKit
            import NIBStarter

            final class RootViewController: UIViewController, NibInstantiable {
                override func viewDidLoad() {
                    super.viewDidLoad()
                }
            }
            """
            let sceneDelegate = """
            import UIKit
            import NIBStarter

            class SceneDelegate: UIResponder, UIWindowSceneDelegate {
                var window: UIWindow?

                func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
                    NibStarter.bootstrap(
                        scene: scene,
                        window: &window,
                        root: RootViewController.instantiateFromNib()
                    )
                }
            }
            """
            let vcURL = targetDir.appendingPathComponent("RootViewController.swift")
            let sceneURL = targetDir.appendingPathComponent("SceneDelegate.swift")
            try writeInPlace(vc, to: vcURL)
            try writeInPlace(sceneDelegate, to: sceneURL)
            generatedURLs.append(vcURL)
            generatedURLs.append(sceneURL)
            
            let appDelegateURL = targetDir.appendingPathComponent("AppDelegate.swift")
            if !FileManager.default.fileExists(atPath: appDelegateURL.path) {
                let mainAttr = "@main"
                let appDelegate = """
                import UIKit

                \(mainAttr)
                class AppDelegate: UIResponder, UIApplicationDelegate {
                    var window: UIWindow?

                    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                        return true
                    }

                    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
                        configuration.delegateClass = SceneDelegate.self
                        return configuration
                    }
                }
                """
                try writeInPlace(appDelegate, to: appDelegateURL)
                generatedURLs.append(appDelegateURL)
            }
            
        case .objc:
            let h = """
            #import <UIKit/UIKit.h>

            NS_ASSUME_NONNULL_BEGIN

            @interface RootViewController : UIViewController
            @end

            NS_ASSUME_NONNULL_END
            """
            let m = """
            #import "RootViewController.h"
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
            #import <NIBStarterObjC/NIBStarterObjC.h>
            #endif

            @implementation RootViewController

            - (void)viewDidLoad {
                [super viewDidLoad];
            }

            @end
            """
            let sceneHURL = targetDir.appendingPathComponent("SceneDelegate.h")
            if !FileManager.default.fileExists(atPath: sceneHURL.path) {
                let sceneH = """
                #import <UIKit/UIKit.h>

                @interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

                @property (strong, nonatomic) UIWindow * window;

                @end
                """
                try writeInPlace(sceneH, to: sceneHURL)
                generatedURLs.append(sceneHURL)
            }
            
            let sceneM = """
            #import "SceneDelegate.h"
            #import "RootViewController.h"
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
            #import <NIBStarterObjC/NIBStarterObjC.h>
            #endif

            @implementation SceneDelegate

            - (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
                if (![scene isKindOfClass:[UIWindowScene class]]) return;
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
                self.window.rootViewController = [RootViewController nib_instantiate];
            #else
                self.window.rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:[NSBundle bundleForClass:[RootViewController class]]];
            #endif
                [self.window makeKeyAndVisible];
            }

            @end
            """
            let rootHURL = targetDir.appendingPathComponent("RootViewController.h")
            let rootMURL = targetDir.appendingPathComponent("RootViewController.m")
            let sceneMURL = targetDir.appendingPathComponent("SceneDelegate.m")
            try writeInPlace(h, to: rootHURL)
            try writeInPlace(m, to: rootMURL)
            try writeInPlace(sceneM, to: sceneMURL)
            generatedURLs.append(contentsOf: [rootHURL, rootMURL, sceneMURL])
        }
        
        return generatedURLs
    }
    
    // MARK: - macOS Scaffolding
    
    private static func generateMacOSFiles(in targetDir: URL, appName: String, language: ProjectLanguage) throws -> [URL] {
        var generatedURLs: [URL] = []
        
        let xib = """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="3.0" toolsVersion="22000" targetRuntime="MacOSX.Cocoa" propertyAccessControl="none" useAutolayout="YES" customObjectInstantitationMethod="direct">
            <dependencies>
                <plugIn identifier="com.apple.InterfaceBuilder.CocoaPlugin" version="22000"/>
                <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
            </dependencies>
            <objects>
                <customObject id="-2" userLabel="File's Owner" customClass="RootViewController">
                    <connections>
                        <outlet property="view" destination="c22-O7-iKe" id="b2m-3d-hWc"/>
                    </connections>
                </customObject>
                <customObject id="-1" userLabel="First Responder" customClass="FirstResponder"/>
                <customObject id="-3" userLabel="Application" customClass="NSObject"/>
                <customView id="c22-O7-iKe">
                    <rect key="frame" x="0.0" y="0.0" width="480" height="300"/>
                    <autoresizingMask key="autoresizingMask" flexibleMaxX="YES" flexibleMinY="YES"/>
                    <subviews>
                        <textField focusRingType="none" horizontalHuggingPriority="251" verticalHuggingPriority="750" translatesAutoresizingMaskIntoConstraints="NO" id="lbl-1">
                            <rect key="frame" x="120" y="138" width="240" height="24"/>
                            <textFieldCell key="cell" lineBreakMode="clipping" alignment="center" title="Welcome to NIBStarter" id="cel-1">
                                <font key="font" metaFont="systemBold" size="18"/>
                                <color key="textColor" name="labelColor" catalog="System"/>
                                <color key="backgroundColor" name="textBackgroundColor" catalog="System"/>
                            </textFieldCell>
                        </textField>
                    </subviews>
                    <constraints>
                        <constraint firstItem="lbl-1" firstAttribute="centerX" secondItem="c22-O7-iKe" secondAttribute="centerX" id="cx-1"/>
                        <constraint firstItem="lbl-1" firstAttribute="centerY" secondItem="c22-O7-iKe" secondAttribute="centerY" id="cy-1"/>
                    </constraints>
                </customView>
            </objects>
        </document>
        """
        let xibURL = targetDir.appendingPathComponent("RootViewController.xib")
        try writeInPlace(xib, to: xibURL)
        generatedURLs.append(xibURL)
        
        switch language {
        case .swift:
            let vc = """
            import AppKit
            import NIBStarter

            final class RootViewController: NSViewController, NibInstantiable {
                override func viewDidLoad() {
                    super.viewDidLoad()
                }
            }
            """
            let mainAttr = "@main"
            let appDelegate = """
            import AppKit
            import NIBStarter

            \(mainAttr)
            class AppDelegate: NSObject, NSApplicationDelegate {
                var windowController: NSWindowController?

                static func main() {
                    let app = NSApplication.shared
                    app.setActivationPolicy(.regular)
                    let delegate = AppDelegate()
                    app.delegate = delegate
                    app.run()
                }

                func applicationDidFinishLaunching(_ aNotification: Notification) {
                    windowController = NibStarter.bootstrapAppKit(
                        root: RootViewController.instantiateFromNib(),
                        title: "\(appName)"
                    )
                }
            }
            """
            let vcURL = targetDir.appendingPathComponent("RootViewController.swift")
            let appDelegateURL = targetDir.appendingPathComponent("AppDelegate.swift")
            try writeInPlace(vc, to: vcURL)
            try writeInPlace(appDelegate, to: appDelegateURL)
            generatedURLs.append(contentsOf: [vcURL, appDelegateURL])
            
        case .objc:
            let h = """
            #import <AppKit/AppKit.h>

            NS_ASSUME_NONNULL_BEGIN

            @interface RootViewController : NSViewController
            @end

            NS_ASSUME_NONNULL_END
            """
            let m = """
            #import "RootViewController.h"
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
            #import <NIBStarterObjC/NIBStarterObjC.h>
            #endif

            @implementation RootViewController

            - (void)viewDidLoad {
                [super viewDidLoad];
            }

            @end
            """
            let appDelegateHURL = targetDir.appendingPathComponent("AppDelegate.h")
            if !FileManager.default.fileExists(atPath: appDelegateHURL.path) {
                let appDelegateH = """
                #import <Cocoa/Cocoa.h>

                NS_ASSUME_NONNULL_BEGIN

                @interface AppDelegate : NSObject <NSApplicationDelegate>
                @end

                NS_ASSUME_NONNULL_END
                """
                try writeInPlace(appDelegateH, to: appDelegateHURL)
                generatedURLs.append(appDelegateHURL)
            }
            let appDelegateM = """
            #import <AppKit/AppKit.h>
            #import "AppDelegate.h"
            #import "RootViewController.h"
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
            #import <NIBStarterObjC/NIBStarterObjC.h>
            #endif

            @interface AppDelegate ()
            @property (strong, nonatomic) NSWindowController *windowController;
            @end

            @implementation AppDelegate

            - (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
            #if __has_include(<NIBStarterObjC/NIBStarterObjC.h>)
                RootViewController *root = [RootViewController nib_instantiate];
            #else
                RootViewController *root = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:[NSBundle bundleForClass:[RootViewController class]]];
            #endif
                NSWindow *window = [NSWindow windowWithContentViewController:root];
                window.title = @"\(appName)";
                [window center];
                [window makeKeyAndOrderFront:nil];
                [NSApp activateIgnoringOtherApps:YES];
                self.windowController = [[NSWindowController alloc] initWithWindow:window];
            }

            @end
            """
            let mainM = """
            #import <Cocoa/Cocoa.h>
            #import "AppDelegate.h"

            int main(int argc, const char * argv[]) {
                @autoreleasepool {
                    NSApplication *app = [NSApplication sharedApplication];
                    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
                    AppDelegate *delegate = [[AppDelegate alloc] init];
                    app.delegate = delegate;
                    [app run];
                }
                return 0;
            }
            """
            let rootHURL = targetDir.appendingPathComponent("RootViewController.h")
            let rootMURL = targetDir.appendingPathComponent("RootViewController.m")
            let appDelegateMURL = targetDir.appendingPathComponent("AppDelegate.m")
            let mainMURL = targetDir.appendingPathComponent("main.m")
            try writeInPlace(h, to: rootHURL)
            try writeInPlace(m, to: rootMURL)
            try writeInPlace(appDelegateM, to: appDelegateMURL)
            try writeInPlace(mainM, to: mainMURL)
            generatedURLs.append(contentsOf: [rootHURL, rootMURL, appDelegateMURL, mainMURL])
        }
        
        return generatedURLs
    }
}

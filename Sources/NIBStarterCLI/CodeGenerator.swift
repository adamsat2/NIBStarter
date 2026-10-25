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
    
    public static func generateStarterFiles(
        in targetDir: URL,
        appName: String,
        platform: ProjectPlatform,
        language: ProjectLanguage
    ) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        switch platform {
        case .ios:
            try generateIOSFiles(in: targetDir, appName: appName, language: language)
        case .macos:
            try generateMacOSFiles(in: targetDir, appName: appName, language: language)
        }
    }
    
    // MARK: - iOS Scaffolding
    
    private static func generateIOSFiles(in targetDir: URL, appName: String, language: ProjectLanguage) throws {
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
        try xib.write(to: targetDir.appendingPathComponent("RootViewController.xib"), atomically: true, encoding: .utf8)
        
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
            try vc.write(to: targetDir.appendingPathComponent("RootViewController.swift"), atomically: true, encoding: .utf8)
            try sceneDelegate.write(to: targetDir.appendingPathComponent("SceneDelegate.swift"), atomically: true, encoding: .utf8)
            
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
            #import <NIBStarterObjC/NIBStarterObjC.h>

            @implementation RootViewController

            - (void)viewDidLoad {
                [super viewDidLoad];
            }

            @end
            """
            let sceneM = """
            #import "SceneDelegate.h"
            #import "RootViewController.h"
            #import <NIBStarterObjC/NIBStarterObjC.h>

            @implementation SceneDelegate

            - (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (!windowScene) return;
                self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
                self.window.rootViewController = [RootViewController nib_instantiate];
                [self.window makeKeyAndVisible];
            }

            @end
            """
            try h.write(to: targetDir.appendingPathComponent("RootViewController.h"), atomically: true, encoding: .utf8)
            try m.write(to: targetDir.appendingPathComponent("RootViewController.m"), atomically: true, encoding: .utf8)
            try sceneM.write(to: targetDir.appendingPathComponent("SceneDelegate.m"), atomically: true, encoding: .utf8)
        }
    }
    
    // MARK: - macOS Scaffolding
    
    private static func generateMacOSFiles(in targetDir: URL, appName: String, language: ProjectLanguage) throws {
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
        try xib.write(to: targetDir.appendingPathComponent("RootViewController.xib"), atomically: true, encoding: .utf8)
        
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

                func applicationDidFinishLaunching(_ aNotification: Notification) {
                    windowController = NibStarter.bootstrapAppKit(
                        root: RootViewController.instantiateFromNib(),
                        title: "\(appName)"
                    )
                }
            }
            """
            try vc.write(to: targetDir.appendingPathComponent("RootViewController.swift"), atomically: true, encoding: .utf8)
            try appDelegate.write(to: targetDir.appendingPathComponent("AppDelegate.swift"), atomically: true, encoding: .utf8)
            
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
            #import <NIBStarterObjC/NIBStarterObjC.h>

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
                try appDelegateH.write(to: appDelegateHURL, atomically: true, encoding: .utf8)
            }
            let appDelegateM = """
            #import <AppKit/AppKit.h>
            #import "AppDelegate.h"
            #import "RootViewController.h"
            #import <NIBStarterObjC/NIBStarterObjC.h>

            @interface AppDelegate ()
            @property (strong, nonatomic) NSWindowController *windowController;
            @end

            @implementation AppDelegate

            - (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
                RootViewController *root = [RootViewController nib_instantiate];
                NSWindow *window = [NSWindow windowWithContentViewController:root];
                window.title = @"\(appName)";
                [window makeKeyAndOrderFront:nil];
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
                    AppDelegate *delegate = [[AppDelegate alloc] init];
                    app.delegate = delegate;
                    [app run];
                }
                return 0;
            }
            """
            try h.write(to: targetDir.appendingPathComponent("RootViewController.h"), atomically: true, encoding: .utf8)
            try m.write(to: targetDir.appendingPathComponent("RootViewController.m"), atomically: true, encoding: .utf8)
            try appDelegateM.write(to: targetDir.appendingPathComponent("AppDelegate.m"), atomically: true, encoding: .utf8)
            try mainM.write(to: targetDir.appendingPathComponent("main.m"), atomically: true, encoding: .utf8)
        }
    }
}

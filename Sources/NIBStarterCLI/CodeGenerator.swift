//
//  CodeGenerator.swift
//  NIBStarter
//
//  Created by Adam Stern on 25/10/2026.
//

import Foundation

public struct CodeGenerator {
    
    public static func generateStarterFiles(in targetDir: URL, appName: String) throws {
        let rootVCSwift = """
        import UIKit
        import NIBStarter

        final class RootViewController: UIViewController, NibInstantiable {
            
            @IBOutlet private weak var welcomeLabel: UILabel!
            
            override func viewDidLoad() {
                super.viewDidLoad()
                view.backgroundColor = .systemBackground
            }
        }
        """
        
        let rootVCXib = """
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
                        <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Welcome to NIBStarter" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="abc-123">
                            <rect key="frame" x="20" y="413" width="353" height="26.333333333333314"/>
                            <fontDescription key="fontDescription" type="boldSystem" pointSize="22"/>
                            <nil key="textColor"/>
                            <nil key="highlightedColor"/>
                        </label>
                    </subviews>
                    <viewLayoutGuide key="safeArea" id="fnl-2z-Ty3"/>
                    <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                    <constraints>
                        <constraint firstItem="abc-123" firstAttribute="centerY" secondItem="i5M-Pr-FkT" secondAttribute="centerY" id="c-1"/>
                        <constraint firstItem="abc-123" firstAttribute="leading" secondItem="fnl-2z-Ty3" secondAttribute="leading" constant="20" id="c-2"/>
                        <constraint firstItem="fnl-2z-Ty3" firstAttribute="trailing" secondItem="abc-123" secondAttribute="trailing" constant="20" id="c-3"/>
                    </constraints>
                </view>
            </objects>
            <resources>
                <systemColor name="systemBackgroundColor">
                    <color white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </systemColor>
            </resources>
        </document>
        """
        
        let sceneDelegateSwift = """
        import UIKit
        import NIBStarter

        class SceneDelegate: UIResponder, UIWindowSceneDelegate {

            var window: UIWindow?

            func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
                guard let windowScene = (scene as? UIWindowScene) else { return }
                
                // Programmatic bootstrap via NIBStarter
                NibStarter.bootstrap(
                    scene: windowScene,
                    window: &window,
                    root: RootViewController.instantiateFromNib()
                )
            }
        }
        """
        
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        try rootVCSwift.write(to: targetDir.appendingPathComponent("RootViewController.swift"), atomically: true, encoding: .utf8)
        try rootVCXib.write(to: targetDir.appendingPathComponent("RootViewController.xib"), atomically: true, encoding: .utf8)
        try sceneDelegateSwift.write(to: targetDir.appendingPathComponent("SceneDelegate.swift"), atomically: true, encoding: .utf8)
    }
}

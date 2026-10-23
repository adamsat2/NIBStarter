//
//  SourceParserTests.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import XCTest
@testable import NIBValidatorCore

final class SourceParserTests: XCTestCase {
    
    func testSwiftSourceParserExtractsOutletsAndActions() {
        let code = """
        import UIKit
        
        class ProfileViewController: UIViewController {
            @IBOutlet weak var titleLabel: UILabel!
            @IBOutlet private var avatarView: UIImageView!
            var nonOutletProperty: String = ""
            
            @IBAction func didTapSave(_ sender: UIButton) {
                print("saved")
            }
            
            @IBAction func dismiss() {
                dismiss(animated: true)
            }
        }
        
        extension ProfileViewController {
            @IBOutlet weak var bioTextView: UITextView!
            
            @IBAction func didTapReset(_ sender: Any) {
                // reset
            }
        }
        """
        
        let models = SwiftSourceParser.parse(source: code, fileURL: URL(fileURLWithPath: "/virtual/ProfileViewController.swift"))
        
        // Merge extensions for verification
        var merged = ClassCodeModel(className: "ProfileViewController")
        for m in models where m.className == "ProfileViewController" {
            merged.outlets.formUnion(m.outlets)
            merged.actions.formUnion(m.actions)
        }
        
        // Verify Outlets (including from extension)
        XCTAssertTrue(merged.outlets.contains("titleLabel"))
        XCTAssertTrue(merged.outlets.contains("avatarView"))
        XCTAssertTrue(merged.outlets.contains("bioTextView"))
        XCTAssertFalse(merged.outlets.contains("nonOutletProperty"))
        
        // Verify Actions
        XCTAssertTrue(merged.actions.contains("didTapSave:"))
        XCTAssertTrue(merged.actions.contains("dismiss"))
        XCTAssertTrue(merged.actions.contains("didTapReset:"))
    }
    
    func testObjCSourceParserExtractsOutletsAndActions() {
        let headerCode = """
        #import <UIKit/UIKit.h>
        
        @interface SettingsViewController : UIViewController
        @property (nonatomic, weak) IBOutlet UILabel *volumeLabel;
        @property (nonatomic, weak) IBOutlet UISwitch *muteSwitch;
        @property (nonatomic, strong) NSString *settingKey;
        
        - (IBAction)muteSwitchChanged:(id)sender;
        - (IBAction)restoreDefaults;
        @end
        """
        
        let models = ObjCSourceParser.parse(source: headerCode, fileURL: URL(fileURLWithPath: "/virtual/SettingsViewController.h"))
        
        guard let model = models.first(where: { $0.className == "SettingsViewController" }) else {
            XCTFail("Failed to find SettingsViewController in ObjC header")
            return
        }
        
        // Verify Outlets
        XCTAssertTrue(model.outlets.contains("volumeLabel"))
        XCTAssertTrue(model.outlets.contains("muteSwitch"))
        XCTAssertFalse(model.outlets.contains("settingKey"))
        
        // Verify Actions
        XCTAssertTrue(model.actions.contains("muteSwitchChanged:"))
        XCTAssertTrue(model.actions.contains("restoreDefaults"))
    }
}

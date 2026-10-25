# NIBStarter

NIBStarter is a multiplatform Swift Package Manager (SPM) SDK and developer toolchain for iOS (UIKit) and macOS (AppKit) in both Swift and Objective-C. It replaces Storyboards with modular XIB workflows, catches broken `@IBOutlet` and `@IBAction` connections at build time before they cause runtime crashes, and provides CLI scaffolding and Xcode file templates.

## Features

1. **Type-Safe Runtime Instantiation (`NIBStarter` and `NIBStarterObjC`)**
   - No hardcoded NIB strings. Automatically resolves the NIB name and bundle from your controller class.
   - `@MainActor`-isolated `NibInstantiable` protocol for Swift (`UIViewController` and `NSViewController`).
   - Objective-C categories (`+nib_instantiate`) on `UIViewController` and `NSViewController`.
   - Single-line window bootstrapping helpers for `UISceneDelegate`, legacy `UIApplicationDelegate`, and `NSApplicationDelegate`.
2. **Build-Time XIB Validator (`NIBValidatorPlugin` and `nib-validator`)**
   - Cross-references `.xib` files against Swift (via `SwiftSyntax` AST) and Objective-C (`.h` and `.m`) source files during compilation.
   - Emits inline Xcode compiler errors with exact line numbers for orphaned outlets, broken action selectors, and missing `view` connections.
3. **Project Converter and Xcode Templates CLI (`nibstarter`)**
   - `nibstarter convert`: Strips `Main.storyboard` and `MainMenu.storyboard` from `.xcodeproj`, cleans `Info.plist` and build settings, deletes storyboard files from disk, and scaffolds a starter `RootViewController.xib` and app entry point.
   - `nibstarter install-templates`: Installs four custom Xcode file templates (`File > New > File...`) for `UIViewController` and `NSViewController` in Swift and Objective-C.

## Requirements

| Platform / Tool | Minimum Version |
| :--- | :--- |
| iOS | 15.0+ |
| macOS | 12.0+ |
| Swift | 6.0+ |
| Xcode | 16.0+ |

## Installation (Swift Package Manager)

### 1. In `Package.swift`

Add `NIBStarter` to your package dependencies and attach the runtime library and build tool plugin to your target:

```swift
dependencies: [
    .package(url: "https://github.com/adamsat2/NIBStarter.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "NIBStarter", package: "NIBStarter")
        ],
        plugins: [
            .plugin(name: "NIBValidatorPlugin", package: "NIBStarter")
        ]
    )
]
```

### 2. In an Xcode Project (`.xcodeproj`)

1. Open **File > Add Package Dependencies...** and enter `https://github.com/adamsat2/NIBStarter.git`.
2. Add the **NIBStarter** library product to your app target.
3. To enable build-time XIB validation:
   - Select your project in the Project Navigator, select your app target, and open the **Build Phases** tab.
   - Expand **Run Build Tool Plug-ins** and click **+** to add **NIBValidatorPlugin**.

## Runtime Usage

### Swift (iOS / UIKit)

#### 1. Conform your `UIViewController` to `NibInstantiable`

Create `ProfileViewController.swift` and a matching `ProfileViewController.xib` (with **File's Owner** set to `ProfileViewController`):

```swift
import UIKit
import NIBStarter

final class ProfileViewController: UIViewController, NibInstantiable {
    @IBOutlet private weak var nameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = "Ada Lovelace"
    }

    @IBAction private func didTapEdit(_ sender: UIButton) {
        // Handle action
    }
}

// Instantiate without string literals:
let profileVC = ProfileViewController.instantiateFromNib()
```

To use a custom XIB filename, override `nibName`:

```swift
final class CustomViewController: UIViewController, NibInstantiable {
    static var nibName: String { "CustomLayoutView" }
}
```

#### 2. Bootstrap your `SceneDelegate` (or `AppDelegate`)

```swift
import UIKit
import NIBStarter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        NibStarter.bootstrap(
            scene: scene,
            window: &window,
            root: ProfileViewController.instantiateFromNib()
        )
    }
}
```

For legacy apps without scenes (`AppDelegate`):

```swift
NibStarter.bootstrapLegacy(
    window: &window,
    root: ProfileViewController.instantiateFromNib()
)
```

### Swift (macOS / AppKit)

```swift
import AppKit
import NIBStarter

final class MainViewController: NSViewController, NibInstantiable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NibStarter.bootstrapAppKit(
            root: MainViewController.instantiateFromNib(),
            title: "My Mac App"
        )
    }
}
```

### Objective-C (iOS and macOS)

Import `<NIBStarterObjC/NIBStarterObjC.h>` to use `+nib_instantiate` on any `UIViewController` or `NSViewController` subclass.

#### iOS (`UIViewController`)

```objc
// ProfileViewController.h
#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
- (IBAction)didTapSave:(id)sender;
@end
```

```objc
// SceneDelegate.m
#import "SceneDelegate.h"
#import "ProfileViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    if (!windowScene) return;

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [ProfileViewController nib_instantiate];
    [self.window makeKeyAndVisible];
}

@end
```

#### macOS (`NSViewController`)

```objc
// AppDelegate.m
#import "AppDelegate.h"
#import "MainViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MainViewController *root = [MainViewController nib_instantiate];
    NSWindow *window = [NSWindow windowWithContentViewController:root];
    window.title = @"My Mac App";
    [window makeKeyAndOrderFront:nil];
    self.windowController = [[NSWindowController alloc] initWithWindow:window];
}

@end
```

## Build-Time XIB Validation

When you rename or delete an `@IBOutlet` or `@IBAction` in code without removing the connection in Interface Builder, `NIBValidatorPlugin` fails the build and reports the exact line in the `.xib` file:

```text
/path/to/LoginViewController.xib:25: error: [NIBStarter] Orphaned outlet 'brokenButton' in 'LoginViewController.xib' has no matching '@IBOutlet' property on class 'LoginViewController'.
/path/to/LoginViewController.xib:42: error: [NIBStarter] Orphaned action 'didTapOldButton:' in 'LoginViewController.xib' has no matching '@IBAction' method on class 'LoginViewController'.
```

You can also run the standalone validator CLI directly in CI or pre-commit hooks:

```bash
swift run nib-validator --path /path/to/YourProject --strict
```

## CLI Tool (`nibstarter`)

### 1. Strip Storyboards and Scaffold an Existing Xcode Project

Run `nibstarter convert` inside your project directory to:
- Remove `Main.storyboard` and `MainMenu.storyboard` references and build phase entries from `.xcodeproj`
- Remove `INFOPLIST_KEY_UIMainStoryboardFile` and `INFOPLIST_KEY_NSMainStoryboardFile` build settings
- Strip `UIMainStoryboardFile`, `NSMainStoryboardFile`, and `UISceneStoryboardFile` from `Info.plist`
- Delete physical `.storyboard` files from disk
- Generate a starter `RootViewController` and `RootViewController.xib`, and configure `SceneDelegate` or `AppDelegate`

```bash
# Auto-detect .xcodeproj and platform in the current directory (defaults to Swift):
swift run nibstarter convert

# Specify project path, platform (ios | macos), and language (swift | objc):
swift run nibstarter convert --project MyApp.xcodeproj --platform ios --language objc

# Strip Storyboards without generating starter files:
swift run nibstarter convert --no-scaffold
```

### 2. Install Xcode File Templates

Install the NIBStarter template group into `~/Library/Developer/Xcode/Templates`:

```bash
swift run nibstarter install-templates
```

Restart Xcode and open **File > New > File...** to use the four templates under the **NIBStarter** section:
- **NibInstantiable UIViewController (Swift)**
- **NibInstantiable UIViewController (Objective-C)**
- **NibInstantiable NSViewController (Swift)**
- **NibInstantiable NSViewController (Objective-C)**

To remove the templates:

```bash
swift run nibstarter install-templates --uninstall
```

## Running Tests

```bash
swift test
```

## License

NIBStarter is released under the [MIT License](LICENSE).

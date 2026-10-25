# NIBStarter

A lightweight, modern SDK for iOS and macOS that eliminates Storyboard overhead in favor of pure XIB (NIB) architectures with type-safe instantiation, build-time interface validation, and project migration tooling.

## Key Features

- **Type-Safe NIB Instantiation**: Instantiate `UIViewController` and `NSViewController` instances from matching `.xib` files using protocol-oriented Swift extensions and Objective-C categories without hardcoded string identifiers.
- **Pure Programmatic Bootstrapping**: Clean window/scene configuration helpers for UIKit (`SceneDelegate`, `AppDelegate`) and AppKit (`AppDelegate`), removing the need for Storyboard entry points.
- **Build-Time XIB Validation (`NIBValidatorPlugin`)**: An automated Swift Package Manager build-tool plugin that parses your `.xib` Interface Builder files and Swift/Objective-C source files to detect missing or broken `@IBOutlet` and `@IBAction` connections at compile time.
- **Xcode Command Plugin & CLI (`NIBConvertPlugin`)**: Convert existing Xcode projects to NIBStarter directly inside Xcode via **Product > Perform Action**, automatically stripping Storyboards, updating build settings and Info.plist, and scaffolding programmatic entry points.
- **Xcode File Templates (`nibstarter install-templates`)**: Installs native Xcode templates for creating `NibInstantiable` view controllers and associated `.xib` files with connections pre-wired.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### 1. In a Swift Package (`Package.swift`)

Add NIBStarter as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/adamsat2/NIBStarter.git", from: "1.0.0")
]
```

Add the library to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "NIBStarter", package: "NIBStarter") // Swift + Objective-C
        // Or for pure Objective-C targets:
        // .product(name: "NIBStarterObjC", package: "NIBStarter")
    ]
)
```

### 2. In an Xcode Project (`.xcodeproj`)

1. Open **File > Add Package Dependencies...** and enter `https://github.com/adamsat2/NIBStarter.git`.
2. Add the **NIBStarter** (or **NIBStarterObjC**) library product to your app target.
3. To enable build-time XIB validation:
   - Select your project in the Project Navigator, select your app target, and open the **Build Phases** tab.
   - Expand **Run Build Tool Plug-ins** and click **+** to add **NIBValidatorPlugin**.

## Converting an Existing Project to NIBStarter

You do not need to install any global CLI tools or binaries. Because NIBStarter includes an **Xcode Command Plugin**, you can convert your project directly from inside Xcode or via the Swift Package Manager.

### Option A: Directly Inside Xcode (Recommended for Xcode Projects)

Once you have added the NIBStarter package dependency to your `.xcodeproj`:

1. In Xcode, right-click your project in the Project Navigator (or go to the top menu and select **Product > Perform Action**).
2. Click **Convert Storyboards to NIBStarter**.
3. Xcode will prompt you with a dialog asking to run the plugin and allow write permissions to your project folder.
4. Click **Run**.

The plugin will:
- Strip `Main.storyboard` and `MainMenu.storyboard` references and build phases from your `.xcodeproj`.
- Remove `INFOPLIST_KEY_UIMainStoryboardFile` and `INFOPLIST_KEY_NSMainStoryboardFile` build settings.
- Clean `UIMainStoryboardFile`, `NSMainStoryboardFile`, and `UISceneStoryboardFile` from `Info.plist`.
- Delete physical `.storyboard` files from disk.
- Generate a starter `RootViewController` and `RootViewController.xib`, and configure your `SceneDelegate` or `AppDelegate`.

### Option B: From the Terminal in Swift Packages

If your project is a Swift Package, run the command plugin from your package directory:

```bash
swift package --allow-writing-to-package-directory nibstarter-convert
```

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

When bootstrapping an AppKit application without a Storyboard or main NIB, do not call `NSApplicationMain(argc, argv)`. `NSApplicationMain` looks for a main NIB with `NSApplication` as File's Owner. When no main storyboard or `NSMainNibFile` is set in Info.plist, AppKit searches the bundle and loads the first available `.nib` file (`RootViewController.nib`), assigning `NSApplication` as File's Owner. This causes a runtime failure because `NSApplication` does not have the `view` outlet expected by the view controller. In addition, `AppDelegate` is never instantiated.

Instead, instantiate `AppDelegate`, assign it to `app.delegate`, and call `[app run]` in `main.m`:

```objc
// main.m
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
```

```objc
// AppDelegate.m
#import "AppDelegate.h"
#import "MainViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@interface AppDelegate ()
@property (strong, nonatomic) NSWindowController *windowController;
@end

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

## Xcode File Templates

Install the NIBStarter template group into `~/Library/Developer/Xcode/Templates`:

```bash
swift run nibstarter install-templates
```

Restart Xcode and open **File > New > File...** to use the four templates under the **NIBStarter** section:
- **NibInstantiable UIViewController (Swift)**
- **NibInstantiable UIViewController (Objective-C)**
- **NibInstantiable NSViewController (Swift)**
- **NibInstantiable NSViewController (Objective-C)**

## License

MIT License. See [LICENSE](LICENSE) for details.

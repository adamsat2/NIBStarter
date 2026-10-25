# NIBStarter

A lightweight SDK for iOS and macOS that eliminates Storyboard overhead in favor of pure XIB (NIB) architectures with type-safe instantiation, build-time interface validation, and project migration tooling.

## Key Features

- **Type-Safe NIB Instantiation**: Instantiate UIViewController and NSViewController instances from matching .xib files using protocol-oriented Swift extensions and Objective-C categories without hardcoded string identifiers.
- **Pure Programmatic Bootstrapping**: Window and scene configuration helpers for UIKit (SceneDelegate, AppDelegate) and AppKit (AppDelegate), removing the need for Storyboard entry points.
- **Build-Time XIB Validation (NIBValidatorPlugin)**: A Swift Package Manager build-tool plugin that parses .xib files and Swift/Objective-C source files to detect missing or broken @IBOutlet and @IBAction connections at compile time.
- **Project Conversion Tooling**: Convert existing Xcode projects to NIBStarter, stripping Storyboards, updating build settings and Info.plist, and scaffolding programmatic entry points.
- **Xcode File Templates**: Templates for creating NibInstantiable view controllers and matching .xib files with connections pre-wired.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### In an Xcode Project (.xcodeproj)

1. In Xcode, select **File > Add Package Dependencies...** and enter `https://github.com/adamsat2/NIBStarter.git`.
2. Add the **NIBStarter** library (or **NIBStarterObjC** for pure Objective-C apps) to your application target.
3. (Optional) To enable build-time XIB validation:
   - Select your project in the Project Navigator, select your app target, and open the **Build Phases** tab.
   - Expand **Run Build Tool Plug-ins** and click **+** to add **NIBValidatorPlugin**.

### In a Swift Package (Package.swift)

Add NIBStarter to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/adamsat2/NIBStarter.git", from: "1.0.0")
]
```

Add the product to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "NIBStarter", package: "NIBStarter")
        // Or for pure Objective-C targets:
        // .product(name: "NIBStarterObjC", package: "NIBStarter")
    ]
)
```

---

## Converting an Existing Project to NIBStarter

The conversion tool strips Storyboard references from your project, cleans Storyboard keys from Info.plist and target build settings, deletes physical .storyboard files from disk, and scaffolds a starter RootViewController and .xib with programmatic bootstrapping.

### Method 1: Terminal Command (Direct Invocation)

You do not need to install anything globally. You can invoke the tool directly from terminal using `swift run --package-path`:

```bash
# Inside your Xcode project directory (Swift project):
swift run --package-path /path/to/NIBStarter nibstarter convert

# Inside an Objective-C project directory:
swift run --package-path /path/to/NIBStarter nibstarter convert --language objc

# From any directory, specifying the .xcodeproj location:
swift run --package-path /path/to/NIBStarter nibstarter convert --project /path/to/MyApp/MyApp.xcodeproj --platform ios --language objc

# Strip storyboards without generating starter files:
swift run --package-path /path/to/NIBStarter nibstarter convert --no-scaffold
```

Available options:
- `--project <path>`: Path to the .xcodeproj file (auto-detected if inside the project folder).
- `--platform <ios|macos>`: Target platform (auto-detected from SDK settings if omitted).
- `--language <swift|objc>`: Language to scaffold (defaults to swift).
- `--no-scaffold`: Only strips Storyboards without creating starter files.

### Method 2: Xcode In-IDE Action

If you added NIBStarter as a package dependency in Xcode:

1. Right-click your project root in Xcode's Project Navigator (or open **Product > Perform Action**).
2. Select **Convert Storyboards to NIBStarter**.
3. In the confirmation dialog, click **Run** to allow the plugin to modify project files.

### Method 3: Swift Package Manager CLI (For SPM Projects)

If your app is built as a Swift Package:

```bash
swift package --allow-writing-to-package-directory nibstarter-convert
```

---

## Installing Xcode File Templates

NIBStarter includes Xcode file templates for quick creation of view controllers with matching .xib files.

### Option 1: Terminal

Run the installer via terminal:

```bash
swift run --package-path /path/to/NIBStarter nibstarter install-templates
```

### Option 2: Xcode In-IDE Action

In Xcode, right-click your project root and select **Product > Perform Action > Install NIBStarter File Templates**.

After installing, restart Xcode. When you open **File > New > File...**, four templates will appear under the **NIBStarter** section:
- **NibInstantiable UIViewController (Swift)**
- **NibInstantiable UIViewController (Objective-C)**
- **NibInstantiable NSViewController (Swift)**
- **NibInstantiable NSViewController (Objective-C)**

---

## Runtime Usage

### Swift (iOS / UIKit)

#### 1. Conform UIViewController to NibInstantiable

Create `ProfileViewController.swift` and a matching `ProfileViewController.xib` (set File's Owner to `ProfileViewController` and wire the `view` outlet):

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

// Instantiate with type safety and no string literals:
let profileVC = ProfileViewController.instantiateFromNib()
```

To specify a custom XIB file name:

```swift
final class CustomViewController: UIViewController, NibInstantiable {
    static var nibName: String { "CustomLayoutView" }
}
```

#### 2. Bootstrap in SceneDelegate or AppDelegate

In `SceneDelegate.swift`:

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

For legacy apps without scenes (`AppDelegate.swift`):

```swift
NibStarter.bootstrapLegacy(
    window: &window,
    root: ProfileViewController.instantiateFromNib()
)
```

### Swift (macOS / AppKit)

In `MainViewController.swift`:

```swift
import AppKit
import NIBStarter

final class MainViewController: NSViewController, NibInstantiable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

In `AppDelegate.swift`:

```swift
import AppKit
import NIBStarter

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

#### iOS (UIViewController)

In `ProfileViewController.h`:

```objc
#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
- (IBAction)didTapSave:(id)sender;
@end
```

In `SceneDelegate.m`:

```objc
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

#### macOS (NSViewController)

When bootstrapping an AppKit application without a Storyboard or main NIB, do not call `NSApplicationMain(argc, argv)`. `NSApplicationMain` looks for a main NIB with `NSApplication` as File's Owner. When no main storyboard or `NSMainNibFile` is set in Info.plist, AppKit loads the first available `.nib` file, assigning `NSApplication` as File's Owner, causing an unrecognized selector crash on the `view` outlet.

Instead, instantiate `AppDelegate`, assign it to `app.delegate`, and call `[app run]` in `main.m`:

In `main.m`:

```objc
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

In `AppDelegate.m`:

```objc
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

---

## Build-Time XIB Validation

When you rename or delete an `@IBOutlet` or `@IBAction` in code without removing the connection in Interface Builder, `NIBValidatorPlugin` halts the build and reports the exact file and line number:

```text
/path/to/LoginViewController.xib:25: error: [NIBStarter] Orphaned outlet 'brokenButton' in 'LoginViewController.xib' has no matching '@IBOutlet' property on class 'LoginViewController'.
/path/to/LoginViewController.xib:42: error: [NIBStarter] Orphaned action 'didTapOldButton:' in 'LoginViewController.xib' has no matching '@IBAction' method on class 'LoginViewController'.
```

You can also run the validator directly in CI pipelines or terminal:

```bash
swift run --package-path /path/to/NIBStarter nib-validator --path /path/to/YourProject --strict
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

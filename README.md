# NIBStarter

A lightweight, type-safe SDK and developer toolchain for building UIKit (iOS) and AppKit (macOS) interfaces using standalone `.xib` files in both Swift and Objective-C, without Storyboards.

---

## Why NIBStarter?

Storyboards can introduce merge conflicts in team environments, obscure view controller initialization, and encourage stringly-typed segues. Standalone `.xib` files give you visual layout tooling in Interface Builder while keeping navigation and dependency injection in code.

Working with raw `.xib` files in UIKit and AppKit normally involves repetitive boilerplate and runtime traps:
- Calling `init(nibName: "MyViewController", bundle: nil)` relies on hardcoded strings.
- Disconnecting the `view` outlet or mistyping the File's Owner class in Interface Builder compiles cleanly and crashes at runtime (`NSInternalInconsistencyException`).
- New Xcode projects come pre-wired with `Main.storyboard` across `project.pbxproj`, build settings, and `Info.plist`.

**NIBStarter** solves all three problems:
1. **Zero-String Runtime Library (`NIBStarter` & `NIBStarterObjC`)**: Type-safe XIB instantiation and window bootstrapping for **Swift and Objective-C** on **iOS and macOS**.
2. **Xcode Project Converter (`NIBConvertPlugin`)**: An Xcode Command Plugin that strips Storyboard references, cleans `Info.plist` and build settings, removes the default template `ViewController`, and scaffolds a working `RootViewController` + `.xib` in Swift or Objective-C.
3. **XIB Contract Validator (`NIBValidatorPlugin` & `NIBValidateCommandPlugin`)**: Validates your `.xib` XML and source files either automatically during compilation (`NIBValidatorPlugin`) or on demand from the Project Navigator context menu (`NIBValidateCommandPlugin`).

---

## Requirements

- **Xcode**: 16.0+
- **Platforms**: iOS 15.0+ / macOS 12.0+
- **Languages**: Swift & Objective-C

---

## Installation (Swift Package Manager)

1. Open your iOS or macOS project in Xcode.
2. Go to **File > Add Package Dependencies...**
3. Enter the repository URL:
   ```text
   https://github.com/adamsat2/NIBStarter.git
   ```
4. Click **Add Package**.
5. When prompted to choose package products for your target:
   - For **Swift** projects, add **`NIBStarter`** to your app target.
   - For **Objective-C** projects, add **`NIBStarterObjC`** to your app target.

---

## Converting an Existing Project (`NIBConvertPlugin`)

When you create a new project in Xcode, the default template includes Storyboard boilerplate. Once you have added NIBStarter to your project's Package Dependencies, you can convert the project directly inside Xcode:

1. In the **Xcode Project Navigator** (left sidebar), **right-click your top-level project icon**.
2. Select **`NIBConvertPlugin`** (or **Convert Storyboards to NIBStarter** depending on your Xcode version) from the context menu.
3. Select your application target in the dialog and click **Run**.
4. When prompted by Xcode, click **Allow** to grant the plugin permission to update your project files.

### What `NIBConvertPlugin` Does Automatically

The converter inspects your project to detect the platform (**iOS** or **macOS**) and language (**Swift** or **Objective-C**), then performs the following steps:
1. **Strips `project.pbxproj`**: Removes `Main.storyboard` and `MainMenu.storyboard` file references, variant groups, `PBXBuildFile` entries, and `INFOPLIST_KEY_UIMainStoryboardFile` / `INFOPLIST_KEY_NSMainStoryboardFile` build settings across all project and target configurations.
2. **Cleans `Info.plist`**: Removes `UIMainStoryboardFile`, `NSMainStoryboardFile`, and `UISceneStoryboardFile` keys while preserving your `UISceneDelegateClassName` configuration.
3. **Deletes Storyboard and Template Files**: Deletes `Main.storyboard`, `MainMenu.storyboard`, `Base.lproj/Main.storyboard`, and the default untouched template `ViewController` files from disk while leaving `LaunchScreen.storyboard` intact on iOS.
4. **Scaffolds Starter NIB Files**:
   - **iOS (Swift)**: Generates `RootViewController.xib`, `RootViewController.swift`, and configures `SceneDelegate.swift`.
   - **iOS (Objective-C)**: Generates `RootViewController.xib`, `RootViewController.h`, `RootViewController.m`, and configures `SceneDelegate.m`.
   - **macOS (Swift)**: Generates `RootViewController.xib`, `RootViewController.swift`, and configures `AppDelegate.swift` with an explicit `main()` entry point.
   - **macOS (Objective-C)**: Generates `RootViewController.xib`, `RootViewController.h`, `RootViewController.m`, `AppDelegate.m`, and configures `main.m` to run `NSApplication` with `AppDelegate` without `NSApplicationMain` storyboard lookup.
5. **Registers Build-Time Validation**: Automatically attaches `NIBValidatorPlugin` to your application target's **Run Build Tool Plug-ins** phase.

After running the plugin, press **Cmd + R** in Xcode to build and run your app.

---

## Installing Xcode File Templates (`NIBInstallTemplatesPlugin`)

NIBStarter includes a custom Xcode file template (**NibInstantiable View Controller**) that creates a pre-paired View Controller and `.xib` file with the File's Owner and `view` outlet already connected.

To install the template from Xcode:
1. In the **Xcode Project Navigator**, **right-click your top-level project icon**.
2. Select **`NIBInstallTemplatesPlugin`** (or **Install NIBStarter Xcode Templates**) from the context menu and click **Run**.
3. Restart Xcode and press **Cmd + N** (**File > New > File from Template...**) to find **NibInstantiable View Controller** under the **NIBStarter** section.

---

## Runtime Usage

### 1. Swift (iOS / UIKit)

Conform your `UIViewController` subclass to `NibInstantiable` and ensure its `.xib` file has the matching name (for example, `ProfileViewController.swift` and `ProfileViewController.xib`):

```swift
import UIKit
import NIBStarter

final class ProfileViewController: UIViewController, NibInstantiable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

Instantiate and present it anywhere without string literals:

```swift
let profileVC = ProfileViewController.instantiateFromNib()
navigationController?.pushViewController(profileVC, animated: true)
```

In `SceneDelegate.swift`, bootstrap the root window using `NibStarter.bootstrap`:

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
            root: RootViewController.instantiateFromNib()
        )
    }
}
```

For apps without scenes (`AppDelegate`-only lifecycle), use `NibStarter.bootstrapLegacy`:

```swift
NibStarter.bootstrapLegacy(
    window: &window,
    root: RootViewController.instantiateFromNib()
)
```

---

### 2. Swift (macOS / AppKit)

Conform your `NSViewController` subclass to `NibInstantiable`:

```swift
import AppKit
import NIBStarter

final class RootViewController: NSViewController, NibInstantiable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

In `AppDelegate.swift`, define `static func main()` (so AppKit does not look for a removed `NSMainStoryboardFile`) and call `NibStarter.bootstrapAppKit`:

```swift
import AppKit
import NIBStarter

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NibStarter.bootstrapAppKit(
            root: RootViewController.instantiateFromNib(),
            title: "My Mac App"
        )
    }
}
```

---

### 3. Objective-C (iOS / UIKit)

Link `NIBStarterObjC` to your target and import `<NIBStarterObjC/NIBStarterObjC.h>`. Every `UIViewController` subclass gains the `+nib_instantiate` class method:

```objc
// RootViewController.h
#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController
@end

// RootViewController.m
#import "RootViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@implementation RootViewController
@end
```

In `SceneDelegate.m`, instantiate your controller with `[RootViewController nib_instantiate]`:

```objc
#import "SceneDelegate.h"
#import "RootViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [RootViewController nib_instantiate];
    [self.window makeKeyAndVisible];
}

@end
```

---

### 4. Objective-C (macOS / AppKit)

Link `NIBStarterObjC` to your target and import `<NIBStarterObjC/NIBStarterObjC.h>`. Every `NSViewController` subclass gains `+nib_instantiate`:

```objc
// AppDelegate.m
#import <AppKit/AppKit.h>
#import "AppDelegate.h"
#import "RootViewController.h"
#import <NIBStarterObjC/NIBStarterObjC.h>

@interface AppDelegate ()
@property (strong, nonatomic) NSWindowController *windowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    RootViewController *root = [RootViewController nib_instantiate];
    NSWindow *window = [NSWindow windowWithContentViewController:root];
    window.title = @"My Mac App";
    [window center];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    self.windowController = [[NSWindowController alloc] initWithWindow:window];
}

@end
```

In `main.m`, attach `AppDelegate` directly to `NSApplication.sharedApplication` before calling `[app run]`:

```objc
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
```

---

## Custom NIB Names (Swift)

If a view controller's `.xib` file uses a different name than the Swift class, override `nibName`:

```swift
final class CustomViewController: UIViewController, NibInstantiable {
    static var nibName: String {
        return "SharedCustomLayout"
    }
}
```

---

## XIB Contract Validation (`NIBValidateCommandPlugin` & `NIBValidatorPlugin`)

NIBStarter provides two ways to validate your `.xib` connections against your Swift and Objective-C view controller classes:

### Option 1: Right-Click On-Demand Validation (`NIBValidateCommandPlugin`)

1. In the **Xcode Project Navigator**, **right-click your top-level project icon**.
2. Select **`NIBValidateCommandPlugin`** (or **Validate XIB Contracts with NIBStarter**) from the context menu.
3. Click **Run** to validate all `.xib` files in your project immediately.

### Option 2: Automatic Build-Time Validation (`NIBValidatorPlugin`)

Running `NIBConvertPlugin` automatically adds `NIBValidatorPlugin` to your target's **Run Build Tool Plug-ins** phase. You can also add it manually:

1. Select your project in the **Xcode Project Navigator**.
2. Select your application target and open the **Build Phases** tab.
3. Expand **Run Build Tool Plug-ins**.
4. Click **+** and select **`NIBValidatorPlugin`** from **NIBStarter**.
5. If Xcode prompts you to trust the plugin on the next build, click **Trust & Enable**.

### What the Validator Verifies

The validator scans your target's `.xib` files and source files (`.swift`, `.h`, `.m`) to verify:
- Every `NibInstantiable` controller has a matching `.xib` file in the target.
- The `.xib` File's Owner `customClass` matches the view controller class name.
- The File's Owner `view` outlet is connected in Interface Builder.
- Every `@IBOutlet` and `@IBAction` connected in the `.xib` exists on the corresponding view controller class.

If any check fails, Xcode reports a build error directly in the Issue Navigator before the app can launch with a broken nib.

---

## License

MIT License.

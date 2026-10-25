//
//  NSViewController+NIBStarter.h
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

#import <Foundation/Foundation.h>

#if __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSViewController (NIBStarter)

/// Instantiates an NSViewController from a NIB matching the class name on macOS.
/// Automatically resolves the class's bundle and strips any Swift module prefixes.
+ (instancetype)nib_instantiate;

@end

NS_ASSUME_NONNULL_END

#endif

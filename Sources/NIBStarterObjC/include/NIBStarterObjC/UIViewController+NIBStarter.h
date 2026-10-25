//
//  UIViewController+NIBStarter.h
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (NIBStarter)

/// Instantiates a view controller from a NIB matching the class name.
/// Automatically resolves the class's bundle and strips any Swift module prefixes.
+ (instancetype)nib_instantiate;

@end

NS_ASSUME_NONNULL_END

#endif

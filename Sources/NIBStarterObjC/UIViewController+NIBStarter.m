//
//  UIViewController+NIBStarter.m
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

#import "include/NIBStarterObjC/UIViewController+NIBStarter.h"

#if __has_include(<UIKit/UIKit.h>)

@implementation UIViewController (NIBStarter)

+ (instancetype)nib_instantiate {
    Class currentClass = [self class];
    NSString *fullClassName = NSStringFromClass(currentClass);
    
    // In case this is a Swift class accessed from Obj-C (e.g. "MyApp.ProfileViewController"),
    // strip the module prefix so we search for "ProfileViewController.nib"
    NSString *cleanNibName = [[fullClassName componentsSeparatedByString:@"."] lastObject];
    NSBundle *bundle = [NSBundle bundleForClass:currentClass];
    
    return [[self alloc] initWithNibName:cleanNibName bundle:bundle];
}

@end

#endif

//
//  NSViewController+NIBStarter.m
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

#import "include/NSViewController+NIBStarter.h"

#if __has_include(<AppKit/AppKit.h>)

@implementation NSViewController (NIBStarter)

+ (instancetype)nib_instantiate {
    Class currentClass = [self class];
    NSString *fullClassName = NSStringFromClass(currentClass);
    
    // Strip Swift module namespace if invoked on a Swift class from Objective-C
    NSString *cleanNibName = [[fullClassName componentsSeparatedByString:@"."] lastObject];
    NSBundle *bundle = [NSBundle bundleForClass:currentClass];
    
    return [[self alloc] initWithNibName:cleanNibName bundle:bundle];
}

@end

#endif

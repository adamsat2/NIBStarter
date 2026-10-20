//
//  NIBStarterObjC.h
//  NIBStarter
//
//  Created by Adam Stern on 20/10/2026.
//

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIKit.h>)
#import "UIViewController+NIBStarter.h"
#endif

#if __has_include(<AppKit/AppKit.h>)
#import "NSViewController+NIBStarter.h"
#endif

//
//  Copyright © 2018 Microsoft All rights reserved.
//  Licensed under the Apache License (2.0).
//

#import <UIKit/UIKit.h>
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import <UserNotifications/UserNotifications.h> 

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)handleRegister;
- (void)handleUnregister;

@end


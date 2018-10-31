//
//  Copyright © 2018 Microsoft All rights reserved.
//  Licensed under the Apache License (2.0).
//

#import "AppDelegate.h"
#import "Constants.h"
#import "NotificationDetailViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

////////////////////////////////////////////////////////////////////////////////
//
// UIApplicationDelegate methods
//
////////////////////////////////////////////////////////////////////////////////

//
// Tells the delegate that the launch process is almost done and the app is almost ready to run.
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application?language=objc
//
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //
    // It is important to always set the UNUserNotificationCenterDelegate when the app launches. Otherwise the app
    // may miss some notifications.
    //
    [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];

    return YES;
}

//
// Tells the app that a remote notification arrived that indicates there is data to be fetched.
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application?language=objc
//
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"Received remote (silent) notification");
    [self logNotificationDetails:userInfo];
    
    //
    // Let the system know the silent notification has been processed.
    //
    completionHandler(UIBackgroundFetchResultNoData);
}

//
// Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
//
// https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application?language=objc
//
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSMutableSet *tags = [[NSMutableSet alloc] init];

    // Load and parse stored tags
    NSString *unparsedTags = [[NSUserDefaults standardUserDefaults] valueForKey:NHUserDefaultTags];
    if (unparsedTags.length > 0) {
        NSArray *tagsArray = [unparsedTags componentsSeparatedByString: @","];
        [tags addObjectsFromArray:tagsArray];
    }

    //
    // Register the device with the Notification Hub.
    // If the device has not already been registered, this will create the registration.
    // If the device has already been registered, this will update the existing registration.
    //
    SBNotificationHub* hub = [self getNotificationHub];
    [hub registerNativeWithDeviceToken:deviceToken tags:tags completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error registering for notifications: %@", error);
        } else {
            [self showAlert:@"Registered" withTitle:@"Registration Status"];
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////
//
// UNUserNotificationCenterDelegate methods
//
////////////////////////////////////////////////////////////////////////////////

//
// Asks the delegate how to handle a notification that arrived while the app was running in the foreground.
//
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter?language=objc
//
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSLog(@"Received notification while the application is in the foreground");
    //
    // The system calls this delegate method when the app is in the foreground. This allows the app to handle the notification
    // itself (and potentially modify the default system behavior).
    //
    
    //
    // Handle the notification by displaying custom UI.
    //
    [self showNotification:notification.request.content.userInfo];
    
    //
    // Use 'options' to specify which default behaviors to enable.
    // https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions?language=objc
    // - UNAuthorizationOptionBadge: Apply the notification's badge value to the app’s icon.
    // - UNAuthorizationOptionSound: Play the sound associated with the notification.
    // - UNAuthorizationOptionAlert: Display the alert using the content provided by the notification.
    //
    // In this case, do not pass UNAuthorizationOptionAlert because the notification was handled by the app.
    //
    completionHandler(UNAuthorizationOptionBadge | UNAuthorizationOptionSound);
}

//
// Asks the delegate to process the user's response to a delivered notification.
//
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=objc
//
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSLog(@"Received notification while the application is in the background");
    //
    // The system calls this delegate method when the user taps or responds to the system notification.
    //
    
    //
    // Handle the notification response by displaying custom UI
    //
    [self showNotification:response.notification.request.content.userInfo];
    
    //
    // Let the system know the response has been processed.
    //
    completionHandler();
}

////////////////////////////////////////////////////////////////////////////////
//
// App logic and helpers
//
////////////////////////////////////////////////////////////////////////////////

- (SBNotificationHub *)getNotificationHub {
    NSString *hubName = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoHubName];
    NSString *connectionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoConnectionString];
    
    return [[SBNotificationHub alloc] initWithConnectionString:connectionString notificationHubPath:hubName];
}

- (void)handleRegister {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    UNAuthorizationOptions options =  UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [center requestAuthorizationWithOptions:(options) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error requesting for authorization: %@", error);
        }
    }];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)handleUnregister {
    //
    // Unregister the device with the Notification Hub.
    //
    SBNotificationHub *hub = [self getNotificationHub];
    [hub unregisterNativeWithCompletion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error unregistering for push: %@", error);
        } else {
            [self showAlert:@"Unregistered" withTitle:@"Registration Status"];
        }
    }];
}

- (void)logNotificationDetails:(NSDictionary *)userInfo {
    if (userInfo != nil) {
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        BOOL background = state != UIApplicationStateActive;
        NSLog(@"Received %@notification: \n%@", background ? @"(background) " : @"", userInfo);
    }
}

- (void)showAlert:(NSString *)message withTitle:(NSString *)title {
    if (title == nil) {
        title = @"Alert";
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)showNotification:(NSDictionary *)userInfo {
    [self logNotificationDetails:userInfo];

    NotificationDetailViewController *notificationDetail = [[NotificationDetailViewController alloc] initWithUserInfo:userInfo];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:notificationDetail animated:YES completion:nil];
}

@end

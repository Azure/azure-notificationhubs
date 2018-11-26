[![Build status](https://build.appcenter.ms/v0.1/apps/690304e0-63d9-429c-8c9e-f44abe9305dc/branches/master/badge)](https://appcenter.ms)
# iOS Notification Hubs Sample

This is a sample project intended to demonstrate the usage of the Azure Notification Hubs iOS Client SDK.  The sample app allows the developer to register the device with a Notification Hub with the given tags as well as unregister the device. 

This app handles the following scenarios
- Register and unregister the device with the Notification Hub with the given tags
- Receive push notifications
- Receive silent push notifications
- Handle mutable messages via a Notification Service Extension

## Getting Started

The sample application requires the following:
- macOS Sierra+
- Xcode 10+
- iOS device with iOS 10+

In order to set up the Azure Notification Hub, [follow the tutorial](https://docs.microsoft.com/en-us/azure/notification-hubs/notification-hubs-ios-apple-push-notification-apns-get-started) to create the required certificates and register your application.

To run the application, update the following values in `Info.plist` with values from the notification hub:
- `NotificationHubConnectionString`: Use the `DefaultListenSharedAccessSignature` connection string from the notification hub created in the tutorial
- `NotificationHubName`: Use the name of the notification hub created in the tutorial

Once the values have been updated, build the application and deploy to your device.  From there, you can register the device, set tags used to target the device, and unregister the device.

## Setting up the notification code

Diving into the sample code, we can use the SDK to connect to the service using the connection string and hub name from `Info.plist`.

```objc
- (SBNotificationHub *)getNotificationHub {
    NSString *hubName = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoHubName];
    NSString *connectionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:NHInfoConnectionString];
    
    return [[SBNotificationHub alloc] initWithConnectionString:connectionString notificationHubPath:hubName];
}
```

We can then register for push notifications (with options to enable sound and badge updates) using the following code:

```objc
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
```

We can also unregister the device from the Azure Notification Hub with the following code:

```objc
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
```

## Handle a push notification

In order to demonstrate handling a push notification, use the Azure Portal for your Notification Hub and select "Test Send" to send messages to your application.  For example, we can send a simple message to our device by selecting the Apple Platform, adding your selected tags and the following message body:

```
{
    "aps": {
        "alert": {
            "title": "Alert title",
            "body": "This is the alert body"
        }
    }
}
```

Diving into the code, the push notifications are handled by the following two `UNUserNotificationCenterDelegate` delegate methods.

The `userNotificationCenter:willPresentNotification:withCompletionHandler:` method handles notifications when the app is in the foreground (before the notification is optionally displayed to the user):

```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    // Your code goes here
}
```

The `userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:` method handles notifications when the app is in the background, _and_ the user taps on the system notification:

```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    // Your code goes here
}
```

## Handle a silent push

The iOS platform allows for [silent notifications](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_updates_to_your_app_silently?language=objc) which allow you to notify your application when new data is available, without displaying that notification to the user.  Using the "Test Send" capability, we can send a silent notification using the `content-available` property in the message body.

```
{
    "aps": {
        "content-available": 1
    }
}
```

To handle this scenario in code, implement the `UIApplicationDelegate` method `application:didReceiveRemoteNotification:fetchCompletionHandler:`:

```objc
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // Your code goes here
}
```

## Handle a mutable push message

The iOS platform also allows for you to [modify the incoming push notifications](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications?language=objc). For example, if the notification message is encrypted, needs translation, or other pre-processing before the notification is displayed. We can test this scenario by adding the `mutable-content` flag to message body.

```
{
    "aps": {
        "alert": {
            "title": "Alert title",
            "body": "This is the alert body"
        },
        "mutable-content": 1
    }
}
```

Mutable notifications are handled by adding a Notification Service Extension to the project and implementing the `didReceiveNotificationRequest:withContentHandler:` and `serviceExtensionTimeWillExpire` methods.

# Credits

- App icons are based on icons from [Material Design](https://material.io/tools/icons) and were packaged with [MakeAppIcon](https://makeappicon.com/).

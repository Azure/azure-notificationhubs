//
//  Copyright © 2018 Microsoft All rights reserved.
//  Licensed under the Apache License (2.0).
//

#import <UIKit/UIKit.h>
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import <UserNotifications/UserNotifications.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *tagsTextField;
@property (strong, nonatomic) IBOutlet UIButton *registerButton;
@property (strong, nonatomic) IBOutlet UIButton *unregisterButton;

@end


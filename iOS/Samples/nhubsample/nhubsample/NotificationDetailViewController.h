//
//  Copyright © 2018 Microsoft All rights reserved.
//  Licensed under the Apache License (2.0).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NotificationDetailViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UIButton *dismissButton;

@property (strong, nonatomic) NSDictionary *userInfo;

- (id)initWithUserInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END

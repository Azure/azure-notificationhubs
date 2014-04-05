#import "HubInstantiationTests.h"

@implementation HubInstantiationTests


-(void)setUp
{
}

// When wrong security info is provided 
-(void)testHubWithWrongToken
{
    SBNotificationHub* wrongNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:[TestHelper getInvalidAcsConnString:testConfig] notificationHubPath:[testConfig NotificationHubWithWrongConnStr]];

    NSData*deviceToken = [[TestHelper getRandomDeviceToken] dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Device Token %@",deviceToken);
    
    NSError *error;
    BOOL registerReturn = [wrongNotificationHub registerNativeWithDeviceToken:deviceToken tags:nil error:&error];
    GHAssertFalse(registerReturn, @"registerDefaultWithDeviceToken passed ");
    GHAssertNotNil(error, @"Error is null");
    GHTestLog(@"HubInstantiationTests :: testHubWithWrongToken SUCCESS");
}

-(void)testHubWithWrongConnStringFormat
{
    SBNotificationHub* wrongConnFormat = [[SBNotificationHub alloc] initWithConnectionString:[TestHelper getInvalidFormatConnString] notificationHubPath:@"testHubWithWrongConnStringFormat"];
    GHAssertNil(wrongConnFormat, @"Notification hub not null");
    GHTestLog(@"HubInstantiationTests :: testHubWithWrongConnStringFormat SUCCESS");
}


// This test requires notification hub to be created with token having
// special characters
// TBD : While creating notification hubs this has to be taken care of 
-(void)testTokenWithSpecialChars
{
    [TestHelper clearLocalStorageWithNotificationPath:[testConfig NotificationHubWithSpecialTokens]];

    SBNotificationHub* wrongNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:[TestHelper getConnStringWithSpecialChars:testConfig] notificationHubPath:[testConfig NotificationHubWithSpecialTokens]];

    NSData*deviceToken = [[TestHelper getRandomDeviceToken] dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Device Token %@",deviceToken);
    
    NSError *error;
    BOOL ret = [wrongNotificationHub registerNativeWithDeviceToken:deviceToken tags:nil error:&error];
    GHAssertFalse(ret, @"registerDefaultWithDeviceToken failed");
    GHTestLog(@"HubInstantiationTests :: testTokenWithSpecialChars SUCCESS");
}

@end

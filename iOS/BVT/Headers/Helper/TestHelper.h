#import <Foundation/Foundation.h>
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import "TestConfig.h"
#import "Registration.h"


@interface TestHelper : NSObject
+ (NSString*) getCurrentDateTime;
+(int)getNumDaysBetweenFromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;
+ (NSString *)getDeviceTokenStringFromData:(NSData *)deviceTokenData;
+(NSTimeInterval) getTimeInMinutesTillDate:(NSDate*)toDate;

+(NSString*)getRandomDeviceToken;
+(NSString*)getInvalidAcsConnString : (TestConfig*)testConfig;
+(NSString*)getInvalidFormatConnString ;
+(NSString*)getConnStringWithSpecialChars : (TestConfig*)testConfig;
+(void)clearLocalStorageWithNotificationPath:(NSString*)path;
+ (NSString*) nameOfRegistration:(Registration*)registration;
+ (NSString*) convertTagSetToString:(NSSet*)tagSet;
+ (NSError*) errorWithMsg:(NSString*)msg code:(NSInteger)code;
+ (NSString*)getRandomName;
@end

#import "TestHelper.h"
#import <Foundation/NSCalendar.h>
#import "Registration.h"
#import "TemplateRegistration.h"

@implementation TestHelper

+ (NSString*) getCurrentDateTime {
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    //[formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    //[formatter release];
    
    NSLog(@"Current data: %@", dateString);
    return dateString;
}

+(int)getNumDaysBetweenFromDate:(NSDate*)fromDate toDate:(NSDate*)toDate
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    
    NSLog(@"Difference in date components: %i/%i/%i", components.day, components.month, components.year);
    
    
    return components.day;
}

+(NSTimeInterval) getTimeInMinutesTillDate:(NSDate*)toDate
{
    return [toDate timeIntervalSinceDate:[NSDate date]]/60;
}

+ (NSString *)getDeviceTokenStringFromData:(NSData *)deviceTokenData
{
    NSString* newDeviceToken = [[[[[deviceTokenData description]
                                   stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                  stringByReplacingOccurrencesOfString:@">" withString:@""]
                                 stringByReplacingOccurrencesOfString: @" " withString: @""] uppercaseString];
    return newDeviceToken;
}

+(NSString*)getRandomDeviceToken
{
     NSString* hexChars = @"0123456789abcdef";
    NSMutableString *hexArray = [NSMutableString string];
    for (int i=0; i<64; i++)
        
        [hexArray appendFormat:@"%02x", [hexChars characterAtIndex:arc4random() % 16]];

    return[NSString stringWithString:hexArray];
}

+(NSString*)getInvalidAcsConnString : (TestConfig*)testConfig
{
    NSString* connStr = [SBConnectionString stringWithEndpoint:[testConfig getCurrentTestEndPoint] issuer:@"owner" issuerSecret:[[testConfig TestSolutionKey] stringByAppendingString:@"Iguazu"]];
    
    connStr = [NSString stringWithFormat:@"%@;%@", connStr,[testConfig getCurrentStsEndPoint]];
    NSLog(@"Wrong connection string = %@",connStr);
    return connStr;
}

+(NSString*)getInvalidFormatConnString
{
    return @"_THIS_IS_INVALID_CONN_STR";
}

+(NSString*)getConnStringWithSpecialChars : (TestConfig*)testConfig
{
    //NSString* connStr = [SBConnectionString stringWithEndpoint:[testConfig getCurrentTestEndPoint] listenAccessSecret:[testConfig TestSpecialToken]];
    NSString* connStr = [SBConnectionString stringWithEndpoint:[testConfig getCurrentTestEndPoint] sharedAccessKeyName:@"DefaultManagementKey" accessSecret:[testConfig TestSpecialToken]];
    
    NSLog(@"connection string = %@",connStr);
    return connStr;
}

+ (void)clearLocalStorageWithNotificationPath:(NSString*)path
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* str = [NSString stringWithFormat:@"%@-version",path];
    [defaults removeObjectForKey:str];
    
    str = [NSString stringWithFormat:@"%@-deviceToken",path];
    [defaults removeObjectForKey:str];

    str = [NSString stringWithFormat:@"%@-registrations",path];
    [defaults removeObjectForKey:str];
    
    [defaults synchronize];
}

+ (NSString*) nameOfRegistration:(Registration*)registration
{
    if( [registration class] == [TemplateRegistration class])
    {
        return ((TemplateRegistration*)registration).templateName;
    }
    else
    {
        return [Registration Name];
    }
}

+ (NSString*) convertTagSetToString:(NSSet*)tagSet
{
    if(!tagSet)
    {
        return @"";
    }
    
    NSMutableString* tags;
    
    for (NSString *element in tagSet) {
        if(!tags)
        {
            tags=[[NSMutableString alloc] initWithString:element];
        }
        else
        {
            [tags appendString:[NSString stringWithFormat:@",%@",element]];
        }
    }
    
    return tags;
}

+ (NSError*) errorWithMsg:(NSString*)msg code:(NSInteger)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:msg forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:@"WindowsAzureMessaging" code:code userInfo:details];
}

+ (NSString*)getRandomName
{
    NSString* charSet = @"abcdefghijklmnopqrstuvwxyz";
    NSMutableString* randomName = [NSMutableString stringWithCapacity:5];
    
    for(NSUInteger i = 0U; i < 5; i++)
    {
        u_int32_t r = arc4random() % [charSet length];
        unichar character = [charSet characterAtIndex:r];
        
        [randomName appendFormat:@"%C", character];
    }
    
    return randomName;
}

@end

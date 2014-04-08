// TBD : All test configurations need to be read from .plist
// file

#import "TestConfig.h"

const int DEFAULT_REG_EXPIRY_IN_DAYS = 90;

@implementation TestConfig

- (id)init
{
    self = [super init];
    if (self) {
        // Set the targetEnvironment here
        // Under usual circumstances, this will be the only setting
        // user will have to set to run the tests
        //
        targetEnvironment      = @"INT7-SN1-002";
        
        [self SetInitParams];
    }
    return self;
}

-(void)setConnType : (NSString*)conType
{
    connType = conType;
}

-(NSString*)ConnType
{
    return connType;
}

-(NSString*)TestSolutionKey
{
    return testSolutionKey;
}

-(NSString*)TestSasKey
{
    return testSasKey;
}

-(NSString*)TestSpecialToken
{
    return specialTokenValue;
}

-(NSString*)DefaultNotificationHub
{
    return deafultNotificationHub;
}

-(NSString*)NotificationHubWithWrongConnStr
{
    return notificationHubWithWrongConnStr;
}

-(NSString*)NotificationHubWithSpecialTokens
{
    return notificationHubWithSpecialTokens;
}

-(NSString*)SpecialToken
{
    return specialTokenValue;
}

-(NSString*)TargetEnvironment
{
    return targetEnvironment;
}

-(NSString*)TestSolutionName
{
    return testSolutionName;
}

-(void)setTestSolutionName:(NSString *)solutionName
{
    testSolutionName = solutionName;
}

-(void)setTestIssuerKey:(NSString *)issuerKey
{
    testSolutionKey = issuerKey;
}

-(NSURL*)getCurrentTestEndPoint
{
    NSArray* tokens = [targetEnvironment componentsSeparatedByString:@"-"] ;
    NSString* endPoint = [NSString stringWithFormat:@"https://%@.servicebus.%@.windows-int.net/",testSolutionName,tokens[0]];
    //return endPoint;
    return [NSURL URLWithString:endPoint];
}

-(NSURL*)getCurrentTestUrl
{
    NSArray* tokens = [targetEnvironment componentsSeparatedByString:@"-"] ;
    NSString* endPoint = [NSString stringWithFormat:@"https://%@.servicebus.%@.windows-int.net/",testSolutionName,tokens[0]];
    return [NSURL URLWithString:endPoint];
}

-(NSURL*)getCurrentStsEndPoint
{
    NSString* stsEndPoint = [NSString stringWithFormat:@"StsEndPoint=https://%@-sb.accesscontrol.windows-ppe.net",testSolutionName];
    //return stsEndPoint;
    return [NSURL URLWithString:stsEndPoint];
}

-(void)setDefaultHubName:(NSString *)hubName
{
    deafultNotificationHub = hubName;
}

- (void) SetInitParams
{
    //Not always required to configure
    //Unless testing special cases
    deafultNotificationHub = @"iosSdkTesting";
    connType               = @"SAS";
    notificationHubWithWrongConnStr = @"iossdktesting1";
    notificationHubWithSpecialTokens = @"iossdktesting2";
    specialTokenValue = @"nsEDOgLthiSalJr80DYMDWD9fN2jo6VE;;";
    testSasKey   = @"d+EqhqCpnyTvgQeh3ArXHd2yKFa8bD/b1mh5JZYnZ50="; //listenAccessSecret
}

// TBD read from test configuration
/*
 path = [[NSBundle mainBundle] pathForResource:@"IguazuIosSdkTests-Info" ofType:@"plist"];
 settings = [[NSDictionary alloc] initWithContentsOfFile:path];
 
 NSBundle* bundle = [NSBundle mainBundle];
 
 NSString* val = [bundle objectForInfoDictionaryKey:@"Namespace"];
 */


@end

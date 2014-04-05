#import <Foundation/Foundation.h>

extern const int DEFAULT_REG_EXPIRY_IN_DAYS;

@interface TestConfig : NSObject
{
    NSString* targetEnvironment;
    NSString* testSolutionName;
    NSString* testSolutionKey;
    NSString* testSasKey;
    NSString* deafultNotificationHub;
    
    NSString* notificationHubWithWrongConnStr;
    
    NSString* notificationHubWithSpecialTokens;
    NSString* specialTokenValue;
    
    NSString* connType;
}

//-(void)setTargetEnvironment : (NSString*)targetEnvironment;
//-(void)setTestSolutionName : (NSString*)testSolutionName;
//-(void)setTestSoluttionKey : (NSString*)testSolutionKey;
-(void)setConnType : (NSString*)connType;

-(NSString*)TargetEnvironment;
-(NSString*)TestSolutionName;
-(NSString*)TestSolutionKey;
-(NSString*)TestSasKey;
-(NSString*)TestSpecialToken;
-(NSString*)DefaultNotificationHub;
-(NSString*)NotificationHubWithWrongConnStr;
-(NSString*)NotificationHubWithSpecialTokens;
-(NSString*)ConnType;

-(NSURL*)getCurrentTestEndPoint;
-(NSURL*)getCurrentStsEndPoint;
-(NSURL*)getCurrentTestUrl;

-(void)setTestSolutionName:(NSString *)solutionName;
-(void)setTestIssuerKey:(NSString *)issuerKey;
-(void)setDefaultHubName:(NSString *)hubName;

@end

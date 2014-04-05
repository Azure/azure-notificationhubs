#import <Foundation/Foundation.h>
#import <GHUnitIOS/GHUnit.h>
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import "TestHelper.h"
#import "TestConfig.h"
#import "AppDelegate.h"
#import "Registration.h"
#import "TemplateRegistration.h"
#import "RegistrationRetriever.h"
#import "NHSolutionMgr.h"

@interface IosSdkTests : GHTestCase
{
    SBNotificationHub*    notificationHub;
    NSString*             currentConnectString;
    RegistrationRetriever*    retriever;
    Registration*         lastRegistrationInfo;
    NSData*               currentDeviceTokenData;
    NSString*             currentDeviceToken;
    TestConfig*           testConfig;
    NHSolutionMgrHelper*  nhSolutionManager;
}

-(SBNotificationHub*)NotificationHub;
-(RegistrationRetriever*)Retriever;
-(Registration*)LastRegistrationInfo;
-(NHSolutionMgrHelper *) NHSolutionManager;

-(void)setNotificationHub:(SBNotificationHub*)notificationHub;
-(void)setLastRegistrationInfo:(Registration*)registrationInfo;

-(Registration*)createNativeRegistrationWithTags:(BOOL)sync;
- (void)createTemplateRegistrationWithNameAndVerify : (BOOL)sync;
- (void)createNativeRegistrationWithEmptyLocalStorage : (BOOL)sync;
- (void)createTemplateRegistrationWithEmptyLocalStorage : (BOOL)sync;
- (void)retrieveAllRegistrationsAndVerify : (BOOL)sync;
-(void)deleteRegistrationWithNameAndVerify : (BOOL)sync;
-(void)deleteNativeRegistrationAndVerify : (BOOL)sync;
- (void)deleteAllRegistrationsAndVerify : (BOOL)sync;
-(Registration*)createNativeAndTemplateRegistrations:(BOOL)sync;
-(Registration*)createRegistrationWithDifferentDeviceToken:(BOOL)sync;
-(Registration*)createRegistrationOnDifferentNotificationHub:(BOOL)sync;
-(void)DeleteAllAndThenNativeAndTemplateRegistration:(BOOL)sync;
-(void)DeleteAllRegistrationWithEmptyLocalStorage:(BOOL)sync;

-(void)verify : (Registration*)regInfo;
-(void)setLastRegistrationInfo:(NSString*)regName deviceToken : (NSString*)deviceToken tags : (NSSet*)tags;
-(void)setLastRegistrationInfo:(NSString*)regName deviceToken : (NSString*)deviceToken tags : (NSSet*)tags
                 bodyTemplate : (NSString*)bodyTemplate expiry : (NSString*)expiry;
-(void)resetLastRgistrationInfo;

@end

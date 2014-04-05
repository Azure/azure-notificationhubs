#import "SyncRegMgmtTests.h"

@implementation SyncRegMgmtTests


// - (BOOL) createDefaultRegistrationWithTags:(NSSet*)tags error:(NSError**)error;
//
-(void)testCreateDefaultRegistration
{
    Registration* regInfo = [self createNativeRegistrationWithTags:TRUE];
    [self verify:regInfo];
    GHTestLog(@"SyncRegMgmtTests::testCreateDefaultRegistration SUCCESS");
}

//- (BOOL) createTemplateRegistrationWithName:(NSString*)name jsonBodyTemplate:(NSString*)bodyTemplate expiryTemplate:(NSString*)expiryTemplate tags:(NSSet*)tags error:(NSError**)error;
//
-(void)testCreateTemplateRegistrationWithName
{
    [self createTemplateRegistrationWithNameAndVerify:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testCreateTemplateRegistrationWithName SUCCESS");
}

-(void)testCreateDefaultRegistrationWithEmptyLocalStorage
{
    [self createNativeRegistrationWithEmptyLocalStorage:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testCreateDefaultRegistrationWithEmptyLocalStorage SUCCESS");
}

-(void)testCreateTemplateRegistrationWithEmptyLocalStorage
{
    [self createTemplateRegistrationWithEmptyLocalStorage:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testCreateTemplateRegistrationWithWithEmptyLocalStorage SUCCESS");
}

//- (BOOL) deleteDefaultRegistrationWithError:(NSError**)error;
-(void)testDeleteDefaultRegistrationWithError
{
    [self deleteAllRegistrationsAndVerify:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteDefaultRegistrationWithError SUCCESS");
}

//- (BOOL) deleteRegistrationWithName:(NSString*)name error:(NSError**)error;
-(void)testDeleteRegistrationWithName
{
    [self deleteRegistrationWithNameAndVerify:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteRegistrationWithName SUCCESS");
}

//- (BOOL) deleteAllRegistrationsWithError:(NSError**)error;
-(void)testDeleteAllRegistrations
{
    [self deleteAllRegistrationsAndVerify:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllRegistrations SUCCESS");
}

//Complex SDK scenarios

-(void)testNativeAndTemplateRegistrations
{
    [self createNativeAndTemplateRegistrations:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testNativeAndTemplateRegistrations SUCCESS");
}

-(void)testCreateRegistrationsWithDifferentDeviceToken
{
    [self createRegistrationWithDifferentDeviceToken:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testCreateRegistrationsWithDifferentDeviceToken SUCCESS");
}

-(void)testCreateRegistrationsWithDifferentNotificationHub
{
    [self createRegistrationOnDifferentNotificationHub:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testCreateRegistrationsWithDifferentNotificationHub SUCCESS");
}

-(void)testDeleteAllAndThenCreateRegistrations
{
    [self DeleteAllAndThenNativeAndTemplateRegistration:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllAndThenCreateRegistrations SUCCESS");
}

-(void)testDeleteAllRegistrationsWithEmptyLocalStorage
{
    [self DeleteAllRegistrationWithEmptyLocalStorage:TRUE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllRegistrationsWithEmptyLocalStorage SUCCESS");
    
}

@end

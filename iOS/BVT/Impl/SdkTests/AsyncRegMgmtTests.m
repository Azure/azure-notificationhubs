#import "AsyncRegMgmtTests.h"

@implementation AsyncRegMgmtTests


-(void)testRegisterNative
{
    Registration* regInfo = [self createNativeRegistrationWithTags:FALSE];
    [self verify:regInfo];
    GHTestLog(@"SyncRegMgmtTests::testCreateDefaultRegistration SUCCESS");
}

-(void)testRegisterTemplate
{
    [self createTemplateRegistrationWithNameAndVerify:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testCreateTemplateRegistrationWithName SUCCESS");
}

-(void)testRegisterNativeWithEmptyLocalStorage
{
    [self createNativeRegistrationWithEmptyLocalStorage:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testCreateDefaultRegistrationWithEmptyLocalStorage SUCCESS");
}

-(void)testRegisterTemplateWithEmptyLocalStorage
{
    [self createTemplateRegistrationWithEmptyLocalStorage:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testCreateTemplateRegistrationWithWithEmptyLocalStorage SUCCESS");
}

-(void)testUnregisterNative
{
    [self deleteNativeRegistrationAndVerify:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteDefaultRegistrationWithError SUCCESS");
}


//- (void) deleteRegistrationWithName:(NSString*)name completion:(void (^)(NSError* error))completion;
-(void)testUnregisterTemplate
{
    [self deleteRegistrationWithNameAndVerify:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteRegistrationWithName SUCCESS");
}

//- (void) deleteAllRegistrationsWithCompletion:(void (^)(NSError* error))completion;
-(void)testUnregisterAll
{
    [self deleteAllRegistrationsAndVerify:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllRegistrations SUCCESS");
}

//Complex SDK scenarios

-(void)testNativeAndTemplateRegistrations
{
    [self createNativeAndTemplateRegistrations:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testNativeAndTemplateRegistrations SUCCESS");
}

-(void)testCreateRegistrationsWithDifferentDeviceToken
{
    [self createRegistrationWithDifferentDeviceToken:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testCreateRegistrationsWithDifferentDeviceToken SUCCESS");
}

-(void)testCreateRegistrationsWithDifferentNotificationHub
{
    [self createRegistrationOnDifferentNotificationHub:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testCreateRegistrationsWithDifferentNotificationHub SUCCESS");
}

-(void)testDeleteAllAndThenCreateRegistrations
{
    [self DeleteAllAndThenNativeAndTemplateRegistration:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllAndThenCreateRegistrations SUCCESS");
}

-(void)testDeleteAllRegistrationsWithEmptyLocalStorage
{
    [self DeleteAllRegistrationWithEmptyLocalStorage:FALSE];
    GHTestLog(@"SyncRegMgmtTests::testDeleteAllRegistrationsWithEmptyLocalStorage SUCCESS");
    
}

@end

#import "IosSdkTests.h"

@implementation IosSdkTests

NSString* _storageVersion = @"v1.0.0";

// Getters
-(SBNotificationHub*)NotificationHub
{
    return notificationHub;
}

-(Registration*)LastRegistrationInfo
{
    return lastRegistrationInfo;
}

-(RegistrationRetriever*)Retriever
{
    return retriever;
}

-(NHSolutionMgrHelper *)NHSolutionManager
{
    return nhSolutionManager;
}

// Setters
-(void)setNotificationHub:(SBNotificationHub*)newNotificationHub
{
    notificationHub = newNotificationHub;
}

-(void)setLastRegistrationInfo:(Registration*)registrationInfo
{
    lastRegistrationInfo = registrationInfo;
}


-(void)setUpClass
{
    testConfig = [[TestConfig alloc]init];
    nhSolutionManager = [[NHSolutionMgrHelper alloc]init];
    
    //Checkout a solution from the requested environemnt
    [nhSolutionManager CheckoutSolution:[testConfig TargetEnvironment]];
    
    
    [testConfig setTestSolutionName:[nhSolutionManager m_serviceNamespace]];
    [testConfig setTestIssuerKey:[nhSolutionManager m_issuerKey]];
    
    [testConfig setDefaultHubName:[NSString stringWithFormat:@"%@-%@", [testConfig DefaultNotificationHub],[TestHelper getRandomName]]];
    
    //Create Notification Hub on server
    [nhSolutionManager CreateNotificationHubOnServer:[testConfig DefaultNotificationHub] defaultSasKey:[testConfig TestSasKey]];
}

-(void)setUp
{
    //[TestHelper clearLocalStorageWithNotificationPath:[testConfig DefaultNotificationHub]];

    // connnection str
    NSString* connStr ;
    if ([[testConfig ConnType] isEqualToString:@"ACS"]) {
        connStr = [SBConnectionString stringWithEndpoint:[testConfig getCurrentTestEndPoint] issuer:@"owner" issuerSecret:[testConfig TestSolutionKey]];
        
        connStr = [NSString stringWithFormat:@"%@;%@", connStr,[testConfig getCurrentStsEndPoint]];
    } else if([[testConfig ConnType] isEqualToString:@"SAS"]){
        connStr = [SBConnectionString stringWithEndpoint:[testConfig getCurrentTestEndPoint] listenAccessSecret:[testConfig TestSasKey]];
    }
    
    currentConnectString = connStr;
    NSLog(@"Connection String = %@",connStr);
        
    // create notificationHub
    notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connStr notificationHubPath:[testConfig DefaultNotificationHub]];
    // setup deviceToken
    currentDeviceTokenData = [[TestHelper getRandomDeviceToken] dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Device Token %@",currentDeviceTokenData);
    currentDeviceToken = [TestHelper getDeviceTokenStringFromData:currentDeviceTokenData];
    
//    NSError *error;
//    [notificationHub unregisterAllWithDeviceToken:currentDeviceTokenData error:&error];
//    NSLog(@"unregisterAllWithDeviceToken error %@",[error localizedDescription]);
    
    NSLog(@"Refresh registartion Success");
    lastRegistrationInfo = nil;
    
    retriever = [[RegistrationRetriever alloc] initWithConnectionString:connStr notificationHubPath:[testConfig DefaultNotificationHub]];
}

-(void)tearDown
{
    [nhSolutionManager CheckinSolution];
}

// Helper
//  Wrppaer functions over SDK
//  Covers both sync and async version with flag 'sync'
-(Registration*)createNativeRegistrationWithTags:(BOOL)sync
{    
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSError* error;
    
    if (sync)
    {
        // Create registartion with tags
        //
        BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:nil
                                                                   error:&error];
        GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                              error:&error];
        GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName again to update success");
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:nil completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags again error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
   
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    GHAssertTrue(regs.count == 1, @"There are more than one registrations.");
    [self setLastRegistrationInfo:[Registration Name] deviceToken:currentDeviceToken tags:tags];
    return regs[0];
}

- (void)createTemplateRegistrationWithNameAndVerify : (BOOL)sync
{
    NSError* error;
    NSSet* tags = [NSSet setWithArray:@[@"testtag1",@"testtag2"]];
    
    NSArray* notificationTemplates = [[NSArray alloc ]initWithObjects:
                                      // alert
                                      @"{\"aps\" : {\"alert\" : \"$(myAlert)\"}}",
                                      
                                      // badge
                                      @"{\"aps\" : {\"badge\" : \"#(bagdeNumber)\"}}",
                                      
                                      // alert + sound
                                      @"{\"aps\" : {\"alert\" : \"$(myAlert)\",\"sound\" : \"$(myTestSound)\"}}",
                                      
                                      // badge + sound
                                      @"{\"aps\" : {\"badge\" : 9,\"sound\" : \"bingbong.aiff\"}}",
                                      
                                      // custom
                                      @"{\"aps\" : {\"alert\" : \"Test Alert.\",\"badge\" : 9,\"sound\" : \"bingbong.aiff\"},\"acme1\" : \"bar\",\"acme2\" : 42}",
                                      
                                      // action-loc-key
                                      @"{\"aps\": {\"alert\": {\"loc-key\" : \"GAME_PLAY_REQUEST_FORMAT\", \"loc-args\" : [\"$(myArrayArgProperty)\"]}}}",
                                      
                                      nil ];
    
    int regId = 0;
    for (NSString* notificationTemplate in notificationTemplates) {
        NSString* regName = [[[NSNumber numberWithInt:regId] stringValue] stringByAppendingString:@"_regId"];
        NSLog(@"Template : %@",notificationTemplate);
        
        regId++;
        
        if (sync) {
            BOOL createReturn = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:notificationTemplate expiryTemplate:@"$(expiryProperty)" tags:nil error:&error];
            
            GHAssertTrue(createReturn, @"Failed to create registation %@",[error localizedDescription]);
            
            createReturn = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:notificationTemplate expiryTemplate:@"$(expiryProperty)" tags:tags error:&error];
            
            GHAssertTrue(createReturn, @"Failed to create registation again %@",[error localizedDescription]);
        } else {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:notificationTemplate expiryTemplate:@"$(expiryProperty)" tags:nil  completion:^(NSError* error){
                NSLog(@"createTemplateRegistrationWithName error %@",[error localizedDescription]);
                GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
                dispatch_semaphore_signal(semaphore);
            }];
            while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
            }
            
            semaphore = dispatch_semaphore_create(0);
            [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:notificationTemplate expiryTemplate:@"$(expiryProperty)" tags:tags  completion:^(NSError* error){
                NSLog(@"createTemplateRegistrationWithName again error %@",[error localizedDescription]);
                GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
                dispatch_semaphore_signal(semaphore);
            }];
            while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
            }
        }

        NSLog(@"createRegistrationWithName success");
        
        [self setLastRegistrationInfo:regName deviceToken:currentDeviceToken tags:tags bodyTemplate:notificationTemplate expiry:@"$(expiryProperty)"];
        
        NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
        GHAssertTrue(regs.count == regId, @"There # of registartions is not correct.");
        
        TemplateRegistration* checkReg;
        for (TemplateRegistration* reg in regs) {
            
            if( [reg.templateName isEqualToString:regName]  )
            {
                checkReg = reg;
                break;
            }
        }
        
        GHAssertNotNil(checkReg, @"retrieveRegistrationWithName returned NULL");
        [self verify:checkReg];
    }
    
    NSLog(@"createTemplateRegistrationWithNameAndVerify Success");
}

-(void)createNativeRegistrationWithEmptyLocalStorage:(BOOL)sync
{
    // create one registration
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSError* error;
    
    if (sync)
    {
        // Create registartion with tags
        //
        BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:nil
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:nil completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // clear local storage
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-registrations",[testConfig DefaultNotificationHub]]];
    [defaults synchronize];
    
    // recreate notificationHub instance to reload from localstorage
    SBNotificationHub* newNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:self->currentConnectString notificationHubPath:[testConfig DefaultNotificationHub]];
    
    // make sure version key is not there
    NSString* version = [defaults objectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    GHAssertTrue(version == nil, @"The version key should not be there.");
    
    // call create again,
    // #1: it should call retrieveAllRegistrations first to update local storage
    // #2: Since the localCache has the registrations after #1, it should only update registrations instead of create.
    tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2", @"testTag3"]];
    if (sync)
    {
        BOOL retVal = [newNotificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                                  error:&error];
        GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [newNotificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // make sure version key is updated
    version = [defaults objectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    GHAssertTrue([version isEqualToString:_storageVersion], @"The version key should be set.");
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    GHAssertTrue(regs.count == 1, @"There are more than one registrations.");
    Registration* retrieveReg = regs[0];
    GHAssertTrue([[retrieveReg tags] count] == 3, @"Tags should have three elements");
}

-(void)createTemplateRegistrationWithEmptyLocalStorage:(BOOL)sync
{
    // create one registration
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSError* error;
    NSString* bodyTemplate = @"{\"aps\" : {\"alert\" : \"$(myAlert)\"}}";
    NSString* regName = @"templateEmptyLocalStorage";
    if (sync)
    {
        BOOL createReturn = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:bodyTemplate expiryTemplate:@"$(expiryProperty)" tags:nil error:&error];
        
        GHAssertTrue(createReturn, @"Failed to create registation %@",[error localizedDescription]);
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:bodyTemplate expiryTemplate:@"$(expiryProperty)" tags:nil  completion:^(NSError* error){
            NSLog(@"createTemplateRegistrationWithName error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // clear local storage
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-registrations",[testConfig DefaultNotificationHub]]];
    [defaults synchronize];
    
    // recreate notificationHub instance to reload from localstorage
    SBNotificationHub* newNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:self->currentConnectString notificationHubPath:[testConfig DefaultNotificationHub]];
    
    // make sure version key is not there
    NSString* version = [defaults objectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    GHAssertTrue(version == nil, @"The version key should not be there.");
    
    // call create again,
    // #1: it should call retrieveAllRegistrations first to update local storage
    // #2: Since the localCache has the registrations after #1, it should only update registrations instead of create.
    tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2", @"testTag3"]];
    if (sync)
    {
        BOOL createReturn = [newNotificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:bodyTemplate expiryTemplate:@"$(expiryProperty)" tags:tags error:&error];
        
        GHAssertTrue(createReturn, @"Failed to create registation %@",[error localizedDescription]);
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [newNotificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:regName jsonBodyTemplate:bodyTemplate expiryTemplate:@"$(expiryProperty)" tags:tags  completion:^(NSError* error){
            NSLog(@"createTemplateRegistrationWithName error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // make sure version key is updated
    version = [defaults objectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    GHAssertTrue([version isEqualToString:_storageVersion], @"The version key should be set.");
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    GHAssertTrue(regs.count == 1, @"There are more than one registrations.");
    Registration* retrieveReg = regs[0];
    GHAssertTrue([[retrieveReg tags] count] == 3, @"Tags should have three elements");
}

-(void)deleteRegistrationWithNameAndVerify : (BOOL)sync
{
    NSError *error;
    NSString* alert = @"{\"aps\" : {\"alert\" : \"$(myAlert)\"}}";
    
    BOOL retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"regName" jsonBodyTemplate:alert expiryTemplate:@"$(expiryProperty)" tags:nil error:&error];
    
    GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
    NSLog(@"createRegistrationWithName success");
    
    if (sync) {
        retVal = [notificationHub unregisterTemplateWithName:@"regName" error:&error];
        GHAssertTrue(retVal, @"deleteRegistrationWithName failed @",[error localizedDescription]);
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub unregisterTemplateWithName:@"regName" completion:^(NSError* error){
            NSLog(@"retrieveAllRegistrationsWithCompletion error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }    

    int count = [[retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error] count];
    GHAssertTrue( count == 0, @"Registration still exists.");
    NSLog(@"deleteRegistrationWithName Success");
}

-(void)deleteNativeRegistrationAndVerify : (BOOL)sync
{
    NSError *error;
    BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:nil
                                                               error:&error];
    
    GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
    NSLog(@"createRegistrationWithName success");    

    if (sync) {
        retVal = [notificationHub unregisterNativeWithError: &error];
        GHAssertTrue(retVal, @"unregisterNative failed @",[error localizedDescription]);

    }
    else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub unregisterNativeWithCompletion:^(NSError* error){
            NSLog(@"unregisterNative error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
        NSLog(@"unregisterNative Success");
    
    int count = [[retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error] count];
    GHAssertTrue( count == 0, @"Registration exists.");
    NSLog(@"deleteDefaultRegistration Success");
}

- (void)deleteAllRegistrationsAndVerify : (BOOL)sync
{
    NSError *error;
    
    NSSet* tags = [NSSet setWithArray:@[@"testtag1",@"testtag2"]];
    
    // Create one default registration
    BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                               error:&error];
    
    GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
    NSLog(@"createDefaultRegistrationWithTags success");
    
    // Create registartion with name
    //
    NSString* alert = @"{\"aps\" : {\"alert\" : \"$(myAlert)\"}}";
    
    retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"testRegName" jsonBodyTemplate:alert expiryTemplate:@"$(expiryProperty)" tags:tags error:&error];

    GHAssertTrue(retVal, @"Failed to create registation %@",[error localizedDescription]);
    NSLog(@"createRegistrationWithName success");
    if (sync) {
        BOOL deleteAllReturn = [notificationHub unregisterAllWithDeviceToken:currentDeviceTokenData error:&error];
        GHAssertTrue(deleteAllReturn, @"deleteAllRegistrations failed @",[error localizedDescription]);
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub unregisterAllWithDeviceToken:currentDeviceTokenData completion:^(NSError* error){
            NSLog(@"deleteAllRegistrationsWithCompletion error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    NSLog(@"Delete All registartions Success");
    
    int count = [[retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error] count];
    GHAssertTrue( count == 0, @"Registration exists.");
    NSLog(@"testDeleteAllRegistrations Success");
    
}

-(Registration*)createNativeAndTemplateRegistrations:(BOOL)sync
{
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSString* customTemplateBody = @"{\"aps\" : {\"alert\" : \"$(myAlert)\", \"sound\" : \"$(mySound)\"},\"customProperty\" : \"$(customProp)\"}";
    NSError* error;
    
    if (sync)
    {
        // Create Native registartion with tags
        //
        BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation %@",[error localizedDescription]);
    }
    else
    {
        dispatch_semaphore_t  semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags again error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        } 
    }
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    GHAssertTrue(regs.count == 2, @"Registrations count mismatch. Expected: 2");
    [self setLastRegistrationInfo:[Registration Name] deviceToken:currentDeviceToken tags:tags];
    return regs[0];
}

-(Registration*)createRegistrationWithDifferentDeviceToken:(BOOL)sync
{
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSString* customTemplateBody = @"{\"aps\" : {\"alert\" : \"$(myAlert)\", \"sound\" : \"$(mySound)\"},\"customProperty\" : \"$(customProp)\"}";
    NSData* newDeviceToken = [[TestHelper getRandomDeviceToken] dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    
    if (sync)
    {
        // Create Native registartion with tags
        //
        BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation %@",[error localizedDescription]);
        
        //Now try to register with a different device token
        //All registration calls should succeed
        
        retVal = [notificationHub registerNativeWithDeviceToken:newDeviceToken tags:tags
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation with new device token %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [notificationHub registerTemplateWithDeviceToken:newDeviceToken name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation with new device token %@",[error localizedDescription]);
        
        
    }
    else
    {
        dispatch_semaphore_t  semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags again error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Now try to register with a different device token
        //All registration calls should succeed
        
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:newDeviceToken tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags with new device token error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:newDeviceToken name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error with new devie token %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:newDeviceToken error:&error];
    GHAssertTrue(regs.count == 2, @"Registrations count mismatch. Expected: 2");
    return regs[0];
}

-(Registration*)createRegistrationOnDifferentNotificationHub:(BOOL)sync
{
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSString* customTemplateBody = @"{\"aps\" : {\"alert\" : \"$(myAlert)\", \"sound\" : \"$(mySound)\"},\"customProperty\" : \"$(customProp)\"}";
    
    NSError* error;
    
    if (sync)
    {
        // Create Native registartion with tags
        //
        BOOL retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation %@",[error localizedDescription]);
        
        //Now try to register on a different Notification hub
        NSString *hubName = [NSString stringWithFormat:@"newHubSync-%@", [TestHelper getRandomName]];
        
        //Create Notification hub on server too
        [nhSolutionManager CreateNotificationHubOnServer:hubName defaultSasKey:[testConfig TestSasKey]];
        
        NSLog(@"Starting the sleep for 5 seconds");
        [NSThread sleepForTimeInterval:.5];
        
        // recreate notificationHub instance to reload from localstorage
        SBNotificationHub* newNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:self->currentConnectString notificationHubPath:hubName];
        
        NSLog(@"Going to register native registration now");
                
        retVal = [newNotificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                          error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation with new notification hub %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [newNotificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation with new device token %@",[error localizedDescription]);
        
        
    }
    else
    {
        dispatch_semaphore_t  semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags again error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Now try to register on a different Notification hub
        NSString *newNotificationHubName = [NSString stringWithFormat:@"newHubAsync-%@", [TestHelper getRandomName]];
        
        //Create Notification hub on server too
        [nhSolutionManager CreateNotificationHubOnServer:newNotificationHubName defaultSasKey:[testConfig TestSasKey]];
        
        // recreate notificationHub instance to reload from localstorage
        SBNotificationHub* newNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:self->currentConnectString notificationHubPath:newNotificationHubName];
        
        
        semaphore = dispatch_semaphore_create(0);
        [newNotificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags with new device token error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [newNotificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error with new devie token %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    [self setLastRegistrationInfo:[Registration Name] deviceToken:currentDeviceToken tags:tags];
    
    return regs[0];
}

-(void)DeleteAllAndThenNativeAndTemplateRegistration:(BOOL)sync
{
    NSSet* tags = [NSSet setWithArray:@[@"TESTtag1",@"testtag2"]];
    NSString* customTemplateBody = @"{\"aps\" : {\"alert\" : \"$(myAlert)\", \"sound\" : \"$(mySound)\"},\"customProperty\" : \"$(customProp)\"}";
    NSError* error;
    
    if (sync)
    {
        //Delete All registrations
        BOOL retVal = [notificationHub unregisterAllWithDeviceToken:currentDeviceTokenData error:&error];
        GHAssertTrue(retVal, @"Failed to unregister all registrations %@",[error localizedDescription]);
        NSLog(@"unregisterAllWithDeviceToken success");
        
        // Create Native registartion with tags
        //
        retVal = [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags
                                                               error:&error];
        GHAssertTrue(retVal, @"Failed to create Native registation %@",[error localizedDescription]);
        NSLog(@"createRegistrationWithName success");
        
        //Create Template registration with tags
        retVal = [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags error:&error];
        GHAssertTrue(retVal, @"Failed to create Template registation %@",[error localizedDescription]);
    }
    else
    {
        //UnregisterAll registrations
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [notificationHub unregisterAllWithDeviceToken:currentDeviceTokenData completion:^(NSError* error){
            NSLog(@"deleteAllRegistrationsWithCompletion error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerNativeWithDeviceToken:currentDeviceTokenData tags:tags completion:^(NSError* error){
            NSLog(@"createDefaultRegistrationWithTags again error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
        
        //Create Template Registration
        semaphore = dispatch_semaphore_create(0);
        [notificationHub registerTemplateWithDeviceToken:currentDeviceTokenData name:@"TemplateTest" jsonBodyTemplate:customTemplateBody expiryTemplate:nil tags:tags completion:^(NSError* error){
            NSLog(@"registerTemplateWithDeviceToken error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %a , %a",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
    
    // Get the registartion and check with expected
    NSArray* regs = [retriever retrieveAllWithDeviceToken:currentDeviceTokenData error:&error];
    GHAssertTrue(regs.count == 2, @"Registrations count mismatch. Expected: 2");
    [self setLastRegistrationInfo:[Registration Name] deviceToken:currentDeviceToken tags:tags];
}

//Bug#752707 - Regression test case
-(void)DeleteAllRegistrationWithEmptyLocalStorage:(BOOL)sync
{
    NSError* error;
    
    // clear local storage
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@-registrations",[testConfig DefaultNotificationHub]]];
    [defaults synchronize];
    
    // recreate notificationHub instance to reload from localstorage
    SBNotificationHub* newNotificationHub = [[SBNotificationHub alloc] initWithConnectionString:self->currentConnectString notificationHubPath:[testConfig DefaultNotificationHub]];
    
    // make sure version key is not there
    NSString* version = [defaults objectForKey:[NSString stringWithFormat:@"%@-version",[testConfig DefaultNotificationHub]]];
    GHAssertTrue(version == nil, @"The version key should not be there.");
    
    if (sync)
    {
        //Delete All registrations
        BOOL retVal = [newNotificationHub unregisterAllWithDeviceToken:currentDeviceTokenData error:&error];
        GHAssertTrue(retVal, @"Failed to unregister all registrations %@",[error localizedDescription]);
        NSLog(@"unregisterAllWithDeviceToken success");
        
    }
    else
    {
        //UnregisterAll registrations
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [newNotificationHub unregisterAllWithDeviceToken:currentDeviceTokenData completion:^(NSError* error){
            NSLog(@"deleteAllRegistrationsWithCompletion error %@",[error localizedDescription]);
            GHAssertNil(error, @"Error : %@ , %@",[error localizedDescription],[error localizedFailureReason]);
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        }
    }
}

// Helper methods for functions in this class
//

-(void)verify:(Registration *)regInfo
{
    NSString* lastName = [TestHelper nameOfRegistration:lastRegistrationInfo];
    NSString* name = [TestHelper nameOfRegistration:regInfo];

    NSLog(@"Registration Name :: Expected = %@ , Actual = %@",lastName,name);
    GHAssertTrue([lastName isEqualToString:name], @"Mismatch in registration name , Expected = %@ , Actual = %@",lastName,name);
    
    NSLog(@"Device Token :: Expected = %@ , Actual = %@",[lastRegistrationInfo deviceToken],[regInfo deviceToken]);
    GHAssertTrue([[lastRegistrationInfo deviceToken] isEqualToString:[regInfo deviceToken]], @"Mismatch in device token , Expected = %@ , Actual = %@",[lastRegistrationInfo deviceToken],[regInfo deviceToken]);
    
    GHAssertTrue([[lastRegistrationInfo tags] isEqualToSet:[regInfo tags]], @"Tags mismatch");
    
    double actualMinutesToExpiry = [TestHelper getTimeInMinutesTillDate:[regInfo expiresAt]];
    double expectedMinutesToExpiry = [TestHelper getTimeInMinutesTillDate:[lastRegistrationInfo expiresAt]];
    double delta = fabs(actualMinutesToExpiry - expectedMinutesToExpiry);
    
    NSLog(@"Minute To Expire:: Expected = %f , Actual = %f",expectedMinutesToExpiry,actualMinutesToExpiry);
    GHAssertTrue(delta < 10, @"Expires at not in range , Expected = %f , Actual = %f",expectedMinutesToExpiry,actualMinutesToExpiry);
    
    if([regInfo isKindOfClass:[TemplateRegistration class]])
    {
        TemplateRegistration* templReg = (TemplateRegistration*)regInfo;
        NSLog(@"Body Template :: Expected = %@ , Actual = %@",[(TemplateRegistration*)lastRegistrationInfo bodyTemplate],[templReg bodyTemplate]);
        GHAssertTrue([[templReg bodyTemplate] isEqualToString:[(TemplateRegistration*)lastRegistrationInfo bodyTemplate]], @"Body template mismatch , Expected = %@ , Actual = %@",[(TemplateRegistration*)lastRegistrationInfo bodyTemplate],[templReg bodyTemplate]);
        
        NSLog(@"Expiry Template :: Expected = %@ , Actual = %@",[(TemplateRegistration*)lastRegistrationInfo expiry],[templReg expiry]);
        GHAssertTrue([[templReg expiry] isEqualToString:[(TemplateRegistration*)lastRegistrationInfo expiry]], @"Expiry template mismatch , Expected = %@ , Actual = %@",[(TemplateRegistration*)lastRegistrationInfo expiry],[templReg expiry]);
    }
}


-(void)setLastRegistrationInfo:(NSString*)regName deviceToken : (NSString*)deviceToken tags : (NSSet*)tags
{
    lastRegistrationInfo = [[Registration alloc] init];
    [lastRegistrationInfo setTags:tags];
    [lastRegistrationInfo setDeviceToken:deviceToken];
    [lastRegistrationInfo setExpiresAt:[[NSDate date] dateByAddingTimeInterval:DEFAULT_REG_EXPIRY_IN_DAYS * 24 * 60 * 60] ];
}

-(void)setLastRegistrationInfo:(NSString*)regName deviceToken : (NSString*)deviceToken tags : (NSSet*)tags
bodyTemplate : (NSString*)bodyTemplate expiry : (NSString*)expiry
{
    lastRegistrationInfo = [[TemplateRegistration alloc] init];
    [lastRegistrationInfo setTags:tags];
    [lastRegistrationInfo setDeviceToken:deviceToken];
    [lastRegistrationInfo setExpiresAt:[[NSDate date] dateByAddingTimeInterval:DEFAULT_REG_EXPIRY_IN_DAYS * 24 * 60 * 60] ];
    [((TemplateRegistration*)lastRegistrationInfo) setBodyTemplate:bodyTemplate];
    [((TemplateRegistration*)lastRegistrationInfo) setExpiry:expiry];
    [((TemplateRegistration*)lastRegistrationInfo) setTemplateName:regName];
}

-(void)resetLastRgistrationInfo
{
    [lastRegistrationInfo setTags:nil];
    [lastRegistrationInfo setDeviceToken:nil];
    [lastRegistrationInfo setExpiresAt:nil ];
    
    if( [lastRegistrationInfo class] == [TemplateRegistration class])
    {
         [((TemplateRegistration*)lastRegistrationInfo) setTemplateName:nil];
    }    
}

@end

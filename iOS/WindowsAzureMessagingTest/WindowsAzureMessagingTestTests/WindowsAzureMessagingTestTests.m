//
//  WindowsAzureMessagingTestTests.m
//  WindowsAzureMessagingTestTests
//
//  Created by Vinod Shanbhag on 1/17/13.
//  Copyright (c) 2013 Azure ServiceBus. All rights reserved.
//

#import "WindowsAzureMessagingTestTests.h"
#import "WindowsAzureMessaging.h"
#import "SBURLConnection.h"
#import "TestHelper.h"
#import "SBLocalStorage.h"

@implementation WindowsAzureMessagingTestTests

NSString* path = @"PushTest";
NSString *connectionStringSAS;
NSString *connectionStringACS;
BOOL httpRequestFinished;
BOOL tokenRequestFinished;
BOOL refreshRequestFinished;
BOOL createRegistrationIdRequestFinished;

NSString* emptyRegistrations = @"<feed xmlns=\"http://www.w3.org/2005/Atom\"><title type=\"text\">Registrations</title><id>https://testuser2-int7sn1007-1-8e72f-36.servicebus.int7.windows-int.net/CreateWindowsRegistrationWithDifferentLocalStorageVersion-NotificationHub-rL9GkO/Registrations/?$filter=channelUri%20eq%20'https%3A%2F%2Ftest.notify.windows.com%2F%3Ftoken%3DrFEXKubeJZrLYYtgIx5OFH62nimatX1U'&amp;api-version=2013-04</id><updated>2013-06-06T17:12:27Z</updated><link rel=\"self\" href=\"https://testuser2-int7sn1007-1-8e72f-36.servicebus.int7.windows-int.net/CreateWindowsRegistrationWithDifferentLocalStorageVersion-NotificationHub-rL9GkO/Registrations/?$filter=channelUri%20eq%20'https%3A%2F%2Ftest.notify.windows.com%2F%3Ftoken%3DrFEXKubeJZrLYYtgIx5OFH62nimatX1U'&amp;api-version=2013-04\"/></feed>";

NSString* deviceToken1 = @"11";
NSString* deviceToken2 = @"22";

- (void)setUp
{
    [super setUp];
    
    connectionStringSAS = [SBConnectionString stringWithEndpoint:[NSURL URLWithString:@"https://test.servicebus.windows.net/"] fullAccessSecret:@"myFullAccessPwd"];
    
    connectionStringACS = [SBConnectionString stringWithEndpoint:[NSURL URLWithString:@"sb://test.servicebus.windows.net"] issuer:@"owner" issuerSecret:@"GnxQQPqX2xwy72BE2Kmb/RvD58R1p7/NqVL9v8bmqC0="];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testConnectionString
{
    NSString* conn = [SBConnectionString stringWithEndpoint:[NSURL URLWithString:@"sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/"] fullAccessSecret:@"myFullAccessPwd"];
    
    if(![conn isEqualToString:@"Endpoint=sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=myFullAccessPwd"])
    {
        STFail(@"Fail at connectionString for full accessSecret.");
        return;
    }
    
    conn = [SBConnectionString stringWithEndpoint:[NSURL URLWithString:@"sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/"] listenAccessSecret:@"myListenAccessPwd"];
    if(![conn isEqualToString:@"Endpoint=sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=myListenAccessPwd"])
    {
        STFail(@"Fail at connectionString for listen accessSecret.");
        return;
    }
    
    conn = [SBConnectionString stringWithEndpoint:[NSURL URLWithString:@"sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/"] issuer:@"owner" issuerSecret:@"GnxQQPqX2xwy72BE2Kmb/RvD58R1p7/NqVL9v8bmqC0="];
    if(![conn isEqualToString:@"Endpoint=sb://INT7-SN1-012Tinnu-0-10.servicebus.int7.windows-int.net/;SharedSecretIssuer=owner;SharedSecretValue=GnxQQPqX2xwy72BE2Kmb/RvD58R1p7/NqVL9v8bmqC0="])
    {
        STFail(@"Fail at connectionString for full sharedScrete.");
        return;
    }
}

- (void)testInvalidConnectionString
{
    SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:@"wrongConnectionString" notificationHubPath:path];
    if(notificationHub)
    {
        STFail(@"Fail at creating notificationHub.");
        return;
    }
}

- (void)testCreateRegistrationWithSameStorageVersion
{
    [TestHelper updateSettingWithVersion:TRUE registrations:FALSE useOldVersion:FALSE];

    NSLog(@"1: creat notifiationHub");
    
    SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
    if(!notificationHub)
    {
        STFail(@"Fail at creating notificationHub.");
        return;
    }
    
    NSData* deviceToken = [deviceToken1 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"2. registerNative");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            if (!createRegistrationIdRequestFinished)
            {
                NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"POST" url:@"https://test.servicebus.windows.net/PushTest/registrationids/?api-version=2013-04" body:@""];
                
                if(ret)
                {
                    NSLog(@"Second call should be create registraionId call.");
                    STFail(ret);
                }
                
                createRegistrationIdRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];                response.Data = [[NSData alloc] init];
                response.Headers = @{@"Location":@"https://test.servicebus.windows.net/PushTest/registrations/73838-337-2383"};
                return response;
            }
            else
            {
                NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"PUT" url:@"https://test.servicebus.windows.net/PushTest/Registrations/73838-337-2383?api-version=2013-04" body:@"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\"><Tags>Tag2,Tag1</Tags><DeviceToken>3131</DeviceToken></AppleRegistrationDescription></content></entry>"];
            
                if(ret)
                {
                    STFail(ret);
                }
            
                httpRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [[NSData alloc] init];
                return response;
            }
        }];
        
        // creat regs
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] error:nil];
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        httpRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] completion:nil];
        sleep(1);
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"3. registerTemplate");
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            if (!createRegistrationIdRequestFinished)
            {
                NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"POST" url:@"https://test.servicebus.windows.net/PushTest/registrationids/?api-version=2013-04" body:@""];
                
                if(ret)
                {
                    NSLog(@"Second call should be create registraionId call.");
                    STFail(ret);
                }
                
                createRegistrationIdRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [[NSData alloc] init];
                response.Headers = @{@"Location":@"https://test.servicebus.windows.net/PushTest/registrations/73838-337-2383"};
                return response;
            }
            else
            {
                NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"PUT" url:@"https://test.servicebus.windows.net/PushTest/Registrations/73838-337-2383?api-version=2013-04" body:@"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\"><Tags>tag3,tag4</Tags><DeviceToken>3131</DeviceToken><BodyTemplate><![CDATA[{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}]]></BodyTemplate><Expiry>$(expiry)</Expiry><TemplateName>MyReg2</TemplateName></AppleTemplateRegistrationDescription></content></entry>"];
            
                if(ret)
                {
                    STFail(ret);
                }
            
                httpRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [[NSData alloc] init];
                return response;
            }
        }];

        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] error:nil];
        
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    
        httpRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] completion:nil];
        sleep(1);
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
}

- (void)testCreateRegistrationWithSameStorageVersionAndRegistrationCache
{
    [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:FALSE];
    
    NSLog(@"1: creat notifiationHub");
  
    SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
    if(!notificationHub)
    {
        STFail(@"Fail at creating notificationHub.");
        return;
    }
    
    NSData* deviceToken = [deviceToken1 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"2. registerNative");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"PUT" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId1?api-version=2013-04" body:@"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\"><Tags>Tag2,Tag1</Tags><DeviceToken>3131</DeviceToken></AppleRegistrationDescription></content></entry>"];
            
            if(ret)
            {
                STFail(ret);
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }];
        
        // creat regs
        httpRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] error:nil];
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        httpRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] completion:nil];
        sleep(1);
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"3. registerTemplate");
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"PUT" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId2?api-version=2013-04" body:@"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\"><Tags>tag3,tag4</Tags><DeviceToken>3131</DeviceToken><BodyTemplate><![CDATA[{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}]]></BodyTemplate><Expiry>$(expiry)</Expiry><TemplateName>regName</TemplateName></AppleTemplateRegistrationDescription></content></entry>"];
            
            if(ret)
            {
                STFail(ret);
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }];
        
        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        
        httpRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"regName" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] error:nil];
        
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        httpRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"regName" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] completion:nil];
        sleep(1);
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
}

- (void)testCreateRegistrationWithEmptyStorageVersion
{
    // when ther version is not in the local setting, or different
    // All create calls should start with retrieveAll call
    
    NSData* deviceToken = [deviceToken1 dataUsingEncoding:NSUTF8StringEncoding];
    [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
        
        if( !refreshRequestFinished)
        {
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"GET" url:@"https://test.servicebus.windows.net/PushTest/Registrations/?$filter=deviceToken+eq+'3131'&api-version=2013-04" body:@""];
            
            if(ret)
            {
                STFail(ret);
            }
            
            refreshRequestFinished = TRUE;
            
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [emptyRegistrations dataUsingEncoding:NSUTF8StringEncoding];
            return response;
        }
        else if (refreshRequestFinished && !createRegistrationIdRequestFinished)
        {
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"POST" url:@"https://test.servicebus.windows.net/PushTest/registrationids/?api-version=2013-04" body:@""];
            
            if(ret)
            {
                NSLog(@"Second call should be create registraionId call.");
                STFail(ret);
            }
            
            createRegistrationIdRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            response.Headers = @{@"Location":@"https://test.servicebus.windows.net/PushTest/registrations/73838-337-2383"};
            return response;
        }
        else
        {
            //second call should be create
            if(![[request HTTPMethod] isEqualToString:@"PUT"])
            {
                STFail(@"Last call should be create call.");
            }
            
            // same deviceToken
            NSString* body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            if ([body rangeOfString:@"<DeviceToken>3131</DeviceToken>"].location == NSNotFound)
            {
                STFail(@"Second call body should include correct deviceToken.");
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }
    }];
    
    NSLog(@"1. registerNative");
    {
        // create regs
        [TestHelper updateSettingWithVersion:FALSE registrations:FALSE useOldVersion:FALSE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] error:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"2. registerNative async");
    {
        [TestHelper updateSettingWithVersion:FALSE registrations:FALSE useOldVersion:FALSE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] completion:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"3. registerTemplate");
    {
        // template
        [TestHelper updateSettingWithVersion:FALSE registrations:FALSE useOldVersion:FALSE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] error:nil];
        
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"4. registerTemplate async");
    {
        [TestHelper updateSettingWithVersion:FALSE registrations:FALSE useOldVersion:FALSE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] completion:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    [SBURLConnection setStaticHandler:nil];
}

- (void)testCreateRegistrationWithDifferentStorageVersionAndNewDeviceToken
{
    // when ther version is not in the local setting, or different
    // All create calls should start with retrieveAll call
    
    NSData* deviceToken = [deviceToken2 dataUsingEncoding:NSUTF8StringEncoding];
    [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
        
        if( !refreshRequestFinished)
        {
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"GET" url:@"https://test.servicebus.windows.net/PushTest/Registrations/?$filter=deviceToken+eq+'3131'&api-version=2013-04" body:@""];

            if(ret)
            {
                STFail(ret);
            }
            
            refreshRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [emptyRegistrations dataUsingEncoding:NSUTF8StringEncoding];
            return response;
        }
        else if (refreshRequestFinished && !createRegistrationIdRequestFinished)
        {
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"POST" url:@"https://test.servicebus.windows.net/PushTest/registrationids/?api-version=2013-04" body:@""];
            
            if(ret)
            {
                NSLog(@"Second call should be create registraionId call.");
                STFail(ret);
            }
            
            createRegistrationIdRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            response.Headers = @{@"Location":@"https://test.servicebus.windows.net/PushTest/registrations/73838-337-2383"};
            return response;
        }
        else
        {
            //second call should be create
            NSString* method = [request HTTPMethod];
            if(![method isEqualToString:@"PUT"])
            {
                STFail(@"Second call should be create call.");
            }
            
            // new deviceToken
            NSString* body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            if ([body rangeOfString:@"<DeviceToken>3232</DeviceToken>"].location == NSNotFound)
            {
                STFail(@"Second call body should include correct deviceToken.");
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }
    }];
    
    NSLog(@"1. registerNative");
    {
        // create regs
        [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:TRUE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] error:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"2. registerNative async");
    {
        [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:TRUE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerNativeWithDeviceToken:deviceToken tags:[NSSet setWithArray:@[@"Tag1",@"Tag2"]] completion:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"3. registerTemplate");
    {
        // template
        [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:TRUE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] error:nil];
        
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    NSLog(@"4. registerTemplate async");
    {
        [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:TRUE];
        SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
        
        NSString* jsonBody = @"{\"aps\":{\"alert\":\"$(GotMail)\",\"badge\":10, \"sound\":\"bingbong.aiff\"},\"acme\":\"My data\"}";
        createRegistrationIdRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        refreshRequestFinished = FALSE;
        [notificationHub registerTemplateWithDeviceToken:deviceToken name:@"MyReg2" jsonBodyTemplate:jsonBody expiryTemplate:@"$(expiry)" tags:[NSSet setWithArray:@[@"tag3",@"tag4"]] completion:nil];
        if(!httpRequestFinished || !refreshRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
    }
    
    [SBURLConnection setStaticHandler:nil];
}

- (void)testDeleteRegistration
{
    [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:FALSE];

    NSLog(@"1: creat notifiationHub");
    
    SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringSAS notificationHubPath:path];
    if(!notificationHub)
    {
        STFail(@"Fail at creating notificationHub.");
        return;
    }
    
    //NSData* deviceToken = [@"12345678912345678912345678912345" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"3. unregisterNative");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"DELETE" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId1?api-version=2013-04" body:@""];
            if(ret)
            {
                STFail(ret);
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }];
        
        httpRequestFinished = FALSE;
        [notificationHub unregisterNativeWithError:nil];
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        httpRequestFinished = FALSE;
        [notificationHub unregisterNativeWithCompletion:nil];
        if(httpRequestFinished)
        {
            STFail(@"HTTP requests was sent out");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
    
    NSLog(@"4. unregisterTemplate");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            NSString* ret = [TestHelper verifySASHttpRequest:request httpMethod:@"DELETE" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId2?api-version=2013-04" body:@""];
            if(ret)
            {
                STFail(ret);
            }
            
            httpRequestFinished = TRUE;
            SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
            response.Data = [[NSData alloc] init];
            return response;
        }];
        
        httpRequestFinished = FALSE;
        [notificationHub unregisterTemplateWithName:@"regName" error:nil];
        if(!httpRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        httpRequestFinished = FALSE;
        [notificationHub unregisterTemplateWithName:@"regName" completion:nil];
        sleep(1);
        if(httpRequestFinished)
        {
            STFail(@"HTTP requests was sent out");
        }
        
        
        httpRequestFinished = FALSE;
        [notificationHub unregisterTemplateWithName:@"NoExistingName" completion:nil];
        sleep(1);
        if(httpRequestFinished)
        {
            STFail(@"Http request should not sent");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
}

- (void)testDeleteRegistrationACS
{
    [TestHelper updateSettingWithVersion:TRUE registrations:TRUE useOldVersion:FALSE];

    NSLog(@"1: creat notifiationHub");
    
    SBNotificationHub* notificationHub = [[SBNotificationHub alloc] initWithConnectionString:connectionStringACS notificationHubPath:path];
    
    NSLog(@"3. unregisterDefault");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            if( !tokenRequestFinished)
            {
                NSString* ret = [TestHelper verifyHttpRequest:request httpMethod:@"POST" url:@"https://test-sb.accesscontrol.windows.net/WRAPv0.9/" body:@"wrap_scope=http%3A%2F%2Ftest.servicebus.windows.net%2Fpushtest%2Fregistrations%2Fmyregid1&wrap_assertion_format=SWT&wrap_assertion=Issuer%3Downer%26HMACSHA256%3Dje1Q5mR%252FmLmbz%252Bio5k%252FuuJ8l4CM5EIb9uN73iZfCHgk%253D"];
                
                if(ret)
                {
                    STFail(ret);
                }
                
                tokenRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [@"wrap_access_token=newToken&wrap_acess_token_expires_in=3600" dataUsingEncoding:NSUTF8StringEncoding];
                return response;
            }
            else
            {
                NSString* ret = [TestHelper verifyACSHttpRequest:request httpMethod:@"DELETE" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId1?api-version=2013-04" body:@""];
                
                if(ret)
                {
                    STFail(ret);
                }
                
                httpRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [[NSData alloc] init];
                return response;
            }
        }];
        
        tokenRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub unregisterNativeWithError:nil];
        if(!httpRequestFinished || !tokenRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        tokenRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub unregisterNativeWithCompletion:nil];
        sleep(1);
        if(httpRequestFinished || tokenRequestFinished)
        {
            STFail(@"HTTP requests was sent out");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
    
    NSLog(@"4. unregisterTemplate");
    
    {
        [SBURLConnection setStaticHandler:^SBStaticHandlerResponse *(NSURLRequest *request) {
            
            if( !tokenRequestFinished)
            {
                NSString* ret = [TestHelper verifyHttpRequest:request httpMethod:@"POST" url:@"https://test-sb.accesscontrol.windows.net/WRAPv0.9/" body:@"wrap_scope=http%3A%2F%2Ftest.servicebus.windows.net%2Fpushtest%2Fregistrations%2Fmyregid2&wrap_assertion_format=SWT&wrap_assertion=Issuer%3Downer%26HMACSHA256%3Dje1Q5mR%252FmLmbz%252Bio5k%252FuuJ8l4CM5EIb9uN73iZfCHgk%253D"];
                
                if(ret)
                {
                    STFail(ret);
                }
                
                tokenRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [@"wrap_access_token=newToken&wrap_acess_token_expires_in=3600" dataUsingEncoding:NSUTF8StringEncoding];
                return response;
            }
            else
            {
                NSString* ret = [TestHelper verifyACSHttpRequest:request httpMethod:@"DELETE" url:@"https://test.servicebus.windows.net/PushTest/Registrations/myRegId2?api-version=2013-04" body:@""];
                
                if(ret)
                {
                    STFail(ret);
                }
                
                httpRequestFinished = TRUE;
                SBStaticHandlerResponse* response = [[SBStaticHandlerResponse alloc] init];
                response.Data = [[NSData alloc] init];
                return response;
            }
        }];
        
        tokenRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub unregisterTemplateWithName:@"regName" error:nil];
        if(!httpRequestFinished || !tokenRequestFinished)
        {
            STFail(@"Http request didn't send out.");
        }
        
        tokenRequestFinished = FALSE;
        httpRequestFinished = FALSE;
        [notificationHub unregisterTemplateWithName:@"regName" completion:nil];
        sleep(1);
        if(httpRequestFinished || tokenRequestFinished)
        {
            STFail(@"HTTP requests was sent out");
        }
        
        [SBURLConnection setStaticHandler:nil];
    }
}

@end

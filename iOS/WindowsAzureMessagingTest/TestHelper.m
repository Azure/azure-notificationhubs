//
//  TestHelper.m
//  WindowsAzureMessagingTest
//
//  Created by Vinod Shanbhag on 2/1/13.
//  Copyright (c) 2013 Azure ServiceBus. All rights reserved.
//

#import "TestHelper.h"
#import "SBNotificationHub.h"

@implementation TestHelper


+ (NSString*) verifyHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody
{
    NSString* httpMethod = [request HTTPMethod];
    if(![httpMethod isEqualToString:expectedMethod])
    {
        NSLog(@"HttpMethod:%@",httpMethod);
        return @"HttpMethod is not correct.";
    }
    
    NSString* url = [[request URL] absoluteString];
    if(![url isEqualToString:expectedUrl])
    {
        NSLog(@"URL:%@",url);
        return @"Url is not correct.";
    }
    
    NSString* bodyText = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    if(![bodyText isEqualToString:expectedBody])
    {
        NSLog(@"Body:%@",bodyText);
        return @"Body is not correct.";
    }
    
    return nil;
}

+ (NSString*) verifySASHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody
{
    NSString* ret = [TestHelper verifyHttpRequest:request httpMethod:expectedMethod url:expectedUrl body:expectedBody];
    if(ret)
    {
        return ret;
    }
    
    NSDictionary* headers = [request allHTTPHeaderFields];
    
    if( ![[headers objectForKey:@"Content-Type"] isEqualToString:@"application/xml"]  ||
       ![[headers objectForKey:@"Authorization"] hasPrefix:@"SharedAccessSignature sr="] ||
       ![[headers objectForKey:@"User-Agent"] hasPrefix:@"NOTIFICATIONHUBS/"] ||
       [[headers objectForKey:@"User-Agent"] rangeOfString:@"api-origin=IosSdk"].location == NSNotFound)
    {
        NSLog(@"Headers:%@",headers);
        return @"Header is not correct.";
    }
   
    return nil;
}

+ (NSString*) verifyACSHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody
{
    NSString* ret = [TestHelper verifyHttpRequest:request httpMethod:expectedMethod url:expectedUrl body:expectedBody];
    if(ret)
    {
        return ret;
    }
    
    NSDictionary* headers = [request allHTTPHeaderFields];
    if( ![[headers objectForKey:@"Content-Type"] isEqualToString:@"application/xml"] ||
       ![[headers objectForKey:@"Authorization"] isEqualToString:@"WRAP access_token=\"newToken\""])
    {
        NSLog(@"Headers:%@",headers);
        return @"Header is not correct.";
    }
    
    return nil;
}

+ (NSString*) verifyETagWithRequest:(NSURLRequest *)request ETag:(NSString*) etag
{
    if( ![etag isEqualToString:@"*"])
    {
        etag = [NSString stringWithFormat:@"\"%@\"",etag];
    }
    
    NSDictionary* headers = [request allHTTPHeaderFields];
    if( ![[headers objectForKey:@"If-Match"] isEqualToString:etag])
    {
        NSLog(@"Headers:%@",headers);
        return @"ETag is not correct.";
    }
    
    return nil;
}

+ (NSString*) verifyCustomizedTokenHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody
{
    NSString* ret = [TestHelper verifyHttpRequest:request httpMethod:expectedMethod url:expectedUrl body:expectedBody];
    if(ret)
    {
        return ret;
    }
    
    NSDictionary* headers = [request allHTTPHeaderFields];
    if( ![[headers objectForKey:@"Content-Type"] isEqualToString:@"application/xml"]  ||
       ![[headers objectForKey:@"Authorization"] isEqualToString:@"newToken"])
    {
        NSLog(@"Headers:%@",headers);
        return @"Header is not correct.";
    }
    
    return nil;
}

+ (void) updateSettingWithVersion:(BOOL)addVersion registrations:(BOOL)addRegistrations useOldVersion:(BOOL)useOldVersion
{
    NSString* current_storageVersion = @"v1.0.0";
    NSString* deviceToken = @"3131";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(addVersion)
    {
        if( useOldVersion)
        {
            [defaults setObject:@"v0.0.1" forKey:@"PushTest-version"];
        }
        else
        {
            [defaults setObject:current_storageVersion forKey:@"PushTest-version"];
        }
        
        [defaults setObject:deviceToken forKey:@"PushTest-deviceToken"];
    }
    else
    {
        [defaults removeObjectForKey:@"PushTest-deviceToken"];
        [defaults removeObjectForKey:@"PushTest-version"];
    }
    
    if( addRegistrations)
    {
        NSMutableArray* registrations = [[NSMutableArray alloc] initWithObjects:@"$Default:myRegId1:1",@"regName:myRegId2:1", nil];
        [defaults setObject:registrations forKey:@"PushTest-registrations"];
    }
    else
    {
        [defaults removeObjectForKey:@"PushTest-registrations"];
    }
    
    [defaults synchronize];
}

+ (BOOL) verifySettingWithDeviceToken:(NSString*)deviceToken EmptyRegistrations:(BOOL)emptyRegistrations
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* storedDeviceToken = [defaults objectForKey:@"PushTest-deviceToken"];
    if(deviceToken != nil && ![storedDeviceToken isEqualToString:deviceToken])
    {
        return FALSE;
    }
    
    NSArray* registrations = [defaults objectForKey:@"PushTest-registrations"];
    if( emptyRegistrations)
    {
        return registrations == nil;
    }
    else
    {
        if( ( [[registrations objectAtIndex:1] isEqualToString:@"$Default:myRegId1:1"] &&
           [[registrations objectAtIndex:0] isEqualToString:@"regName:myRegId2:2"]) ||
           ([[registrations objectAtIndex:0] isEqualToString:@"$Default:myRegId1:1"] &&
           [[registrations objectAtIndex:1] isEqualToString:@"regName:myRegId2:2"]) )
        {
            return TRUE;
        }
        
        return FALSE;
    }
}
@end

//
//  TestHelper.h
//  WindowsAzureMessagingTest
//
//  Created by Vinod Shanbhag on 2/1/13.
//  Copyright (c) 2013 Azure ServiceBus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestHelper : NSObject

+ (NSString*) verifyHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody;

+ (NSString*) verifySASHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody;

+ (NSString*) verifyACSHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody;

+ (NSString*) verifyCustomizedTokenHttpRequest:(NSURLRequest *)request httpMethod:(NSString*)expectedMethod url:(NSString*)expectedUrl body:(NSString*)expectedBody;

+ (NSString*) verifyETagWithRequest:(NSURLRequest *)request ETag:(NSString*) etag;

+ (void) updateSettingWithVersion:(BOOL)addVersion registrations:(BOOL)addRegistrations useOldVersion:(BOOL)useOldVersion;

+ (BOOL) verifySettingWithDeviceToken:(NSString*)deviceToken EmptyRegistrations:(BOOL)emptyRegistrations;

@end

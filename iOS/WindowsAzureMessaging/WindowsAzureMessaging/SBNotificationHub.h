//----------------------------------------------------------------
//  Copyright (c) Microsoft Corporation. All rights reserved.
//----------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface SBNotificationHub : NSObject
{
@private
    NSString* _path;
    NSURL* _serviceEndPoint;
}

+ (NSString*) version;

- (SBNotificationHub*) initWithConnectionString:(NSString*) connectionString notificationHubPath:(NSString*)notificationHubPath;

// Async operations
- (void) registerNativeWithDeviceToken:(NSData*)deviceToken tags:(NSSet*)tags completion:(void (^)(NSError* error))completion;
- (void) registerTemplateWithDeviceToken:(NSData*)deviceToken name:(NSString*)name jsonBodyTemplate:(NSString*)bodyTemplate expiryTemplate:(NSString*)expiryTemplate tags:(NSSet*)tags completion:(void (^)(NSError* error))completion;

- (void) unregisterNativeWithCompletion:(void (^)(NSError* error))completion;
- (void) unregisterTemplateWithName:(NSString*)name completion:(void (^)(NSError* error))completion;

- (void) unregisterAllWithDeviceToken:(NSData*)deviceToken completion:(void (^)(NSError* error))completion;

// sync operations
- (BOOL) registerNativeWithDeviceToken:(NSData*)deviceToken tags:(NSSet*)tags error:(NSError**)error;
- (BOOL) registerTemplateWithDeviceToken:(NSData*)deviceToken name:(NSString*)templateName jsonBodyTemplate:(NSString*)bodyTemplate expiryTemplate:(NSString*)expiryTemplate tags:(NSSet*)tags error:(NSError**)error;

- (BOOL) unregisterNativeWithError:(NSError**)error;
- (BOOL) unregisterTemplateWithName:(NSString*)name error:(NSError**)error;

- (BOOL) unregisterAllWithDeviceToken:(NSData*)deviceToken error:(NSError**)error;

@end

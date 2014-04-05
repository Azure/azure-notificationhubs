#import <Foundation/Foundation.h>

@interface RegistrationRetriever : NSObject
{
@private
    NSString* _path;
    NSURL* _serviceEndPoint;
}

- (RegistrationRetriever*) initWithConnectionString:(NSString*) connectionString notificationHubPath:(NSString*)notificationHubPath;
- (NSArray*) retrieveAllWithDeviceToken:(NSData*)deviceToken error:(NSError**)error;

@end

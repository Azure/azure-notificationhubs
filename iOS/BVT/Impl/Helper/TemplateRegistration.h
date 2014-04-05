#import <Foundation/Foundation.h>
#import "Registration.h"

@interface TemplateRegistration : Registration

@property (copy, nonatomic) NSString* bodyTemplate;
@property (copy, nonatomic) NSString* expiry;
@property (copy, nonatomic) NSString* templateName;

+ (NSString*) payloadWithDeviceToken:(NSString*)deviceToken bodyTemplate:(NSString*)bodyTemplate expiryTemplate:(NSString*)expiryTemplate tags:(NSSet*)tags templateName:(NSString *)templateName;

@end
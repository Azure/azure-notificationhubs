#import "Registration.h"
#import "TestHelper.h"

@implementation Registration

NSString* const myFormat = @"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">%@<DeviceToken>%@</DeviceToken></AppleRegistrationDescription></content></entry>";

@synthesize ETag, expiresAt, tags, deviceToken, registrationId;

+ (NSString*) Name
{
    return @"$Default";
}

+ (NSString*) payloadWithDeviceToken:(NSString*)deviceToken tags:(NSSet*)tags
{
    NSString* tagNode = @"";
    NSString* tagString = [TestHelper convertTagSetToString:tags];
    if( [tagString length]>0)
    {
        tagNode = [NSString stringWithFormat:@"<Tags>%@</Tags>", tagString];
    }
    
    return [NSString stringWithFormat:myFormat, tagNode, deviceToken];
}

@end



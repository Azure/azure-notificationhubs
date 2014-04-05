#import "TemplateRegistration.h"
#import "TestHelper.h"

@implementation TemplateRegistration

NSString* const myTemplateFormat = @"<entry xmlns=\"http://www.w3.org/2005/Atom\"><content type=\"text/xml\"><AppleTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">%@<DeviceToken>%@</DeviceToken><BodyTemplate><![CDATA[%@]]></BodyTemplate>%@<TemplateName>%@</TemplateName></AppleTemplateRegistrationDescription></content></entry>";

@synthesize bodyTemplate, expiry, templateName;

+ (NSString*) payloadWithDeviceToken:(NSString*)deviceToken bodyTemplate:(NSString*)bodyTemplate expiryTemplate:(NSString*)expiryTemplate tags:(NSSet*)tags templateName:(NSString *)templateName
{
    NSString* expiryFullString = @"";
    if(expiryTemplate && [expiryTemplate length]>0)
    {
        expiryFullString = [NSString stringWithFormat:@"<Expiry>%@</Expiry>",expiryTemplate];
    }
    
    NSString* tagNode = @"";
    NSString* tagString = [TestHelper convertTagSetToString:tags];
    if( [tagString length]>0)
    {
        tagNode = [NSString stringWithFormat:@"<Tags>%@</Tags>", tagString];
    }
    
    return [NSString stringWithFormat:myTemplateFormat, tagNode, deviceToken, bodyTemplate, expiryFullString, templateName];
}

@end

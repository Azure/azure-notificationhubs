#import "Registration.h"

@interface RegistrationParser : NSObject{
    @private
    NSMutableArray *_allRegistrations;
    NSMutableString *_currentElementValue;
    Registration *_currentRegistration;
}

- (RegistrationParser*) initParserWithResult:(NSMutableArray*)result;

+ (NSArray *)parseRegistrations:(NSData *)data error:(NSError **)error;
@end

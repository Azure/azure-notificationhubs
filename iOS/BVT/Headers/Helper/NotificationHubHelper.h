#import <Foundation/Foundation.h>

@interface NotificationHubHelper : NSObject

+ (NSString*) urlEncode: (NSString*)urlString;
+ (NSString*) urlDecode: (NSString*)urlString;

+ (NSString*) createHashWithData:(NSData*)data;

+ (NSString*) signString: (NSString*)str withKey:(NSString*) key;
+ (NSString*) signString: (NSString*)str withKeyData:(const char*) cKey keyLength:(NSInteger) keyLength;

+ (NSData*) fromBase64: (NSString*) str;
+ (NSString*) toBase64: (unsigned char*) data length:(NSInteger) length;

+ (NSString*) convertTagSetToString:(NSSet*)tagSet;

+ (NSError*) errorWithMsg:(NSString*)msg code:(NSInteger)code;

+ (NSError*) errorForNullDeviceToken;

@end



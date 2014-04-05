#import "NotificationHubHelper.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NotificationHubHelper

static const char encodingTableNew[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static char decodingTableNew[128];
static NSString* decodingTableLockNew = @"decodingTableLock";

+ (NSString*) urlEncode: (NSString*)urlString{
    return (__bridge NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)urlString, NULL,CFSTR("!*'();:@&=+$,/?%#[]"),  kCFStringEncodingUTF8);
}

+ (NSString*) urlDecode: (NSString*)urlString{
    return [[urlString
      stringByReplacingOccurrencesOfString:@"+" withString:@" "]
     stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*) createHashWithData:(NSData*)data{
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSString* hash = [self toBase64:(unsigned char *)digest length:CC_SHA1_DIGEST_LENGTH];
    
    return [[[hash stringByReplacingOccurrencesOfString:@"=" withString:@""] stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

+ (NSString*) signString: (NSString*)str withKeyData:(const char*) cKey keyLength:(NSInteger) keyLength{
    const char *cData = [str cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, keyLength, cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
    
    NSString* signature = [self toBase64:(unsigned char *)[HMAC bytes] length:[HMAC length]];
    
    return signature;

}

+ (NSString*) signString: (NSString*)str withKey:(NSString*) key{
    const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    return [self signString:str withKeyData:cKey keyLength:strlen(cKey)];
}

+ (NSData*) fromBase64: (NSString*) str{
    
    if(decodingTableNew['B'] != 1)
    {
        @synchronized(decodingTableLockNew)
        {
            if(decodingTableNew['B'] != 1)
            {
                memset(decodingTableNew, 0, 128);
                int length = (sizeof encodingTableNew);
                for (int i = 0; i < length; i++)
                {
                    decodingTableNew[encodingTableNew[i]] = i;
                }
            }
        }
    }

    NSData* inputData = [str dataUsingEncoding:NSASCIIStringEncoding];
    const char* input =inputData.bytes;
    NSInteger inputLength = inputData.length;
    
    if ((input == NULL) || (inputLength% 4 != 0)) {
		return nil;
	}
	
	while (inputLength > 0 && input[inputLength - 1] == '=') {
		inputLength--;
	}
	
	int outputLength = inputLength * 3 / 4;
	NSMutableData* outputData = [NSMutableData dataWithLength:outputLength];
	uint8_t* output = outputData.mutableBytes;
    
    int outputPos = 0;
    for (int i=0; i<inputLength; i += 4)
    {
        char i0 = input[i];
		char i1 = input[i+1];
		char i2 = i+2 < inputLength ? input[i+2] : 'A';
        char i3 = i+3 < inputLength ? input[i+3] : 'A';
		
        char result =(decodingTableNew[i0] << 2) | (decodingTableNew[i1] >> 4);
		output[outputPos++] =  result;
		if (outputPos < outputLength) {
			output[outputPos++] = ((decodingTableNew[i1] & 0xf) << 4) | (decodingTableNew[i2] >> 2);
		}
		if (outputPos < outputLength) {
			output[outputPos++] = ((decodingTableNew[i2] & 0x3) << 6) | decodingTableNew[i3];
		}
    }
    
    return outputData;
}

+ (NSString*) toBase64: (unsigned char*) data length:(NSInteger) length{
    
    NSMutableString *dest = [[NSMutableString alloc] initWithString:@""];
    
    unsigned char * tempData = (unsigned char *)data;
    NSInteger srcLen = length;
    
    for (int i=0; i<srcLen; i += 3)
    {
        NSInteger value = 0;
        for (int j = i; j < (i + 3); j++) {
            value <<= 8;
			
            if (j < length) {
                value |= (0xFF & tempData[j]);
            }
        }
		
        [dest appendFormat:@"%c", encodingTableNew[(value >> 18) & 0x3F]];
        [dest appendFormat:@"%c", encodingTableNew[(value >> 12) & 0x3F]];
        [dest appendFormat:@"%c", (i + 1) < length ? encodingTableNew[(value >> 6)  & 0x3F] : '='];
        [dest appendFormat:@"%c", (i + 2) < length ? encodingTableNew[(value >> 0)  & 0x3F] : '='];
    }
    
    return dest;
}

+ (NSString*) convertTagSetToString:(NSSet*)tagSet
{
    if(!tagSet)
    {
        return @"";
    }
    
    NSMutableString* tags;
    
    for (NSString *element in tagSet) {
        if(!tags)
        {
            tags=[[NSMutableString alloc] initWithString:element];
        }
        else
        {
            [tags appendString:[NSString stringWithFormat:@",%@",element]];
        }
    }
    
    return tags;
}

NSString* const domainNew = @"WindowsAzureMessaging";

+ (NSError*) errorForNullDeviceToken
{
    return [NotificationHubHelper errorWithMsg:@"Device Token is not updated. Please call refreshRegistrationsWithDeviceToken." code:-1];
}

+ (NSError*) errorWithMsg:(NSString*)msg code:(NSInteger)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:msg forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:domainNew code:code userInfo:details];
}

@end


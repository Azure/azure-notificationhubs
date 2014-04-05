@interface TokenProvider : NSObject{

@private
    NSString* _sharedAccessValue;
    NSString* _sharedAccessKeyName ;
    NSString* _sharedSecret;
    NSString* _sharedSecretIssurer;
    NSURL* _stsHostName;
    NSURL* _serviceEndPoint;
    NSString* _path;
}

@property (nonatomic) NSInteger timeToExpireinMins;

- (TokenProvider*) initWithConnectionString: (NSString*) connectionString path:(NSString*)path;

- (void) setTokenWithRequest:(NSMutableURLRequest*)request completion:(void (^)(NSError*))completion;
- (BOOL) setTokenWithRequest:(NSMutableURLRequest*)request error:(NSError**)error;

- (NSString*) getToken;

@end


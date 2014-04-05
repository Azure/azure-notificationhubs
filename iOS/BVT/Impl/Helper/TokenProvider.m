#import "TokenProvider.h"
#import "NotificationHubHelper.h"
#import "URLConnection.h"

@implementation TokenProvider

const int defaultTimeToExpireinMins1 = 20;

@synthesize timeToExpireinMins;

- (TokenProvider*) initWithConnectionString: (NSString*) connectionString path:(NSString*)path
{
    self = [super init];
    
    if( self){
        NSDictionary* connectionDictionary = [self parseConnectionString:connectionString];
        if(![self initMembersWithDictionary:connectionDictionary])
        {
            return nil;
        }
        
        self->_path = path;
    }
    
    return self;
}

- (NSDictionary*) parseConnectionString:(NSString*) connectionString
{
    NSArray *allField = [connectionString componentsSeparatedByString:@";"];
    
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    
    NSString* previousLeft = @"";
    for (int i=0; i< [allField count]; i++) {
        NSString* currentField = (NSString*)[allField objectAtIndex:i];
        
        if( (i+1) < [allField count])
        {
            // if next field does not start with known name, this ';' will be ignored
            NSString* lowerCaseNextField = [(NSString*)[allField objectAtIndex:(i+1)] lowercaseString];
            if(!([lowerCaseNextField hasPrefix:@"endpoint="] ||
                 [lowerCaseNextField hasPrefix:@"sharedaccesskeyname="] ||
                 [lowerCaseNextField hasPrefix:@"sharedaccesskey="] ||
                 [lowerCaseNextField hasPrefix:@"sharedsecretissuer="] ||
                 [lowerCaseNextField hasPrefix:@"sharedsecretvalue="] ||
                 [lowerCaseNextField hasPrefix:@"stsendpoint="] ))
            {
                previousLeft = [NSString stringWithFormat:@"%@%@;",previousLeft,currentField];
                continue;
            }
        }
        
        currentField = [NSString stringWithFormat:@"%@%@",previousLeft,currentField];
        previousLeft = @"";
        
        NSArray *keyValuePairs = [currentField componentsSeparatedByString:@"="];
        NSString* keyName = [[keyValuePairs objectAtIndex: 0] lowercaseString];
        
        NSString* keyValue =[currentField substringFromIndex:([keyName length] +1)];
        if([keyName isEqualToString:@"endpoint"]){
            if(![keyValue hasSuffix:@"/"])
            {
                keyValue = [NSString stringWithFormat:@"%@/",keyValue];
            }
        }
        
        [result setObject:keyValue forKey:keyName];
    }
    
    return result;
}

- (BOOL)initMembersWithDictionary:(NSDictionary*) connectionDictionary
{
    self->timeToExpireinMins = defaultTimeToExpireinMins1;
    
    NSString* endpoint = [connectionDictionary objectForKey:@"endpoint"];
    if( endpoint)
    {
        self->_serviceEndPoint = [[NSURL alloc] initWithString:endpoint];
    }
    
    NSString* stsendpoint = [connectionDictionary objectForKey:@"stsendpoint"];
    if( stsendpoint)
    {
        self->_stsHostName = [[NSURL alloc] initWithString:stsendpoint];
    }
    
    self->_sharedAccessValue = [connectionDictionary objectForKey:@"sharedaccesskey"];
    self->_sharedAccessKeyName = [connectionDictionary objectForKey:@"sharedaccesskeyname"];
    self->_sharedSecret = [connectionDictionary objectForKey:@"sharedsecretvalue"];
    self->_sharedSecretIssurer = [connectionDictionary objectForKey:@"sharedsecretissuer"];
    
    // validation
    if(self->_serviceEndPoint == nil ||
       [self->_serviceEndPoint host] == nil)
    {
        NSLog(@"%@",@"Endpoint is missing or not in URL format in connectionString.");
        return FALSE;
    }
    
    //if(self->_generateTokenCallback == nil)
    {
        if((self->_sharedAccessValue == nil || self->_sharedAccessKeyName == nil) &&
           self->_sharedSecret == nil)
        {
            NSLog(@"%@",@"Security information is missing in connectionString.");
            return FALSE;
        }
        
        if(self->_stsHostName == nil)
        {
            NSString* nameSpace = [[[self->_serviceEndPoint host] componentsSeparatedByString:@"."] objectAtIndex:0];
            self->_stsHostName = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://%@-sb.accesscontrol.windows.net",nameSpace]];
        }
        else
        {
            if([self->_stsHostName host] == nil)
            {
                NSLog(@"%@",@"StsHostname is not in URL format in connectionString.");
                return FALSE;
            }
            
            self->_stsHostName = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://%@",[self->_stsHostName host]]];
        }
        
        if(self->_sharedSecret && !self->_sharedSecretIssurer )
        {
            self->_sharedSecretIssurer = @"owner";
        }
    }
    
    return TRUE;
}

- (NSString*) getToken
{
    NSString* fullPath = [NSString stringWithFormat:@"%@%@", [self->_serviceEndPoint absoluteString],self->_path];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString: fullPath]
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:60.0];
    
    NSString *token;
    if( [self->_sharedAccessValue length] > 0)
    {
        token = [self PrepareSharedAccessTokenWithUrl:[request URL]];
    }
    else
    {
        NSMutableURLRequest *stsRequest = [self PrepareSharedSecretTokenWithUrl:[request URL]];
        NSHTTPURLResponse* response = nil;
        NSError* requestError;
        NSData* data = [[[URLConnection alloc] init] sendSynchronousRequest:stsRequest returningResponse:&response error:&requestError];
        
        if(requestError)
        {
            NSLog(@"Fail to request token:");
            NSLog(@"Response:%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
            
            return FALSE;
        }
        else
        {
            NSInteger statusCode = [response statusCode];
            if( statusCode != 200 && statusCode != 201)
            {
                NSString* msg = [NSString stringWithFormat:@"Fail to request token. Response:%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]];
                NSLog(@"%@",msg);
                
                return FALSE;
            }
        }
        
        token = [TokenProvider ExtractToken:data];
    }
    
    return token;
}

- (BOOL) setTokenWithRequest:(NSMutableURLRequest*)request error:(NSError**)error
{
    NSString *token;
    if( [self->_sharedAccessValue length] > 0)
    {
        token = [self PrepareSharedAccessTokenWithUrl:[request URL]];
    }
    else
    {
        NSMutableURLRequest *stsRequest = [self PrepareSharedSecretTokenWithUrl:[request URL]];
        NSHTTPURLResponse* response = nil;
        NSError* requestError;
        NSData* data = [[[URLConnection alloc] init] sendSynchronousRequest:stsRequest returningResponse:&response error:&requestError];
    
        if(requestError && error)
        {
            NSLog(@"Fail to request token:");
            NSLog(@"Response:%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
        
            (*error) = requestError;
            return FALSE;
        }
        else
        {
            NSInteger statusCode = [response statusCode];
            if( statusCode != 200 && statusCode != 201)
            {
                NSString* msg = [NSString stringWithFormat:@"Fail to request token. Response:%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]];
                NSLog(@"%@",msg);
            
                if(error)
                {
                    (*error) = [NotificationHubHelper errorWithMsg:msg code:statusCode];
                }
        
                return FALSE;
            }
        }
    
        token = [TokenProvider ExtractToken:data];
    }
    
    [request addValue: token forHTTPHeaderField: @"Authorization"];
    return TRUE;
}

- (NSString *)PrepareSharedAccessTokenWithUrl:(NSURL*)url
{
    // time to live in seconds
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    int totalSeconds = interval + self->timeToExpireinMins*60;
    NSString* expiresOn = [NSString stringWithFormat:@"%d", totalSeconds];
    
    NSString* audienceUri = [url absoluteString];
    audienceUri = [[audienceUri lowercaseString] stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
    audienceUri = [[NotificationHubHelper urlEncode:audienceUri] lowercaseString];
    
    NSString* signature = [NotificationHubHelper signString:[audienceUri stringByAppendingFormat:@"\n%@",expiresOn] withKey:self->_sharedAccessValue];
    signature = [NotificationHubHelper urlEncode:signature];
    
    NSString* token = [NSString stringWithFormat:@"SharedAccessSignature sr=%@&sig=%@&se=%@&skn=%@", audienceUri, signature, expiresOn, self->_sharedAccessKeyName];
    
    return token;
}

- (NSMutableURLRequest *)PrepareSharedSecretTokenWithUrl:(NSURL*)url
{
    NSString* audienceUri = [[url absoluteString] lowercaseString];
    NSString* query = [url query];
    if(query)
    {
        audienceUri = [audienceUri substringToIndex:([audienceUri length] - [query length]-1) ];
    }
    
    audienceUri = [audienceUri stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
    audienceUri = [NotificationHubHelper urlEncode:audienceUri];
    
    //compute simpleWebToken
    NSString* issurerStr = [NSString stringWithFormat:@"Issuer=%@", self->_sharedSecretIssurer];
    NSData* secretBase64 = [NotificationHubHelper fromBase64:self->_sharedSecret];
    
    NSString* signature = [NotificationHubHelper signString:issurerStr withKeyData:secretBase64.bytes keyLength:secretBase64.length];
    signature = [NotificationHubHelper urlEncode:signature];
    
    NSString* simpleWebToken = [NSString stringWithFormat:@"Issuer=%@&HMACSHA256=%@",self->_sharedSecretIssurer,signature];
    simpleWebToken = [NotificationHubHelper urlEncode:simpleWebToken];
    
    NSString* requestBody = [NSString stringWithFormat:@"wrap_scope=%@&wrap_assertion_format=SWT&wrap_assertion=%@", audienceUri, simpleWebToken];
    
    //send request
    NSURL* stsUri = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/WRAPv0.9/",_stsHostName]];
    NSMutableURLRequest *stsRequest=[NSMutableURLRequest requestWithURL:stsUri
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:60.0];
    [stsRequest setHTTPMethod:@"POST"];
    [stsRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [stsRequest setValue:@"0" forHTTPHeaderField:@"ContentLength"];
    [stsRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    return stsRequest;
}

- (void) setTokenWithRequest:(NSMutableURLRequest*)request completion:(void (^)(NSError*))completion
{
    if( [self->_sharedAccessValue length] > 0)
    {
        [self setSharedAccessTokenWithRequest:request completion:completion];
    }
    else
    {
        [self setSharedSecretTokenAsync:request completion:completion];
    }
}

- (void) setSharedAccessTokenWithRequest: (NSMutableURLRequest*)request completion:(void (^)(NSError*))completion
{
    NSString *token = [self PrepareSharedAccessTokenWithUrl:[request URL]];
    [request addValue: token forHTTPHeaderField: @"Authorization"];
    completion(nil);
}

- (void) setSharedSecretTokenAsync: (NSMutableURLRequest*)request completion:(void (^)(NSError*))completion
{
    NSMutableURLRequest *stsRequest = [self PrepareSharedSecretTokenWithUrl:[request URL]];
    
    [[[URLConnection alloc] init] sendRequest:stsRequest completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error){
        if(error)
        {
            completion(error);
            return;
        }
        
        NSString* responseString = @"";
        if(data)
        {
            responseString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        
        NSInteger statusCode = [response statusCode];
        if( statusCode != 200 && statusCode != 201)
        {
            NSLog(@"Fail to retrieve token.");
            NSLog(@"%@",[request description]);
            NSLog(@"Headers:%@",[request allHTTPHeaderFields]);
            NSLog(@"Error Response:%@",responseString);
            
            NSString* msg = [NSString stringWithFormat:@"Fail to retrieve token. Response:%@",responseString];

            completion([NotificationHubHelper errorWithMsg:msg code:statusCode]);
            return;
        }
        
        NSString* token = [TokenProvider ExtractToken:data];
        if( [token length] == 0)
        {
            NSString* msg = [NSString stringWithFormat:@"Fail to parse token. Response:%@",responseString];
            completion([NotificationHubHelper errorWithMsg:msg code:-1]);
        }
        else
        {
            [request addValue: token forHTTPHeaderField: @"Authorization"];
            completion(nil);
        }
    } ];
}

+ (NSString *)ExtractToken:(NSData *)data
{
    NSString *expireInSeconds;
    NSString *token;
    NSString* rawStr= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *fields = [rawStr componentsSeparatedByString:@"&"];
    
    //Check size..
    if([fields count] != 2)
    {
        NSLog(@"Wrong format of received token:%@",rawStr);
        return @"";
    }
    
    for (NSString* item in fields) {
        NSArray *subItems = [item componentsSeparatedByString:@"="];
        NSString* key = [subItems objectAtIndex:0];
        NSString* value = [NotificationHubHelper urlDecode:[subItems objectAtIndex:1]];
        if([key isEqualToString:@"wrap_access_token"])
        {
            token = [NSString stringWithFormat:@"WRAP access_token=\"%@\"",value];
        }
        else
        {
            expireInSeconds = value;
        }
    }
    
    return token;
}

@end




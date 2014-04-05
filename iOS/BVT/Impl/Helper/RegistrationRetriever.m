#import "RegistrationRetriever.h"
#import "TokenProvider.h"
#import "RegistrationParser.h"
#import "URLConnection.h"
#import "TestHelper.h"

@implementation RegistrationRetriever

TokenProvider* tokenProvider;

- (RegistrationRetriever*) initWithConnectionString:(NSString*) connectionString notificationHubPath:(NSString*)notificationHubPath
{
    self = [super init];
    
    if(!connectionString || !notificationHubPath)
    {
        return nil;
    }
    
    if( self){
        NSDictionary* connnectionDictionary = [self parseConnectionString:connectionString];
        
        NSString* endPoint = [connnectionDictionary objectForKey:@"endpoint"];
        if(endPoint)
        {
            self->_serviceEndPoint = [[NSURL alloc] initWithString:endPoint];
        }
        
        if(self->_serviceEndPoint == nil || [self->_serviceEndPoint host] == nil)
        {
            NSLog(@"%@",@"Endpoint is missing or not in URL format in connectionString.");
            return nil;
        }
        
        self->_path = notificationHubPath;
        tokenProvider = [[TokenProvider alloc] initWithConnectionString:connectionString path:notificationHubPath];
        
        if(tokenProvider == nil)
        {
            return nil;
        }
    }
    
    return self;
}

- (NSString *)convertDeviceToken:(NSData *)deviceTokenData
{
    NSString* newDeviceToken = [[[[[deviceTokenData description]
                                   stringByReplacingOccurrencesOfString:@"<"withString:@""]
                                  stringByReplacingOccurrencesOfString:@">" withString:@""]
                                 stringByReplacingOccurrencesOfString: @" " withString: @""] uppercaseString];
    return newDeviceToken;
}

- (NSArray*) retrieveAllWithDeviceToken:(NSData*)deviceTokenData error:(NSError**)error
{
    NSString* deviceToken = [self convertDeviceToken:deviceTokenData];
    
    NSURL *requestUri = [self composeRetrieveAllRegistrationsUriWithDeviceToken:deviceToken];
    
    NSHTTPURLResponse* response=nil;
    NSData* data;
    NSError* operationError;
    [self registrationOperationWithRequestUri:requestUri payload:@"" httpMethod:@"GET" ETag:@"" response:&response responseData:&data error:&operationError];
    
    if(operationError)
    {
        if([operationError code]==404)
        {
            //no registrations
            return nil;
        }
        
        if( error)
        {
            (*error) = operationError;
        }
        
        return nil;
    }
    
    NSArray *registrations = [RegistrationParser parseRegistrations:data error:error];
    return registrations;
}

- (void) registrationOperationWithRequestUri:(NSURL*)requestUri payload:(NSString*)payload httpMethod:(NSString*) httpMethod ETag:(NSString*)etag completion:(void (^)(NSHTTPURLResponse *response, NSData *data, NSError *error))completion
{
    NSMutableURLRequest *theRequest = [self PrepareUrlRequest:requestUri httpMethod:httpMethod ETag:etag payload:payload];
    
    [tokenProvider setTokenWithRequest:theRequest completion:^(NSError *error) {
        if(error)
        {
            if(completion)
            {
                completion(nil,nil,error);
            }
            
            return;
        }
        
        [[[URLConnection alloc] init] sendRequest:theRequest completion:completion];
    } ];
}

- (BOOL) registrationOperationWithRequestUri:(NSURL*)requestUri payload:(NSString*)payload httpMethod:(NSString*) httpMethod ETag:(NSString*)etag response:(NSHTTPURLResponse**)response responseData:(NSData**)responseData error:(NSError**)error
{
    NSMutableURLRequest *theRequest = [self PrepareUrlRequest:requestUri httpMethod:httpMethod ETag:etag payload:payload];
    
    [tokenProvider setTokenWithRequest:theRequest error:error];
    if(*error != nil)
    {
        return FALSE;
    }
    
    //send synchronously
    (*responseData) = [[[URLConnection alloc] init] sendSynchronousRequest:theRequest returningResponse:response error:error];
    
    if(*error != nil)
    {
        NSLog(@"Fail to perform registration operation.");
        NSLog(@"%@",[theRequest description]);
        NSLog(@"Headers:%@",[theRequest allHTTPHeaderFields]);
        NSLog(@"Error Response:%@",[[NSString alloc]initWithData:(*responseData) encoding:NSUTF8StringEncoding]);
        
        return FALSE;
    }
    else
    {
        NSInteger statusCode = [(*response) statusCode];
        if( statusCode != 200 && statusCode != 201)
        {
            NSString* responseString = [[NSString alloc]initWithData:(*responseData) encoding:NSUTF8StringEncoding];
            
            if(statusCode != 404)
            {
                NSLog(@"Fail to perform registration operation.");
                NSLog(@"%@",[theRequest description]);
                NSLog(@"Headers:%@",[theRequest allHTTPHeaderFields]);
                NSLog(@"Error Response:%@",responseString);
            }
            
            if(error)
            {
                NSString* msg = [NSString stringWithFormat:@"Fail to perform registration operation. Response:%@",responseString];
                
                (*error) = [TestHelper errorWithMsg:msg code:statusCode];
            }
            
            return FALSE;
        }
    }
    
    return TRUE;
}

- (NSURL*) composeRetrieveAllRegistrationsUriWithDeviceToken:(NSString*)deviceToken
{
    NSString* APIVersion = @"2013-04";
    NSString* fullPath = [NSString stringWithFormat:@"%@%@/Registrations/?$filter=deviceToken+eq+'%@'&api-version=%@", [self->_serviceEndPoint absoluteString],self->_path, deviceToken, APIVersion];
    
    return[[NSURL alloc] initWithString: fullPath];
}

- (NSMutableURLRequest *)PrepareUrlRequest:(NSURL *)uri httpMethod:(NSString *)httpMethod ETag:(NSString*)etag payload:(NSString *)payload {
    NSMutableURLRequest *theRequest;
    theRequest = [NSMutableURLRequest requestWithURL:uri
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:60.0];
    [theRequest setHTTPMethod:httpMethod];
    
    if( [payload hasPrefix:@"{"])
    {
        [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    else
    {
        [theRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    }
    
    if( etag != nil && [etag length]>0)
    {
        if( ![etag isEqualToString:@"*"])
        {
            etag = [NSString stringWithFormat:@"\"%@\"",etag];
        }
        
        [theRequest addValue: etag forHTTPHeaderField: @"If-Match"];
    }
    
    if( [payload length]>0){
        NSString* requestBody = [NSString stringWithFormat:@"%@",payload];
        [theRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return theRequest;
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
        if([keyValuePairs count] < 2)
        {
            break;
        }
        
        NSString* keyName = [[keyValuePairs objectAtIndex: 0] lowercaseString];
        
        NSString* keyValue =[currentField substringFromIndex:([keyName length] +1)];
        if([keyName isEqualToString:@"endpoint"]){
            {
                keyValue = [[self modifyEndpoint:[NSURL URLWithString:keyValue] scheme:@"https"] absoluteString];
            }
        }
        
        [result setObject:keyValue forKey:keyName];
    }
    
    return result;
}

- (NSURL*) modifyEndpoint:(NSURL*)endPoint scheme:(NSString*)scheme
{
    NSString* modifiedEndpoint = [NSString stringWithString:[endPoint absoluteString]];
    
    if(![modifiedEndpoint hasSuffix:@"/"])
    {
        modifiedEndpoint = [NSString stringWithFormat:@"%@/",modifiedEndpoint];
    }
    
    NSInteger position = [modifiedEndpoint rangeOfString:@":"].location;
    if( position == NSNotFound)
    {
        modifiedEndpoint = [scheme stringByAppendingFormat:@"://%@",modifiedEndpoint];
    }
    else
    {
        modifiedEndpoint = [scheme stringByAppendingFormat:@"%@",[modifiedEndpoint substringFromIndex:position]];
    }
    
    return [NSURL URLWithString:modifiedEndpoint];
}

@end

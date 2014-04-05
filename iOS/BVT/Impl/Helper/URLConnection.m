#import "URLConnection.h"
#import "NotificationHubHelper.h"

@implementation URLConnection

- (void) sendRequest: (NSURLRequest*) request completion:(void (^)(NSHTTPURLResponse*,NSData*,NSError*))completion;
{
    if( self){
        self->_request = request;
        self->_completion = completion;
    }
 
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!theConnection)
    {
        NSString* msg = [NSString stringWithFormat:@"Initiate request failed for %@",[request description]];
        completion(nil,nil,[NotificationHubHelper errorWithMsg:msg code:-1]);
    }
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    return [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(!self->_completion)
    {
        return;
    }
    
    self->_response = (NSHTTPURLResponse*)response;
    
    NSInteger statusCode = [self->_response statusCode];
    if( statusCode != 200 && statusCode != 201)
    {
        if(statusCode != 404)
        {
            NSLog(@"URLRequest failed:");
            NSLog(@"URL:%@",[[self->_request URL] absoluteString]);
            NSLog(@"Headers:%@",[self->_request allHTTPHeaderFields]);
        }
        
        NSString* msg = [NSString stringWithFormat:@"URLRequest failed for %@ with status code: %@",[self->_request description], [NSHTTPURLResponse localizedStringForStatusCode:statusCode]];

        self->_completion(self->_response,nil,[NotificationHubHelper errorWithMsg:msg code:statusCode]);
        self->_completion = nil;
        return;
    }
    
    if([[self->_request HTTPMethod] isEqualToString:@"DELETE"])
    {
        self->_completion(self->_response,nil,nil);
        self->_completion =nil;
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if( self->_completion)
    {
        self->_completion(self->_response,data,nil);
        self->_completion = nil;
    }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error
{
    if(self->_completion)
    {
        self->_completion(self->_response,nil,error);
        self->_completion = nil;
    }
}

@end

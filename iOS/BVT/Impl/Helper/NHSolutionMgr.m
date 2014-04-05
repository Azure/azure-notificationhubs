#import "NHSolutionMgr.h"


@implementation NHSolutionMgrHelper

@synthesize m_issuerKey;
@synthesize m_owner;
@synthesize m_serviceNamespace;
@synthesize m_targetEnvironment;
@synthesize semaphore;
@synthesize m_responseData;
@synthesize acs_semaphore;
@synthesize createNotificationSemaphore;

- (void)CheckoutSolution:(NSString *)environmentName
{
    NSString* url = @"http://nhsolutionmgr.azurewebsites.net/csm";
    NSMutableString* urlStr = [[NSMutableString alloc] initWithString:url];
    [urlStr appendFormat:@"?%@=%@", @"TargetEnvironment", environmentName];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL: [NSURL
                                                  URLWithString:urlStr]];
    [request setHTTPMethod:@"GET"];
    
    NSURLResponse *urlResponse = nil;
    NSError *requestError;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse  error:&requestError];
    
    NSString* responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    //NSLog(@"Response from NHSolutionMgr = %@", responseStr);
    
    NSArray* chunks = [responseStr componentsSeparatedByString:@"$"];
    
    m_targetEnvironment = environmentName;
    m_serviceNamespace = [chunks objectAtIndex:0];
    m_issuerKey = [chunks objectAtIndex:1];
    m_owner = [chunks objectAtIndex:2];
    
    NSLog(@"TargetEnvironment=%@, ServiceNamespace=%@, IssuerKey=%@, Issuer=%@", m_targetEnvironment, m_serviceNamespace, m_issuerKey, m_owner);
}

-(void)CheckinSolution
{
    NSLog(@"Checking in solution %@", m_serviceNamespace);
    //Register with notification tracker.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL: [NSURL
                                                  URLWithString:@"http://nhsolutionmgr.azurewebsites.net/csm"]];
    
    NSString* payload = @"";
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
    
    NSString *conLen = [NSString stringWithFormat:@"%d", [payload length]];
    [request setValue:conLen forHTTPHeaderField:@"Content-Length"];
    [request setValue:m_targetEnvironment forHTTPHeaderField:@"X-Target-Environment"];
    
    [request setValue:m_serviceNamespace forHTTPHeaderField:@"X-Service-Namespace"];
    [request setValue:m_issuerKey forHTTPHeaderField:@"X-Issuer-Key"];
    
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[NSURLConnection alloc]
     initWithRequest:request
     delegate:self];
}

-(void)CreateNotificationHubOnServer:(NSString *)hubName defaultSasKey:(NSString *)sasKey
{
    NSLog(@"CreateNotificationhubRest with name: %@", hubName);
    createNotificationSemaphore = dispatch_semaphore_create(0);
    NSString* connString = [NSString stringWithFormat:@"http://%@.servicebus.int7.windows-int.net/%@?api-version=2013-04", m_serviceNamespace, hubName];
    NSString* authHeader = [self GetToken];
    
    createNotificationSemaphore = dispatch_semaphore_create(0);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL: [NSURL
                                                  URLWithString:connString]];
    
    NSString* payload = [NSString stringWithFormat:@"<entry xmlns=\"http://www.w3.org/2005/Atom\"><title type=\"text\">%@</title><content type=\"application/xml\"><NotificationHubDescription xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><WnsCredential><Properties><Property><Name>PackageSid</Name><Value>ms-app://s-1-15-2-1185740631-77398440-1493721689-3550961144-3662611179-2285788125-3925323875</Value></Property><Property><Name>SecretKey</Name><Value>UYq-vNxAcORTyOTl-4ImouRj4YkJdwAt</Value></Property><Property><Name>WindowsLiveEndpoint</Name><Value>http://pushtestservice2.cloudapp.net/LiveID/accesstoken.srf</Value></Property></Properties></WnsCredential><AuthorizationRules><AuthorizationRule i:type=\"SharedAccessAuthorizationRule\"><ClaimType>SharedAccessKey</ClaimType><ClaimValue>None</ClaimValue><Rights><AccessRights>Listen</AccessRights></Rights><KeyName>DefaultListenSharedAccessSignature</KeyName><PrimaryKey>%@</PrimaryKey></AuthorizationRule></AuthorizationRules></NotificationHubDescription></content></entry>", hubName, sasKey];
    
    
    
    //
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/atom+xml" forHTTPHeaderField:@"Content-type"];
    
    NSString *conLen = [NSString stringWithFormat:@"%d", [payload length]];
    [request setValue:conLen forHTTPHeaderField:@"Content-Length"];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
        
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
}

-(NSString*)GetToken
{
    NSLog(@"GetToken");
    acs_semaphore = dispatch_semaphore_create(0);
    
    NSString* acsEndPoint = [NSString stringWithFormat:@"https://%@-sb.accesscontrol.aadint.windows-int.net:443/WRAPv0.9/", m_serviceNamespace];
    NSString* realm = [NSString stringWithFormat:@"http://%@.servicebus.int7.windows-int.net/", m_serviceNamespace];
    NSString* issuerKey = (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)m_issuerKey, NULL, (CFStringRef)@"!*&=+", kCFStringEncodingUTF8);
    NSMutableString* requestStr = [[NSMutableString alloc] initWithFormat:@"wrap_name=%@&wrap_password=%@&wrap_scope=%@",@"owner", issuerKey, realm];
    NSData* requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:acsEndPoint]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSLog(@"semaphore wait start");
    
    while (dispatch_semaphore_wait(acs_semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:50]];
    }
    
    NSLog(@"semaphoe wait over");
    
    NSString* responseStr = [[NSString alloc] initWithData:m_responseData encoding:NSUTF8StringEncoding];
    NSLog(@"The response from token provider is %@", responseStr);
    
    NSArray* tokens = [responseStr componentsSeparatedByString:@"&"];
    NSArray* tokens2 = [tokens[0] componentsSeparatedByString:@"="];
    
    NSString* wrap_access_token = [NSString stringWithFormat:@"WRAP access_token=\"%@\"", tokens2[1]];
    
    //NSString* retStr = [wrap_access_token[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* retStr = (__bridge NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef) wrap_access_token, (CFStringRef)@"", kCFStringEncodingUTF8);
    
    NSLog(@"The returned string is: %@", retStr);
    
    return retStr;
    
    
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *responseCode = (NSHTTPURLResponse *)response;
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didRecieveData. response data is %@", responseStr);
    
    self.m_responseData = data;
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", [error description]);
}

-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    
    NSLog(@"connectionDidFinishLoading called");
    
    if(acs_semaphore)
    {
        dispatch_semaphore_signal(acs_semaphore);
    }
    if(createNotificationSemaphore)
    {
        dispatch_semaphore_signal(createNotificationSemaphore);
    }
}

@end

@implementation NSURLRequest (IgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
}

@end

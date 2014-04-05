#import <Foundation/Foundation.h>

@interface NHSolutionMgrHelper : NSObject

@property (strong, nonatomic) NSString *m_serviceNamespace;
@property (strong, nonatomic) NSString *m_targetEnvironment;
@property (strong, nonatomic) NSString *m_issuerKey;
@property (strong, nonatomic) NSString *m_owner;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (strong, nonatomic) dispatch_semaphore_t acs_semaphore;
@property (strong, nonatomic) NSMutableData *m_responseData;
@property (strong, nonatomic) dispatch_semaphore_t createNotificationSemaphore;

- (void)CheckoutSolution:(NSString *)environmentName;

-(void)CheckinSolution;

-(void)CreateNotificationHubOnServer:(NSString *)hubName defaultSasKey:(NSString *)sasKey;

-(NSString * )GetToken;

@end

@interface NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;

@end

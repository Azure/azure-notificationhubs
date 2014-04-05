#import <Foundation/Foundation.h>

typedef void (^URLConnectionCompletion)(NSHTTPURLResponse*,NSData*,NSError*);

@interface URLConnection : NSObject{
@private
    NSURLRequest* _request;
    NSHTTPURLResponse* _response;
    URLConnectionCompletion _completion;
}

- (void) sendRequest: (NSURLRequest*) request completion:(void (^)(NSHTTPURLResponse*,NSData*,NSError*))completion;

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end

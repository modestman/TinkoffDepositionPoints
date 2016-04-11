//
//  NetworkManager.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager
{
    NSURLSessionConfiguration* _sessionConfig;
    NSURLSession *_session;
}

+(NetworkManager *)sharedInstance
{
    static NetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NetworkManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

-(id)init
{
    if (self = [super init])
    {
        _sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:_sessionConfig];
    }
    return self;
}

-(NSURLSessionConfiguration*)sessionConfig
{
    return _sessionConfig;
}

-(void)getData:(NSURL*)url completion:(void(^)(NSData * data, NSError *error))completion
{
    [[_session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completion) completion(data,error);
    }] resume];
}

-(void)downloadFile:(NSURL*)url completion:(void(^)(NSURL* originalUrl, NSURL* locaUrl, NSError *error))completion
{
    [[_session downloadTaskWithURL: url
                 completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                     NSFileManager *fileManager = [NSFileManager defaultManager];
                     
                     NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
                     NSURL *documentsDirectory = [urls objectAtIndex:0];
                     
                     NSURL *originalUrl = [NSURL URLWithString:[url lastPathComponent]];
                     NSURL *destinationUrl = [documentsDirectory URLByAppendingPathComponent:[originalUrl lastPathComponent]];
                     NSError *fileManagerError;
                     
                     [fileManager removeItemAtURL:destinationUrl error:NULL];
                     [fileManager copyItemAtURL:location toURL:destinationUrl error:&fileManagerError];
                     
                     if (completion) completion(url, destinationUrl, error);
                     
                 }] resume];
}

-(NSData*)getDataSynchronously:(NSURL*)url lastModified:(NSDate**)date error:(NSError**)error
{
    __block NSData *_data = nil;
    __block NSDate *_date = nil;
    __block NSError *_error = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[_session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        _error = error;
        _data = data;
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
        if (!error && httpResp)
        {
            NSString *lastModifiedDateStr = httpResp.allHeaderFields[@"Last-Modified"];
            if (lastModifiedDateStr)
            {
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
                _date = [dateFormatter dateFromString:lastModifiedDateStr];
            }
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (error != NULL) *error = _error;
    if (date != NULL) *date = _date;
    return _data;
}

-(NSDate*)getLastModifiedDateSynchronously:(NSURL*)url
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDate *_date;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data,
                                                                                          NSURLResponse * _Nullable response,
                                                                                          NSError * _Nullable error) {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
        if (!error && httpResp)
        {
            NSString *lastModifiedDateStr = httpResp.allHeaderFields[@"Last-Modified"];
            if (lastModifiedDateStr)
            {
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
                _date = [dateFormatter dateFromString:lastModifiedDateStr];
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return _date;
}

@end

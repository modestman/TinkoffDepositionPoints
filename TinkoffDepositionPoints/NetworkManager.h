//
//  NetworkManager.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+(NetworkManager *)sharedInstance;

@property (nonatomic, readonly, strong) NSURLSessionConfiguration* sessionConfig;

-(void)getData:(NSURL*)url completion:(void(^)(NSData * data, NSError *error))completion;
-(void)downloadFile:(NSURL*)url completion:(void(^)(NSURL* originalUrl, NSURL* locaUrl, NSError *error))completion;

-(NSData*)getDataSynchronously:(NSURL*)url lastModified:(NSDate**)date error:(NSError**)error;
-(NSDate*)getLastModifiedDateSynchronously:(NSURL*)url;

@end

//
//  TinkoffApi.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TinkoffApi : NSObject

+(NSURL*)depositionPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius;
+(NSURL*)depositionPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius andPartner:(NSString*)partner;
+(NSURL*)depositionPartners;
+(NSURL*)pictureForName:(NSString*)pictureName;

@end

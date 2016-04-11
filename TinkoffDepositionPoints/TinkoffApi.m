//
//  TinkoffApi.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "TinkoffApi.h"
#import <UIKit/UIKit.h>

NSString* const kProtocol = @"https";
NSString* const kDomain = @"api.tinkoff.ru";
NSString* const kApiVersion = @"v1";

@implementation TinkoffApi

+(NSURL*)depositionPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius
{
    // https://api.tinkoff.ru/v1/deposition_points?latitude=55.755786&longitude=37.617633&radius=1000
    
    return [self depositionPointsForLatitude:lat longitude:lon radius:radius andPartner:nil];
}

+(NSURL*)depositionPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius andPartner:(NSString*)partner
{
    // https://api.tinkoff.ru/v1/deposition_points?latitude=55.755786&longitude=37.617633&partners=EUROSET&radius=1000
    
    NSInteger rad = (NSInteger)floor(radius);
    NSDictionary *parameters = @{@"latitude": [NSNumber numberWithDouble:lat],
                                 @"longitude": [NSNumber numberWithDouble:lon],
                                 @"radius": [NSNumber numberWithInteger:rad],
                                 @"partners": partner ? partner : [NSNull null]};
    
    NSString *template = @"%@://%@/%@/deposition_points?%@";
    NSString *url = [NSString stringWithFormat:template, kProtocol, kDomain, kApiVersion, [self parametersStringFromDictionary:parameters]];
    return [NSURL URLWithString:url];
}

+(NSURL*)depositionPartners
{
    // https://api.tinkoff.ru/v1/deposition_partners?accountType=Credit
    NSDictionary *parameters = @{@"accountType": @"Credit"};
    NSString *template = @"%@://%@/%@/deposition_partners?%@";
    NSString *url = [NSString stringWithFormat:template, kProtocol, kDomain, kApiVersion, [self parametersStringFromDictionary:parameters]];
    return [NSURL URLWithString:url];
}

+(NSURL*)pictureForName:(NSString*)pictureName
{
    // https://static.tinkoff.ru/icons/deposition-partners-v3/{dpi}/contact.png
    
    NSString *dpiLabel;
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale == 1.0)
        dpiLabel = @"mdpi";
    else if (scale == 2.0)
        dpiLabel = @"xhdpi";
    else if (scale == 3.0)
        dpiLabel = @"xxhdpi";
    
    NSString *template = @"https://static.tinkoff.ru/icons/deposition-partners-v3/%@/%@";
    NSString *url = [NSString stringWithFormat:template, dpiLabel, pictureName];
    return [NSURL URLWithString:url];
}

+(NSString*)parametersStringFromDictionary:(NSDictionary*)params
{
    NSNumberFormatter *fmt = [NSNumberFormatter new];
    fmt.maximumFractionDigits = 5;
    fmt.decimalSeparator = @".";
    NSString *result = @"";
    for (NSString *key in [params allKeys])
    {
        if (![params[key] isEqual:[NSNull null]])
        {
            NSString *value;
            if ([params[key] isKindOfClass:[NSNumber class]])
                value = [fmt stringFromNumber:params[key]];
            else
                value = [params[key] description];
            
            result = [result stringByAppendingFormat:@"%@=%@&", key, value];
        }
    }
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    return result;
}

@end

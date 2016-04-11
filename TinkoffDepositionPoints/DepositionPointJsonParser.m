//
//  DepositionPointJsonParser.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "DepositionPointJsonParser.h"
#import "DataManager.h"
#import "DepositionPoint.h"
#import "DepositionPartner.h"

@implementation DepositionPointJsonParser
{
    NSNumberFormatter *fmt;
    NSManagedObjectContext *context;
    NSMutableDictionary *partners;
}

-(id)init
{
    self = [super init];
    if (self)
    {
        fmt = [NSNumberFormatter new];
        fmt.maximumFractionDigits = 5;
        fmt.decimalSeparator = @".";
        
        partners = [NSMutableDictionary new];
    }
    return self;
}

- (void)parseData:(NSData*) data
{
    NSError *error;
    NSDictionary *rootElement = [NSJSONSerialization  JSONObjectWithData:data options:0 error:&error];
    if (error)
    {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    NSString *resultCode = rootElement[@"resultCode"];
    if (![resultCode isEqualToString:@"OK"])
    {
        NSLog(@"%@", rootElement[@"errorMessage"]);
        return;
    }
    
    NSArray *payload = rootElement[@"payload"];
    
    context = [DataManager sharedInstance].managedObjectContext;
    
    for (NSDictionary *pointDesc in payload)
    {
        NSDictionary *location = pointDesc[@"location"];
        DepositionPoint *point = [self getPointForLatitude:location[@"latitude"] andLongitude:location[@"longitude"]];
        point.bankInfo = pointDesc[@"bankInfo"];
        point.bankName = pointDesc[@"bankName"];
        point.fullAddress = pointDesc[@"fullAddress"];
        point.partnerName = pointDesc[@"partnerName"];
        point.phones = pointDesc[@"phones"];
        point.verificationInfo = pointDesc[@"verificationInfo"];
        point.workHours = pointDesc[@"workHours"];
        
        DepositionPartner *partner = [self getPartnerById:point.partnerName];
        if (partner != nil)
        {
            [partner addPointsObject:point];
        }
    }
    
    [[DataManager sharedInstance] saveContext:context];
}

-(DepositionPoint*)getPointForLatitude:(NSNumber *)lat andLongitude:(NSNumber*)lon
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DepositionPoint" inManagedObjectContext:context];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"abs(latitude - %lf) < %lf AND abs(longitude - %lf) < %lf",
                              [lat doubleValue], DBL_EPSILON, [lon doubleValue], DBL_EPSILON];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    
    DepositionPoint *point;
    if ([arr count] > 0)
    {
        point = [arr lastObject];
    }
    else
    {
        // Create new object if not exist
        point = [NSEntityDescription insertNewObjectForEntityForName:@"DepositionPoint"
                                               inManagedObjectContext:context];
        
        point.latitude = lat;
        point.longitude = lon;
    }
    return point;
}

-(DepositionPartner*)getPartnerById:(NSString*)partnerId
{
    DepositionPartner *partner = nil;
    if ([partners objectForKey:partnerId] != nil)
    {
        partner = partners[partnerId];
    }
    else
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DepositionPartner" inManagedObjectContext:context];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", partnerId];
        [request setEntity:entity];
        [request setPredicate:predicate];
        NSArray *arr = [context executeFetchRequest:request error:nil];
        if ([arr count] > 0)
        {
            partner = [arr lastObject];
            [partners setObject:partner forKey:partnerId];
        }
    }
    return partner;
}

@end

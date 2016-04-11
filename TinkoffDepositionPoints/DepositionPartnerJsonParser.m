//
//  DepositionPartnerJsonParser.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 09.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "DepositionPartnerJsonParser.h"
#import "DataManager.h"
#import "DepositionPartner.h"

@implementation DepositionPartnerJsonParser
{
    NSNumberFormatter *fmt;
    NSManagedObjectContext *context;
}

- (void)parseData:(NSData*) data
{
    NSError *error;
    NSDictionary *rootElement = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
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
    
    for (NSDictionary *partnerDesc in payload)
    {
        DepositionPartner *partner = [self getPartnerById:partnerDesc[@"id"]];
        partner.depositionDuration = partnerDesc[@"depositionDuration"];
        partner.description_ = partnerDesc[@"description"];
        partner.externalPartnerId = partnerDesc[@"externalPartnerId"];
        partner.hasLocations = partnerDesc[@"hasLocations"];
        partner.hasPreferentialDeposition = partnerDesc[@"hasPreferentialDeposition"];
        partner.isMomentary = partnerDesc[@"isMomentary"];
        partner.limitations = partnerDesc[@"limitations"];
        partner.moneyMax = partnerDesc[@"moneyMax"];
        partner.moneyMin = partnerDesc[@"moneyMin"];
        partner.name = partnerDesc[@"name"];
        partner.picture = partnerDesc[@"picture"];
        partner.pointType = partnerDesc[@"pointType"];
        partner.url = partnerDesc[@"url"];
    }
    
    [[DataManager sharedInstance] saveContext:context];
}

-(DepositionPartner*)getPartnerById:(NSString*)partnerId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DepositionPartner" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", partnerId];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *arr = [context executeFetchRequest:request error:nil];
    
    DepositionPartner *partner;
    if ([arr count] > 0)
    {
        partner = [arr lastObject];
    }
    else
    {
        // Create new object if not exist
        partner = [NSEntityDescription insertNewObjectForEntityForName:@"DepositionPartner"
                                              inManagedObjectContext:context];
        
        partner.id = partnerId;
    }
    return partner;
}

@end

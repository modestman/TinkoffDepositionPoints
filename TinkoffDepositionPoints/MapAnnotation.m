//
//  MapAnnotation.m
//  TestProject
//
//  Created by Admin on 21.03.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation
{
    
}

@synthesize coordinate = _coordinate;
@synthesize title, subtitle;

-(id)initWithLatittude:(double)lat andLongitude:(double)lon
{
    if (self = [super init])
    {
        _coordinate = CLLocationCoordinate2DMake(lat, lon);
    }
    return self;
}

@end

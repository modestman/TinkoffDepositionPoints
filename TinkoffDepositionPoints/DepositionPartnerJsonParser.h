//
//  DepositionPartnerJsonParser.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 09.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DepositionPartnerJsonParser : NSObject

- (void) parseData:(NSData*) data;

@end

//
//  DepositionPointJsonParser.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DepositionPointJsonParser : NSObject

- (void) parseData:(NSData*) data;

@end

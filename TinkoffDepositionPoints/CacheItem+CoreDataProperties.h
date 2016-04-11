//
//  CacheItem+CoreDataProperties.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 10.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CacheItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CacheItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSDate *lastModified;
@property (nullable, nonatomic, retain) NSData *data;

@end

NS_ASSUME_NONNULL_END

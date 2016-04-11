//
//  DepositionPartner+CoreDataProperties.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 08.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DepositionPartner.h"

NS_ASSUME_NONNULL_BEGIN

@interface DepositionPartner (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *depositionDuration;
@property (nullable, nonatomic, retain) NSString *description_;
@property (nullable, nonatomic, retain) NSString *externalPartnerId;
@property (nullable, nonatomic, retain) NSNumber *hasLocations;
@property (nullable, nonatomic, retain) NSNumber *hasPreferentialDeposition;
@property (nullable, nonatomic, retain) NSString *id;
@property (nullable, nonatomic, retain) NSNumber *isMomentary;
@property (nullable, nonatomic, retain) NSString *limitations;
@property (nullable, nonatomic, retain) NSNumber *moneyMax;
@property (nullable, nonatomic, retain) NSNumber *moneyMin;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *picture;
@property (nullable, nonatomic, retain) NSString *pointType;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSSet<DepositionPoint *> *points;

@end

@interface DepositionPartner (CoreDataGeneratedAccessors)

- (void)addPointsObject:(DepositionPoint *)value;
- (void)removePointsObject:(DepositionPoint *)value;
- (void)addPoints:(NSSet<DepositionPoint *> *)values;
- (void)removePoints:(NSSet<DepositionPoint *> *)values;

@end

NS_ASSUME_NONNULL_END

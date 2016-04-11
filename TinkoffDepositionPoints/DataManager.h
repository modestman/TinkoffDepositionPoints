//
//  DataManager.h
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>


extern NSString* const DepositionPointsUpdatedNotificationName;
extern NSString* const DepositionPartnersUpdatedNotificationName;

@interface DataManager : NSObject


@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


+(DataManager *)sharedInstance;
- (void)initLocalDataStorage;
- (void)saveContext;
-(BOOL)saveContext:(NSManagedObjectContext*)context;

-(void)loadPartners;
-(void)loadPictureForPartner:(NSString*)picName completion:(void(^)(UIImage *image, NSError *error))completion;

/// get points from local cache
-(NSArray*)getPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius;

/// send request for new points and return current available points
-(void)beginGetDataForLatitude:(double)lat longitude:(double)lon radius:(double)radius
                    completion:(void(^)(NSArray *points, NSError *error))completion;


@end

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

@interface DataManager : NSObject


@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


+(DataManager *)sharedInstance;
- (void) initLocalDataStorage;
-(BOOL)saveContext:(NSManagedObjectContext*)context;

-(void)loadPartners;
-(NSArray*)getPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius;
-(void)beginGetDataForLatitude:(double)lat longitude:(double)lon radius:(double)radius
                    completion:(void(^)(NSArray *points, NSError *error))completion;
-(void)loadPictureForPartner:(NSString*)picName completion:(void(^)(UIImage *image, NSError *error))completion;

@end

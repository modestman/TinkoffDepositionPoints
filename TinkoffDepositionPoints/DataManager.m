//
//  DataManager.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "DataManager.h"
#import "NetworkManager.h"
#import "TinkoffApi.h"
#import "DepositionPointJsonParser.h"
#import "DepositionPartnerJsonParser.h"
#import "DepositionPoint.h"
#import "DepositionPartner.h"
#import "CacheItem.h"
#import <CoreLocation/CoreLocation.h>


NSString* const DepositionPointsUpdatedNotificationName = @"DepositionPointsUpdated";
NSString* const DepositionPartnersUpdatedNotificationName = @"DepositionPartnersUpdated";

@interface DataManager()
{
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSMutableDictionary *threadMOCs;
    
    NSOperationQueue *parseQueue;
    NSOperationQueue *getImageQueue;
}
@end

@implementation DataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


+(DataManager *)sharedInstance
{
    static DataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DataManager alloc] init];
    });
    return sharedInstance;
}

-(id)init
{
    if (self = [super init])
    {
        threadMOCs = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(threadExit)
                                                     name:NSThreadWillExitNotification
                                                   object:nil];

        parseQueue = [NSOperationQueue new];
        parseQueue.maxConcurrentOperationCount = 1;
        getImageQueue = [NSOperationQueue new];
        getImageQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void) initLocalDataStorage
{
    [self createMainMOC];
    [self loadPartners];
}

#pragma mark - Core Data stack

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationCachesDirectory] URLByAppendingPathComponent:@"TinkoffDepositionPoints.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TinkoffDepositionPoints" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext)
    {
        if (![[NSThread currentThread] isMainThread])
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self createMainMOC];
            });
        }
        else
        {
            [self createMainMOC];
        }
        
    }
    return [self getMOCFor:[NSThread currentThread]];
}

-(void) createMainMOC
{
    if (_managedObjectContext)
        return;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
}

- (NSManagedObjectContext *)getMOCFor:(NSThread *) thread
{
    if ([thread isMainThread])
    {
        return _managedObjectContext;
    }
    @synchronized(threadMOCs)
    {
        NSNumber *threadHash = [NSNumber numberWithUnsignedInteger:[thread hash]];
        if ([threadMOCs objectForKey:threadHash] == nil)
        {
            NSManagedObjectContext *newMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            newMoc.parentContext = _managedObjectContext;
            [threadMOCs setObject:newMoc forKey:threadHash];
        }
        return [threadMOCs objectForKey:threadHash];
    }
}

-(void)threadExit
{
    @synchronized(threadMOCs)
    {
        [threadMOCs removeObjectForKey:@([NSThread currentThread].hash)];
    }
}

- (void)saveContext
{
    [self saveContext:self.managedObjectContext];
}

-(BOOL)saveContext:(NSManagedObjectContext*)context
{
    if (context == nil) return NO;
    
    NSError *error;
    __block BOOL result = [context save:&error];
    if (result)
    {
        [context.parentContext performBlockAndWait:^{
            NSError *parentError;
            result = [context.parentContext save:&parentError];
            if (!result)
                NSLog(@"unable to save parent context: %@", parentError);
        }];
    }
    else
        NSLog(@"unable to save context: %@", error);
    [context reset];
    return result;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

// Returns the URL to the application's Caches directory.
- (NSURL *)applicationCachesDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Business logic

-(void)loadPartners
{
    NSURL *requestUrl = [TinkoffApi depositionPartners];
    [[NetworkManager sharedInstance] getData:requestUrl completion:^(NSData *data, NSError *error) {
        if (!error && [data length] > 0)
        {
            [parseQueue addOperationWithBlock:^{
                DepositionPartnerJsonParser *parser = [DepositionPartnerJsonParser new];
                [parser parseData:data];
                [[NSNotificationCenter defaultCenter] postNotificationName:DepositionPartnersUpdatedNotificationName object:nil];
            }];
        }
    }];
}

-(void)loadPictureForPartner:(NSString*)picName completion:(void(^)(UIImage *image, NSError *error))completion
{
    [getImageQueue addOperationWithBlock:^{
        
        NSURL *pictureRequestUrl = [TinkoffApi pictureForName:picName];
        
        // Fetch cache item from Core Data
        NSManagedObjectContext *moc = [DataManager sharedInstance].managedObjectContext;
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CacheItem" inManagedObjectContext:moc];
        NSFetchRequest *request = [NSFetchRequest new];
        [request setEntity:entity];
        request.predicate = [NSPredicate predicateWithFormat: @"url = %@", pictureRequestUrl.absoluteString];
        CacheItem *cacheItem;
        NSError *error;
        NSArray *cache = [moc executeFetchRequest:request error:&error];
        
        if (!error && [cache count] > 0)
        {
            cacheItem = [cache firstObject];
            // get file date on the server
            NSDate *lastModified = [[NetworkManager sharedInstance] getLastModifiedDateSynchronously:pictureRequestUrl];
            if ([cacheItem.lastModified compare: lastModified] == NSOrderedAscending)
            {
                // download new file
                NSData *data = [[NetworkManager sharedInstance] getDataSynchronously:pictureRequestUrl lastModified:&lastModified error:&error];
                if (!error)
                {
                    cacheItem.url = [pictureRequestUrl absoluteString];
                    cacheItem.data = data;
                    cacheItem.lastModified = lastModified;
                    [self saveContext:moc];
                    if (completion) completion([UIImage imageWithData:cacheItem.data], nil);
                }
            }
            else
            {
                // we have latest version
                if (completion) completion([UIImage imageWithData:cacheItem.data], nil);
            }
        }
        else
        {
            // create new
            cacheItem = [NSEntityDescription insertNewObjectForEntityForName:entity.name
                                                      inManagedObjectContext:moc];
            NSDate *lastModified;
            NSData *data = [[NetworkManager sharedInstance] getDataSynchronously:pictureRequestUrl lastModified:&lastModified error:&error];
            if (!error)
            {
                cacheItem.url = [pictureRequestUrl absoluteString];
                cacheItem.data = data;
                cacheItem.lastModified = lastModified;
                [self saveContext:moc];
                if (completion) completion([UIImage imageWithData:cacheItem.data], nil);
            }
            else
            {
                if (completion) completion(nil, error);
            }
        }
    }];
}

-(void)beginGetDataForLatitude:(double)lat longitude:(double)lon radius:(double)radius
                    completion:(void(^)(NSArray *points, NSError *error))completion
{
    // request new data
    NSURL *requestUrl = [TinkoffApi depositionPointsForLatitude:lat longitude:lon radius:radius];
    [[NetworkManager sharedInstance] getData:requestUrl completion:^(NSData *data, NSError *error) {
        if (!error && [data length] > 0)
        {
            // parse data and save to db
            [parseQueue addOperationWithBlock:^{
                DepositionPointJsonParser *parser = [DepositionPointJsonParser new];
                [parser parseData:data];
                // notification about new data ready
                [[NSNotificationCenter defaultCenter] postNotificationName:DepositionPointsUpdatedNotificationName object:nil];
            }];
        }
    }];
    
    // fetch and return cached data
    dispatch_queue_t queue = dispatch_queue_create("fetchData", nil);
    dispatch_async(queue, ^{
        
        NSArray *points = [self getPointsForLatitude:lat longitude:lon radius:radius];
        completion(points, nil);
    });
}

-(NSArray*)getPointsForLatitude:(double)lat longitude:(double)lon radius:(double)radius
{
    // WARNING: This math is broken when we’re close to the 180° meridian
    double D = radius * 2;
    double const R = 6371009.; // Earth readius in meters
    double meanLatitidue = lat * M_PI / 180.;
    double deltaLatitude = D / R * 180. / M_PI;
    double deltaLongitude = D / (R * cos(meanLatitidue)) * 180. / M_PI;
    double minLatitude = lat - deltaLatitude;
    double maxLatitude = lat + deltaLatitude;
    double minLongitude = lon - deltaLongitude;
    double maxLongitude = lon + deltaLongitude;
    
    // Request points for square region
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DepositionPoint" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity:entity];
    request.predicate = [NSPredicate predicateWithFormat:
                      @"(%@ <= longitude) AND (longitude <= %@)"
                      @"AND (%@ <= latitude) AND (latitude <= %@)",
                      @(minLongitude), @(maxLongitude), @(minLatitude), @(maxLatitude)];
    request.returnsObjectsAsFaults = NO;
    
    NSError *error = nil;
    NSArray *points = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSAssert(points != nil, @"Failed to execute %@: %@", request, error);
    
    // Filter the points by distance from our center
    CLLocation *center = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    NSPredicate *exactPredicate = [self exactLatitudeAndLongitudePredicateForCoordinate:center andDistance:radius];
    points = [points filteredArrayUsingPredicate:exactPredicate];
    
    return points;
}

- (NSPredicate *)exactLatitudeAndLongitudePredicateForCoordinate:(CLLocation*)location andDistance:(double)d;
{
    return [NSPredicate predicateWithBlock:^BOOL(DepositionPoint *point, NSDictionary *bindings) {
        CLLocation *evaluatedLocation = [[CLLocation alloc] initWithLatitude:[point.latitude doubleValue]
                                                                   longitude:[point.longitude doubleValue]];
        CLLocationDistance distance = [location distanceFromLocation:evaluatedLocation];
        return (distance < d);
    }];
}

@end

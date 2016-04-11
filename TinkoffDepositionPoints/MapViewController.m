//
//  ViewController.m
//  TinkoffDepositionPoints
//
//  Created by Admin on 07.04.16.
//  Copyright © 2016 Anton Glezman. All rights reserved.
//

#import "MapViewController.h"
#import "DataManager.h"
#import "DepositionPoint.h"
#import "DepositionPartner.h"
#import "MapAnnotation.h"

@interface MapViewController ()
{
    CLLocationManager *locationManager;
    BOOL allowUserLocation;
    NSMutableDictionary<NSManagedObjectID*, id<MKAnnotation>> *pointsOnMap;
    NSMutableDictionary<NSString*, UIImage*> *partnerPictures;
}
@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    pointsOnMap = [NSMutableDictionary new];
    partnerPictures = [NSMutableDictionary new];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([self checkUserLocation] == kCLAuthorizationStatusNotDetermined)
    {
        [locationManager requestWhenInUseAuthorization];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePoints:) name:@"DepositionPointsUpdated" object:nil];
    
    /*****  Debug ****/
    MKCoordinateSpan span;
    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.02;
    MKCoordinateRegion region;
    region.span = span;
    region.center = CLLocationCoordinate2DMake(55.751, 37.620417);
    [self.mapView setRegion:region animated:NO];
    /****************/
    
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self checkUserLocation];
}

-(CLAuthorizationStatus)checkUserLocation
{
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        allowUserLocation = YES;
        self.mapView.showsUserLocation = YES;
    }
    else
    {
        allowUserLocation = NO;
    }
    return authorizationStatus;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(CLLocationDistance)distanceBetweenPoint:(CLLocationCoordinate2D)point1 andPoint:(CLLocationCoordinate2D)point2
{
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:point1.latitude longitude:point1.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:point2.latitude longitude:point2.longitude];
    return [loc1 distanceFromLocation:loc2];
}

- (IBAction)zoomIn:(id)sender
{
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    region.center.latitude = self.mapView.region.center.latitude;
    region.center.longitude = self.mapView.region.center.longitude;
    span.latitudeDelta = self.mapView.region.span.latitudeDelta / 2.0;
    span.longitudeDelta = self.mapView.region.span.longitudeDelta / 2.0;
    region.span=span;
    [self.mapView setRegion:region animated:TRUE];
}

- (IBAction)zoomOut:(id)sender
{
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    region.center.latitude = self.mapView.region.center.latitude;
    region.center.longitude = self.mapView.region.center.longitude;
    span.latitudeDelta=self.mapView.region.span.latitudeDelta * 2;
    span.longitudeDelta=self.mapView.region.span.longitudeDelta * 2;
    if(span.latitudeDelta < 200)
    {
        region.span=span;
        [self.mapView setRegion:region animated:TRUE];
    }
}

- (IBAction)showCurrentLocation:(id)sender
{
    if (allowUserLocation)
    {
        [self.mapView setCenterCoordinate:locationManager.location.coordinate animated:YES];
    }
}

#pragma mark - MapView Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
{
    [self loadPointsForCurrentRegion];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *identifier = @"MapAnnotationView";
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKPinAnnotationView *view = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (view)
    {
        view.annotation = annotation;
        
    }
    else
    {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        view.canShowCallout = YES;
        view.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    }

    MapAnnotation *ant = annotation;
    if (partnerPictures[ant.picture] != nil)
    {
        ((UIImageView*)view.leftCalloutAccessoryView).image = partnerPictures[ant.picture];
    }
    else
    {
        [[DataManager sharedInstance] loadPictureForPartner:ant.picture completion:^(UIImage *image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((UIImageView*)view.leftCalloutAccessoryView).image = image;
                [partnerPictures setObject:image forKey:ant.picture];
            });
        }];
    }
    return view;
}

-(void)loadPointsForCurrentRegion
{
    CLLocationCoordinate2D centerLoc = self.mapView.region.center;
    CLLocationCoordinate2D topLeftLoc;
    topLeftLoc = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    CLLocationDistance radius = [self distanceBetweenPoint:centerLoc andPoint:topLeftLoc];
    if (radius > 1000000) return; // quick fix
    
    [[DataManager sharedInstance] beginGetDataForLatitude:centerLoc.latitude longitude:centerLoc.longitude
                                                   radius:radius completion:^(NSArray *points, NSError *error) {
       if (!error)
       {
           // здесь получаем данные из кэша
           NSArray *annotations = [self makeAnnotationsFromPoints:points];
           [self updateMapViewAnnotationsWithAnnotations:annotations];
       }
   }];
}

-(void)updatePoints:(NSNotification*)ntf
{
    CLLocationCoordinate2D centerLoc = self.mapView.region.center;
    CLLocationCoordinate2D topLeftLoc;
    topLeftLoc = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    CLLocationDistance radius = [self distanceBetweenPoint:centerLoc andPoint:topLeftLoc];
    
    dispatch_queue_t queue = dispatch_queue_create("updateAnnotation", NULL);
    dispatch_async(queue, ^{
        NSArray *points = [[DataManager sharedInstance] getPointsForLatitude:centerLoc.latitude longitude:centerLoc.longitude radius:radius];
        NSArray *annotations = [self makeAnnotationsFromPoints:points];
        [self updateMapViewAnnotationsWithAnnotations:annotations];
        
    });
}

-(NSArray*)makeAnnotationsFromPoints:(NSArray*)points
{
    NSMutableArray *annotations = [NSMutableArray new];
    for (DepositionPoint *point in points)
    {
        MapAnnotation *annotation = [[MapAnnotation alloc] initWithLatittude:[point.latitude doubleValue]
                                                                andLongitude:[point.longitude doubleValue]];
        annotation.picture = ((DepositionPartner*)point.partner).picture;
        annotation.title = ((DepositionPartner*)point.partner).name;
        annotation.subtitle = point.workHours;
        [annotations addObject:annotation];
    }
    return annotations;
}

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    }];
}

@end

//
//  ViewController.m
//  Test_ezlogz
//
//  Created by Admin on 28.12.17.
//  Copyright © 2017 Tsvigun Aleksander. All rights reserved.
//

#import "ViewController.h"
#import "TSPoint.h"
#import "TSPrefixHeader.pch"

#import <GoogleMaps/GoogleMaps.h>

@interface ViewController ()

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) NSMutableArray *routePoints;
@property (strong, nonatomic) NSMutableArray *randomPoints;
@property (strong, nonatomic) NSDate *methodStart;
@property (assign, nonatomic) NSInteger discardedPoints;

@end

@implementation ViewController

- (void)loadView {
  
    _methodStart = [NSDate date];
    CGFloat zoom = 0;
    
    _routePoints = [NSMutableArray array];
    _randomPoints = [NSMutableArray array];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        zoom = 3.2;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        zoom = 4.4;
    }

    GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:32.8 longitude:-96.8 zoom:zoom];
    
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:cameraPosition];
    _mapView.myLocationEnabled = YES;
    
    GMSMarker *firstMarker = [[GMSMarker alloc] init];
    firstMarker.position = CLLocationCoordinate2DMake(kfirstLocationLatitude, kfirstLocationLongitude);
    firstMarker.icon = [UIImage imageNamed:@"purp_pin"];
    firstMarker.groundAnchor = CGPointMake(0.5, 0.5);
    firstMarker.map = _mapView;
    
    GMSMarker *lastMarker = [[GMSMarker alloc] init];
    lastMarker.position = CLLocationCoordinate2DMake(klastLocationLatitude, klastLocationLongitude);
    lastMarker.icon = [UIImage imageNamed:@"green_pin"];
    lastMarker.groundAnchor = CGPointMake(0.5, 0.5);
    lastMarker.map = _mapView;
    
    //calculation of the average distance between points on the route
    [self calculatingAverageDistanceBetweenPoints];
}

- (void)calculatingAverageDistanceBetweenPoints
{
    CLLocation *firstLocation = [[CLLocation alloc] initWithLatitude:kfirstLocationLatitude longitude:kfirstLocationLongitude];
    CLLocation *lastLocation = [[CLLocation alloc] initWithLatitude:klastLocationLatitude longitude:klastLocationLongitude];
    
    float averageDistance = ([firstLocation distanceFromLocation:lastLocation] / kMile) / kMax;
    _discardedPoints = kDeviation / averageDistance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    GMSMutablePath *path = [GMSMutablePath path];
    
    //create array points
    [self createArrayWithPointsRouteByPoints];
    //add route
    [self addRouteWithPath:path];
    //create Random Points
    [self createRandomPoints];
    //determine the intersection of points, with definition of superfluous points
    [self determineIntersectionAndDisplayPoints:_routePoints];
    
//    [self determineIntersectionAndDisplayPoints2:_routePoints];
    
    GMSPolyline *rectangle = [GMSPolyline polylineWithPath:path];
    rectangle.strokeWidth = 2.f;
    rectangle.map = _mapView;
    self.view = _mapView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createArrayWithPointsRouteByPoints
{
    CGFloat rangeLongitude = klastLocationLongitude - kfirstLocationLongitude;
    CGFloat stepLatitude = kStepLatitude;
    CGFloat stepLongitude = (rangeLongitude / kMax);
    
    for (int i = 0; i < kMax; i++) {
        TSPoint *point = [[TSPoint alloc] init];
        if (i == 0) {
            point.latitude = kfirstLocationLatitude;
            point.longitude = kfirstLocationLongitude;
        } else if (i == (kMax - 1)) {
            point.latitude = klastLocationLatitude;
            point.longitude = klastLocationLongitude;
        } else {
            if (arc4random_uniform(1000) > 500) {
                stepLatitude = stepLatitude;
            } else {
                stepLatitude = -stepLatitude;
            }
            if (arc4random_uniform(1000) > 500) {
                stepLatitude = stepLatitude + floatingCorrection;
            } else {
                stepLatitude = stepLatitude - floatingCorrection;
            }
            [self deviationFromCoordinatesLastPoint:point
                                          increment:i step:stepLatitude step:stepLongitude];
        }
        [_routePoints addObject:point];
    }
}

- (void)addRouteWithPath:(GMSMutablePath *)path
{
    for (TSPoint *point in _routePoints) {
        [path addCoordinate:CLLocationCoordinate2DMake(@(point.latitude).doubleValue,@(point.longitude).doubleValue)];
    }
}

- (void)createRandomPoints
{
    for (int i = 0; i < kMax; i++) {
        TSPoint *randomPoint = [[TSPoint alloc] init];
        randomPoint.latitude = [self randomFloatBetween:kUpperBoundLatitude
                                                    and:kLowerBoundLatitude];
        randomPoint.longitude = [self randomFloatBetween:kUpperBoundLongitude
                                                     and:kLowerBoundLongitude];
        [_randomPoints addObject:randomPoint];
    }
}

- (void)deviationFromCoordinatesLastPoint:(TSPoint *)point
                                increment:(int)increment
                                     step:(CGFloat)stepLatitude
                                     step:(CGFloat)stepLongitude {
    
    TSPoint *lastPoint = [_routePoints objectAtIndex:increment - 1];
    point.latitude = lastPoint.latitude + stepLatitude;
    float offsetCorrection = (stepLongitude * increment);
    point.longitude = kfirstLocationLongitude + offsetCorrection;
    float fissionResidue = increment % 10;
    if (fissionResidue == 0) {
        point.latitude = point.latitude + kOffsetLastPoint;
    }
}

- (float)randomFloatBetween:(float)lowerBound and:(float)upperBound {
    float diff = upperBound - lowerBound;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + lowerBound;
}

- (void)determineIntersectionAndDisplayPoints:(NSMutableArray *)array
{
    NSInteger offset = -1;
    NSInteger counter = 0;
    for (int i = 0; i < array.count; i++) {
        TSPoint *routPoint = array[i];
        CLLocation *routePointLocation = [[CLLocation alloc] initWithLatitude:routPoint.latitude longitude:routPoint.longitude];
        if (i == offset && counter != _discardedPoints) {
            offset = (offset + 1);
            ++counter;
            continue;
        }
        if (counter == _discardedPoints) {
            counter = 0;
        }
        for (int j = 0; j < _randomPoints.count; j++) {
            TSPoint *randomPoint = _randomPoints[j];
            CLLocation *randomPointLocation = [[CLLocation alloc] initWithLatitude:randomPoint.latitude longitude:randomPoint.longitude];
            
            if ([randomPointLocation distanceFromLocation:routePointLocation]
                / kMile < kDeviation) {
                offset = (i + 1);
                GMSMarker *marker = [[GMSMarker alloc] init];
                marker.position = CLLocationCoordinate2DMake(randomPoint.latitude, randomPoint.longitude);
                marker.icon = [UIImage imageNamed:@"blue_pin"];
                marker.groundAnchor = CGPointMake(0.5, 0.5);
                marker.map = _mapView;
            }
        }
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:_methodStart];
    NSLog(@"execution time = %f", executionTime);
}

- (void)determineIntersectionAndDisplayPoints2:(NSMutableArray *)array
{
    for (int i = 0; i < array.count; i++) {
        TSPoint *routPoint = array[i];
        CLLocation *routePointLocation = [[CLLocation alloc] initWithLatitude:routPoint.latitude longitude:routPoint.longitude];
        
        for (int j = 0; j < _randomPoints.count; j++) {
            TSPoint *randomPoint = _randomPoints[j];
            CLLocation *randomPointLocation = [[CLLocation alloc] initWithLatitude:randomPoint.latitude longitude:randomPoint.longitude];
            
            if ([randomPointLocation distanceFromLocation:routePointLocation]
                / kMile < kDeviation) {
                GMSMarker *marker = [[GMSMarker alloc] init];
                marker.position = CLLocationCoordinate2DMake(randomPoint.latitude, randomPoint.longitude);
                marker.icon = [UIImage imageNamed:@"blue_pin"];
                marker.groundAnchor = CGPointMake(0.5, 0.5);
                marker.map = _mapView;
            }
        }
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:_methodStart];
    NSLog(@"execution time = %f", executionTime);
}

@end

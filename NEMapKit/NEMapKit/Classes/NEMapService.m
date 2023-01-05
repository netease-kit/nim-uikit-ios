// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMapService.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <NEChatKit/NEChatKit-Swift.h>
#import <NECommonKit/NECommonKit-Swift.h>

@interface NEMapService () <NEChatMapProtocol, AMapLocationManagerDelegate>

@property(nonatomic, strong) MAMapView *mapView;

@property(nonatomic, strong) AMapLocationManager *locationManager;

@end

@implementation NEMapService
+ (instancetype)shared {
  static id instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[[self class] alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    //        [self configLocationManager];
  }
  return self;
}

- (void)setupMapClient {
  //    [[NEChatKitClient instance] addMapDelegate:self];
  //    [[NEChatKitClient instance] addMapServiceDelegate:self];
}

- (void)setupMapSdkConfig {
  // 初始化高德SDK
  [AMapServices sharedServices].enableHTTPS = YES;
}

- (void)setupMapControllerWithMapType:(NSInteger)mapType {
  // 隐藏指南针
  _mapView.showsCompass = NO;
  // 隐藏比例尺
  _mapView.showsScale = NO;
  _mapView.zoomLevel = 15;
  _mapView.showsUserLocation = YES;
  _mapView.userTrackingMode = MAUserTrackingModeFollow;

  if (mapType == NEMapTypeDetail) {
    MAUserLocationRepresentation *r = [[MAUserLocationRepresentation alloc] init];
    r.showsAccuracyRing = YES;
    [self.mapView updateUserLocationRepresentation:r];

  } else {
  }

  // 设置大头针
  MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
  pointAnnotation.coordinate = _mapView.centerCoordinate;
  [_mapView addAnnotation:pointAnnotation];
}

- (id)getMapView {
  MAMapView *mapView = [[MAMapView alloc]
      initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight)];
  self.mapView = mapView;
  return mapView;
}

- (void)searchPositionWithKey:(NSString *)key
                   completion:(void (^)(NSArray<ChatLocaitonModel *> *_Nonnull,
                                        NSError *_Nullable))completion {
  NSLog(@"search key : %@", key);
}

- (void)dealloc {
  //    [[NEChatKitClient instance] removeMapServiceDelegate:self];
}

#pragma mark - location

//- (void)configLocationManager{
//    self.locationManager = [[AMapLocationManager alloc] init];
//    [self.locationManager setDelegate:self];
//    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
//    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
//}
//
//- (void)startUpdatingLocation{
//    [self.locationManager startUpdatingLocation];
//}
//
//- (void)stopSerialLocation{
//  //停止定位
//   [self.locationManager stopUpdatingLocation];
//}
//
//- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error{
//  //定位错误
//    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
//}
//
//- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation
//*)location{
//  //定位结果
//    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude,
//    location.coordinate.longitude, location.horizontalAccuracy);
//}

@end

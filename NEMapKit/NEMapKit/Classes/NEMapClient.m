// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMapClient.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <MAMapKit/MAMapKit.h>

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <NEChatKit/NEChatKit-Swift.h>
#import <NECommonKit/NECommonKit-Swift.h>

typedef void (^SearchCompletion)(NSArray<ChatLocaitonModel *> *, NSError *);

typedef void (^MapMoveCompletion)(void);

@interface NEMapClient () <NEChatMapProtocol,
                           AMapSearchDelegate,
                           NEMapServiceDelegate,
                           MAMapViewDelegate>

@property(nonatomic, strong) MAMapView *mapView;

@property(nonatomic, strong) AMapSearchAPI *search;

@property(nonatomic, strong) AMapLocationManager *locationManager;

@property(nonatomic, strong) SearchCompletion block;

@property(nonatomic, strong) SearchCompletion searchRoundBlock;

@property(nonatomic, strong) MapMoveCompletion mapMoveCompletion;

@property(nonatomic, strong) UIImage *annoationImage;

@property(nonatomic, strong) NSString *city;

@property(nonatomic, assign) BOOL needSearchRound;

@end

@implementation NEMapClient

- (instancetype)init {
  self = [super init];
  if (self) {
  }
  return self;
}

+ (instancetype)shared {
  static id instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[[self class] alloc] init];
  });
  return instance;
}

- (void)setupMapClientWithAppkey:(NSString *)appkey {
  [[NEChatKitClient instance] addMapDelegate:self];
  [self setupMapSdkConfigWithAppkey:appkey];
}

- (void)setupMapSdkConfigWithAppkey:(NSString *)appkey {
  // 初始化高德SDK
  [[AMapServices sharedServices] setApiKey:appkey];
  [AMapServices sharedServices].enableHTTPS = YES;
  [AMapSearchAPI updatePrivacyShow:AMapPrivacyShowStatusDidShow
                       privacyInfo:AMapPrivacyInfoStatusDidContain];
  [AMapSearchAPI updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
  self.search = [[AMapSearchAPI alloc] init];
  self.search.delegate = self;
}

- (void)setupMapControllerWithMapType:(NSInteger)mapType {
  // 隐藏指南针
  _mapView.showsCompass = NO;
  // 隐藏比例尺
  _mapView.showsScale = NO;
  _mapView.zoomLevel = 15;
  _mapView.showsUserLocation = YES;
  _mapView.userTrackingMode = MAUserTrackingModeFollow;
}

- (void)setCustomAnnotationWithImage:(UIImage *)image lat:(double)lat lng:(double)lng {
  self.annoationImage = image;
  if (image != nil) {
    MAUserLocationRepresentation *r = [[MAUserLocationRepresentation alloc] init];
    r.showsAccuracyRing = YES;
    [self.mapView updateUserLocationRepresentation:r];
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lng);
    [_mapView addAnnotation:pointAnnotation];
  }
}

- (void)searchPositionWithKey:(NSString *)key
                   completion:(void (^)(NSArray<ChatLocaitonModel *> *_Nonnull,
                                        NSError *_Nullable))completion {
  if (key.length <= 0) {
    return;
  }
  self.block = completion;

  [self.search cancelAllRequests];

  AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
  request.keywords = key;
  if (self.city.length > 0) {
    request.city = self.city;
  }

  [self.search AMapPOIKeywordsSearch:request];
}

- (void)didmoveMapWithCompletion:(void (^)(void))completion {
  self.mapMoveCompletion = completion;
}

- (id)getCurrentPositionWithMapview:(id)mapview {
  if ([mapview isKindOfClass:[MAMapView class]]) {
    MAMapView *map = (MAMapView *)mapview;
    return @{
      @"title" : map.userLocation.title ?: @"",
      @"subtitle" : map.userLocation.subtitle ?: @"",
      @"latitude" : [NSNumber numberWithDouble:map.userLocation.location.coordinate.latitude],
      @"longitude" : [NSNumber numberWithDouble:map.userLocation.location.coordinate.longitude]
    };
  }
  return nil;
}

- (id)getMapView {
  MAMapView *mapView = [[MAMapView alloc]
      initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight)];
  self.mapView = mapView;
  mapView.showsUserLocation = YES;
  // 隐藏指南针
  mapView.showsCompass = NO;
  // 隐藏比例尺
  mapView.showsScale = NO;
  mapView.maxZoomLevel = 19;
  mapView.userTrackingMode = MAUserTrackingModeNone;
  mapView.delegate = self;
  return mapView;
}

- (id)getCellMapView {
  MAMapView *mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, 242, 90)];
  // 隐藏指南针
  mapView.showsCompass = NO;
  // 隐藏比例尺
  mapView.showsScale = NO;
  //  mapView.maxZoomLevel = 5;
  //  mapView.showsUserLocation = YES;
  mapView.userTrackingMode = MAUserTrackingModeNone;
  mapView.zoomEnabled = NO;

  mapView.userInteractionEnabled = NO;
  return mapView;
}

- (void)setMapviewLocationWithLat:(double)lat lng:(double)lng mapview:(id)mapview {
  if ([mapview isKindOfClass:[MAMapView class]]) {
    MAMapView *map = (MAMapView *)mapview;
    [map setCenterCoordinate:CLLocationCoordinate2DMake(lat, lng)];
  }
}

- (void)setMapCenterWithMapview:(id)mapview {
  if ([mapview isKindOfClass:[MAMapView class]]) {
    MAMapView *map = (MAMapView *)mapview;
    [map setCenterCoordinate:map.userLocation.location.coordinate];
  }
}

- (void)searchRoundPositionWithCompletion:(void (^)(NSArray<ChatLocaitonModel *> *_Nonnull,
                                                    NSError *_Nullable))completion {
  self.searchRoundBlock = completion;
  self.needSearchRound = YES;
}

- (void)searchRoundPositionWithLat:(double)lat lng:(double)lng {
  [self.search cancelAllRequests];
  AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
  request.location = [[AMapGeoPoint alloc] init];
  request.location.latitude = lat;
  request.location.longitude = lng;
  [self.search AMapPOIAroundSearch:request];
}

- (void)searchMapCenterWithMapview:(id)mapview
                        completion:(void (^)(NSArray<ChatLocaitonModel *> *_Nonnull,
                                             NSError *_Nullable))completion {
  if ([mapview isKindOfClass:[MAMapView class]]) {
    self.searchRoundBlock = completion;
    MAMapView *map = (MAMapView *)mapview;
    [self searchRoundPositionWithLat:map.userLocation.location.coordinate.latitude
                                 lng:map.userLocation.location.coordinate.longitude];
  }
}

- (void)dealloc {
  [[NEChatKitClient instance] removeMapDelegate:self];
}

// MARK: AMapSearchDelegate

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request
               response:(AMapPOISearchResponse *)response {
  NSLog(@"onPOISearchDone count : %ld", (long)response.count);
  [self parseAndPassWithData:response.pois];
}

- (void)searchPositionResultWithResult:(NSArray<ChatLocaitonModel *> *)result {
  NSLog(@"searchPositionResultWithResult count : %lu", (unsigned long)result.count);
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
  NSLog(@"AMapSearchRequest error : %@", error);
}

- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request
                   response:(AMapGeocodeSearchResponse *)response {
}

- (void)parseAndPassWithData:(NSArray<AMapPOI *> *)datas {
  NSMutableArray<ChatLocaitonModel *> *mutaData = [[NSMutableArray alloc] init];
  for (AMapPOI *poi in datas) {
    ChatLocaitonModel *model = [[ChatLocaitonModel alloc] init];
    [mutaData addObject:model];
    model.title = poi.name;
    model.address = poi.address;
    model.city = poi.city;
    model.distance = poi.distance;
    model.lat = poi.location.latitude;
    model.lng = poi.location.longitude;
  }
  if (self.block != nil) {
    self.block(mutaData, nil);
  }
  if (self.searchRoundBlock != nil) {
    self.searchRoundBlock(mutaData, nil);
  }
}

#pragma mark - MAMapView Delegate

- (void)mapView:(MAMapView *)mapView
    didUpdateUserLocation:(MAUserLocation *)userLocation
         updatingLocation:(BOOL)updatingLocation {
  //  NSLog(@"didUpdateUserLocation : %d", updatingLocation);
  if (updatingLocation && self.needSearchRound) {
    AMapReGeocodeSearchRequest *regeoRequest = [[AMapReGeocodeSearchRequest alloc] init];
    regeoRequest.location = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude
                                                     longitude:userLocation.coordinate.longitude];
    // 发起逆地理编码
    [self.search AMapReGoecodeSearch:regeoRequest];
    [self searchRoundPositionWithLat:userLocation.location.coordinate.latitude
                                 lng:userLocation.location.coordinate.longitude];
    self.needSearchRound = NO;
  }
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request
                     response:(AMapReGeocodeSearchResponse *)response {
  if (response.regeocode != nil) {
    self.city = response.regeocode.addressComponent.city;
  }
}

- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction {
  if (wasUserAction == YES) {
    self.block = nil;
    [self searchRoundPositionWithLat:mapView.centerCoordinate.latitude
                                 lng:mapView.centerCoordinate.longitude];
  }
}

- (void)mapView:(MAMapView *)mapView mapWillMoveByUser:(BOOL)wasUserAction {
  if (wasUserAction == YES) {
    if (self.mapMoveCompletion != nil) {
      self.mapMoveCompletion();
    }
  }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
  if (nil != self.annoationImage) {
    MAAnnotationView *annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                                    reuseIdentifier:nil];
    annotationView.image = self.annoationImage;
    self.annoationImage = nil;
    return annotationView;
  }
  return nil;
}

@end

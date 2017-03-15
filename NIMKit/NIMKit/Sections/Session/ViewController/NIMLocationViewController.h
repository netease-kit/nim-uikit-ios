//
//  NTESLocationViewController.h
//  NIM
//
//  Created by chris on 15/2/28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class NIMKitLocationPoint;

@protocol NIMLocationViewControllerDelegate <NSObject>

- (void)onSendLocation:(NIMKitLocationPoint *)locationPoint;

@end

@interface NIMLocationViewController : UIViewController<MKMapViewDelegate>

@property(nonatomic,strong) MKMapView *mapView;

@property(nonatomic,weak)   id<NIMLocationViewControllerDelegate> delegate;

- (instancetype)initWithLocationPoint:(NIMKitLocationPoint *)locationPoint;

@end

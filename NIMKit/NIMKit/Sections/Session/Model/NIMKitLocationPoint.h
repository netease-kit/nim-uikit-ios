//
//  NIMKitLocationPoint.h
//  NIM
//
//  Created by chris on 15/2/28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@class NIMLocationObject;

@interface NIMKitLocationPoint : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly, copy)   NSString *title;

- (instancetype)initWithLocationObject:(NIMLocationObject *)locationObject;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate andTitle:(NSString*)title;

@end

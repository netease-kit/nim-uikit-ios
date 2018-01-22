//
//  NIMLocationPoint.m
//  NIM
//
//  Created by chris on 15/2/28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMKitLocationPoint.h"
#import <NIMSDK/NIMSDK.h>

@implementation NIMKitLocationPoint

- (instancetype)initWithLocationObject:(NIMLocationObject *)locationObject{
    self = [super init];
    if (self) {
        CLLocationCoordinate2D coordinate;
        coordinate.longitude = locationObject.longitude;
        coordinate.latitude  = locationObject.latitude;
        _coordinate = coordinate;
        _title      = locationObject.title;
    }
    return self;
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate andTitle:(NSString *)title{
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _title      = title;
    }
    return self;
}




@end

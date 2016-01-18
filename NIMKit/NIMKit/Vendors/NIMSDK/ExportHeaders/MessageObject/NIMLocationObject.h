//
//  NIMLocationObject.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMMessageObjectProtocol.h"
/**
 *  位置实例对象
 */
@interface NIMLocationObject : NSObject<NIMMessageObject>

/**
 *  位置实例对象初始化方法
 *
 *  @param latitude  纬度
 *  @param longitude 经度
 *  @param title   地理位置描述
 *  @return 位置实例对象
 */
- (instancetype)initWithLatitude:(double)latitude
                       longitude:(double)longitude
                           title:(NSString *)title;

/**
 *  维度
 */
@property (nonatomic, assign, readonly) double latitude;

/**
 *  经度
 */
@property (nonatomic, assign, readonly) double longitude;

/**
 *  标题
 */
@property (nonatomic, copy, readonly) NSString *title;


@end

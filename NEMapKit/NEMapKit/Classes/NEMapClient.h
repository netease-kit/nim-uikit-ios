// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NELocaitonModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEMapClient : NSObject

+ (instancetype)shared;

/// 设置插件初始化
/// @param appkey appkey
- (void)setupMapClientWithAppkey:(NSString *)appkey
    __attribute__((deprecated("- (void)setupMapClientWithAppkey:(NSString *)appkey "
                              "withServerKey:(NSString *)serverKey instead")));

/// 设置插件初始化
/// @param appkey appkey
/// @param serverKey serverKey
- (void)setupMapClientWithAppkey:(NSString *)appkey withServerKey:(NSString *)serverKey;

/// 定位地理位置中心
/// @param mapview 高德地图View
- (void)setMapCenterWithMapview:(id)mapview;

/// 根据关键字搜索地理位置
/// @param key 地理位置关键字
/// @param completion 搜索结果回调
- (void)searchPositionWithKey:(NSString *)key
                   completion:(void (^)(NSArray<NELocaitonModel *> *_Nonnull,
                                        NSError *_Nullable))completion;

/// 搜索当前地图中心位置附近地理位置
/// @param mapview  地图 view
- (void)searchMapCenterWithMapview:(id)mapview
                        completion:(void (^)(NSArray<NELocaitonModel *> *_Nonnull,
                                             NSError *_Nullable))completion;

/// 设置搜索地图中心位置回调(当用户拖动地图时需要不断回调)
/// @param completion 回调
- (void)searchRoundPositionWithCompletion:(void (^)(NSArray<NELocaitonModel *> *_Nonnull,
                                                    NSError *_Nullable))completion;

/// 设置地图定位到某个为止
/// @param lat 维度
/// @param lng 精度
/// @param mapview 地图视图控件
- (void)setMapviewLocationWithLat:(double)lat lng:(double)lng mapview:(id)mapview;

/// 获取地图控件(缺省参数)
/// @return mapview 地图视图
- (id)getMapView;

/// 设置地图默认参数(地图缺省参数)
///  @param mapType 预留扩展，暂时无用
- (void)setupMapControllerWithMapType:(NSInteger)mapType;

/// 位置移动回调
/// @param completion 回到block
- (void)didmoveMapWithCompletion:(void (^)(void))completion;

/// 设置地图自定义定位图标
/// @param image 自定义图片
/// @param lat 纬度
/// @param lng 精度
- (void)setCustomAnnotationWithImage:(nullable UIImage *)image lat:(double)lat lng:(double)lng;

@end

NS_ASSUME_NONNULL_END

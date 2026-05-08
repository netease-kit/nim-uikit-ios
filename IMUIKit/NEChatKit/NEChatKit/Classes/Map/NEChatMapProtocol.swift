// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public enum NEMapType: Int {
  case detail = 0
  case search
}

@objc
public protocol NEChatMapProtocol: NSObjectProtocol {
//  @objc
//  weak var mapService: NEMapServiceDelegate? { get set }

  @objc
  optional func setupMapSdkConfig()

  /// 设置地图页面类型
  /// - Parameter mapType  地图页面类型，0 地图详情页，用于查看地址位置消息  1 搜索，用于发送地址位置消息搜索位置
  @objc
  optional func setupMapController(mapType: Int)

  /// 获取详情页地图View
  @objc
  optional func getMapView() -> AnyObject?

  /// 获取聊天页地理位置消息cell显示的地址位置视图
  @objc
  optional func getCellMapView() -> AnyObject?

  @objc
  optional func getCurrentPosition(mapview: AnyObject?) -> AnyObject?

  /// 搜索某个关键字的地理位置坐标信息
  /// - Parameter key  关键字
  /// - Parameter completion  搜索结果回调
  @objc
  optional func searchPosition(key: String, completion: NESearchPositionCompletion?)

  /// 设置搜索附近地理位置的回调
  /// - Parameter completion  搜索结果回调

  @objc
  optional func searchRoundPosition(completion: NESearchPositionCompletion?)

  /// 搜索用户当前位置周围的地理位置信息
  /// - Parameter mapview  地图view
  @objc
  optional func searchMapCenter(mapview: AnyObject, completion: NESearchPositionCompletion?)

  /// 用户是否滑动地图回调，组件内根据回调决定是否改编重新定位到当前按钮状态
  @objc
  optional func didmoveMap(completion: NEMapviewDidMoveCompletion?)

  /// 设置当前位置为地图中心
  /// - Parameter mapview  地图view
  @objc
  optional func setMapCenter(mapview: AnyObject?)

  @objc
  optional func releaseSource()

  @objc
  optional func startUpdatingLocation()

  @objc
  optional func stopSerialLocation()

  /// 地图详情页(查看地址位置消息类型)设置当前定位经纬度位置
  ///  - Parameter lat  纬度
  ///  - Parameter lng  经度
  ///  - Parameter mapview  地图view
  @objc
  optional func setMapviewLocation(lat: Double, lng: Double, mapview: AnyObject)

  /// 设置自定义地址大头钉标记
  /// - Parameter image  自定义图片
  /// - Parameter lat  纬度
  /// - Parameter lng  经度
  @objc
  optional func setCustomAnnotation(image: UIImage?, lat: Double, lng: Double)

  /// 获取生成地理位置的图片
  /// - Parameter lat  纬度
  /// - Parameter lng  经度
  /// - returns   地理位置图片url
  @objc
  optional func getMapImageUrl(lat: Double, lng: Double) -> String
}

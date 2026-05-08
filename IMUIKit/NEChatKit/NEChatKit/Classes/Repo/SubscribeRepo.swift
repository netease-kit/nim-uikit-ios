//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objc
public protocol NESubscribeListener: NSObjectProtocol {
  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  @objc optional func onUserStatusChanged(_ data: [V2NIMUserStatus])
}

@objcMembers
public class SubscribeRepo: NSObject, V2NIMSubscribeListener {
  private let eventMultiDelegate = MultiDelegate<NESubscribeListener>(strongReferences: false)

  public static let shared = SubscribeRepo()

  override private init() {
    super.init()
    SubscribeProvider.shared.addEventSubscribeListener(self)
  }

  /// 添加监听
  /// - Parameter listener: 监听实例
  open func addListener(_ listener: NESubscribeListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    eventMultiDelegate.addDelegate(listener)
  }

  /// 移除监听
  /// - Parameter listener: 监听实例
  open func removeListener(_ listener: NESubscribeListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    eventMultiDelegate.removeDelegate(listener)
  }

  /// 发布用户自定义状态，如果默认在线状态不满足业务需求，可以发布自定义用户状态
  /// - Parameter statusType: 自定义设置值： 10000以上，包括一万，一万以内为预定义值，小于1万，返回参数错误
  /// - Parameter duration: 状态的有效期，单位秒，范围为 60s 到 7days
  /// - Parameter multiSync: 用户发布状态时是否需要多端同步
  /// - Parameter onlineOnly: 用户发布状态时是否只广播给在线的订阅者
  /// - Parameter completion: 完成回调
  open func publishCustomUserStatus(_ statusType: Int32,
                                    _ duration: Int?,
                                    _ multiSync: Bool = true,
                                    _ onlineOnly: Bool = true,
                                    _ completion: @escaping (V2NIMCustomUserStatusPublishResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " statusType: \(statusType) duration: \(String(describing: duration)) multiSync: \(multiSync) onlineOnly: \(onlineOnly)")

    let params = V2NIMCustomUserStatusParams()
    params.statusType = statusType
    params.multiSync = multiSync
    params.onlineOnly = onlineOnly
    if let duration = duration {
      params.duration = duration
    }

    SubscribeProvider.shared.publishCustomUserStatus(params, completion)
  }

  /// 订阅用户状态，包括在线状态，或自定义状态
  /// 单次订阅人数最多100，如果有较多人数需要调用，需多次调用该接口
  /// 如果同一账号多端重复订阅， 订阅有效期会默认后一次覆盖前一次时长
  /// 总订阅人数最多3000， 被订阅人数3000，为了性能考虑
  /// 在线状态事件订阅是单向的，双方需要各自订阅
  /// 如果接口整体失败，则返回调用错误码
  /// 如果部分账号失败，则返回失败账号列表
  /// 订阅接口后，有成员在线状态变更会触发回调：onUserStatusChanged
  /// - Parameter accountIds: 订阅的成员列表， 为空返回参数错误，单次数量不超过100， 列表数量如果超限，默认截取前100个账号
  /// - Parameter duration: 订阅的有效期，时间范围为 60~2592000，单位：秒, 过期后需要重新订阅。如果未过期的情况下重复订阅，新设置的有效期会覆盖之前的有效期
  /// - Parameter immediateSync: 订阅后是否立即同步事件状态值， 默认为false，为true：表示立即同步当前状态值。但为了性能考虑， 30S内重复订阅，会忽略该参数
  /// - Parameter completion: 完成回调
  open func subscribeUserStatus(_ accountIds: [String],
                                _ duration: Int?,
                                _ immediateSync: Bool = false,
                                _ completion: @escaping ([String]?, NSError?) -> Void) {
    let option = V2NIMSubscribeUserStatusOption()
    option.accountIds = accountIds
    option.immediateSync = immediateSync
    if let duration = duration {
      option.duration = duration
    } else {
      option.duration = 30 * 24 * 60 * 60
    }

    SubscribeProvider.shared.subscribeUserStatus(option, completion)
  }

  /// 取消用户状态订阅请求
  /// - Parameter accountIds: 取消订阅的成员列表，为空，则表示取消所有订阅的成员， 否则取消指定的成员, 单次数量不超过100
  /// - Parameter completion: 完成回调
  open func unsubscribeUserStatus(_ accountIds: [String],
                                  _ completion: @escaping ([String]?, NSError?) -> Void) {
    let option = V2NIMUnsubscribeUserStatusOption()
    option.accountIds = accountIds
    SubscribeProvider.shared.unsubscribeUserStatus(option, completion)
  }

  /// 查询用户状态订阅关系
  /// 输入账号列表，查询自己订阅了哪些账号列表， 返回订阅账号列表
  /// - Parameter accountIds 需要查询的账号列表，查询自己是否订阅了对应账号
  /// - Parameter completion: 完成回调
  open func queryUserStatusSubscriptions(_ accountIds: [String],
                                         _ completion: @escaping ([V2NIMUserStatusSubscribeResult]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountIds count: \(accountIds.count), first: \(String(describing: accountIds.first))")

    SubscribeProvider.shared.queryUserStatusSubscriptions(accountIds, completion)
  }

  /// 其它用户状态变更，包括在线状态，和自定义状态
  /// 同账号发布时，指定了多端同步的状态
  /// 在线状态默认值为：
  /// 登录：1
  /// 登出：2
  /// 断开连接： 3
  /// 在线状态事件会受推送的影响：如果应用被清理，但厂商推送（APNS、小米、华为、OPPO、VIVO、魅族、FCM）可达，则默认不会触发该用户断开连接的事件		,若开发者需要该种情况下视为离线，请前往网易云信控制台>选择应用>IM 即时通讯>功能配置>全局功能>在线状态订阅
  /// - Parameter data: 用户状态列表
  public func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    eventMultiDelegate |> { delegate in
      delegate.onUserStatusChanged?(data)
    }
  }
}

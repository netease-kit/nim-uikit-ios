/// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objc
public protocol ChatServiceDelegate: NSObjectProtocol {
  /// 注册初始化协议
  /// - Parameter params: 初始化参数
  @objc optional func setupInit(_ params: [String: Any]?)
}

@objcMembers
public class ChatKitClient: NSObject {
  public static let shared = ChatKitClient()
  var initProvider: [ChatServiceDelegate] = []

  /// 消息列表发送消息前的回调
  /// 回调参数：消息参数（包含消息和发送参数）和消息列表的视图控制器
  /// 返回值/回调值：（修改后的）消息参数，若消息参数为 nil，则表示拦截该消息不发送
  /// beforeSend 与 beforeSendCompletion 只能二选一，同时设置时优先使用 beforeSend
  public var beforeSend: ((_ viewController: UIViewController, _ param: MessageSendParams) -> MessageSendParams?)?
  public var beforeSendCompletion: ((UIViewController, MessageSendParams, @escaping (MessageSendParams?) -> Void) -> Void)?

  /// 本端发送消息后的回调，为 sendMessage 接口callback，可在回调中获取消息反垃圾结果
  public var sendMessageCallback: ((_ viewController: UIViewController, _ result: V2NIMSendMessageResult?, _ error: V2NIMError?, _ progress: UInt) -> Void)?

  override private init() {
    super.init()
    buryDataPoints("ChatKit")
  }

  open func setupInit(isFun: Bool) {
    initServices(["isFun": isFun])
    _ = NEFriendUserCache.shared
  }

  /// 注册初始化协议
  /// - Parameter service: 实现协议的类
  open func registerInit(_ service: ChatServiceDelegate) {
    initProvider.append(service)
  }

  /// 获取初始化协议列表
  /// - Parameter params: 初始化参数
  func initServices(_ params: [String: Any]?) {
    for initFunc in initProvider {
      initFunc.setupInit?(params)
    }
  }

  /// 数据埋点
  public func buryDataPoints(_ component: String) {
    let reportData = BaseReportData()
    reportData.imVersion = IMKitClient.instance.sdkVersion()
    reportData.component = component
    reportData.reportType = "init"
    reportData.framework = "iOS"
    reportData.version = imkitVersion
    reportData.appKey = IMKitClient.instance.appKey()
    XKitReporter.shared().report(reportData)
  }
}

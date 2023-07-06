// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreKit

@objcMembers
public class SettingRepo: NSObject {
  public let settingProvider = SettingProvider.shared
  private let moduleName = "NECoreIMKit"
  private let className = "SettingRepo"

  // 获取听筒模式
  public func getHandsetMode() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getHandSetMode()
  }

  // 设置听筒模式
  public func setHandsetMode(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setHandSetMode(value)
  }

  // 获取 已读/未读开关状态
  public func getShowReadStatus() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getMessageRead()
  }

  // 设置 已读/未读开关状态
  public func setShowReadStatus(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setMessageRead(value)
  }

  // 通知栏展示推送详情
  public func getPushShowDetail() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getPushDetailEnable()
  }

  public func setPushShowDetail(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setPushDetailEnable(value)
  }

  // PC/web同步开关
  public func getMultiPortPushMode() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getPcWebPushEnable()
  }

  public func updateMultiPortPushMode(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.updatePcWebPushEnable(value)
  }

  // 消息提示音开关
  public func getRingMode() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getPushAudioEnable()
  }

  public func setRingMode(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setPushAudioEnable(value)
  }

  // 消息震动开关
  public func getVibrateMode() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getPushShakeEnable()
  }

  public func setVibrateMode(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setPushShakeEnable(value)
  }

  // 新消息通知
  public func getPushEnable() -> Bool {
//    NELog.infoLog(moduleName + " " + className, desc: #function)
    settingProvider.getPushEnable()
  }

  public func setPushEnable(_ value: Bool) {
//    NELog.infoLog(moduleName + " " + className, desc: #function + ", value:\(value)")
    settingProvider.setPushEnable(value)
  }

  // 节点配置
  public func getNodeValue() -> Bool {
//    NELog.infoLog(className, desc: #function)
    settingProvider.getNodeConfig()
  }

  public func setNodeValue(_ value: Bool) {
//    NELog.infoLog(className, desc: #function + ", value:\(value)")
    settingProvider.setNodeConfig(value)
  }
}

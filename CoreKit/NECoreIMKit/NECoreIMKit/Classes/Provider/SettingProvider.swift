
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class SettingProvider: NSObject {
  private let HandSetModeKey = "HandSetModeKey"
  private let DeleteFriendKey = "DeleteFriendKey"
  private let MessageHasRead = "MessageHasRead"
  private let PushEnable = "PushEnable"
  private let PushAudio = "PushAudio"
  private let PushShake = "PushShake"
  // 节点配置，默认国内true，海外为false
  private let NodeConfigKey = "NodeConfigKey"

  public static let shared = SettingProvider()

  private let userDefault = UserDefaults.standard

  public func getHandSetMode() -> Bool {
    if let handSet = userDefault.value(forKey: HandSetModeKey) as? Bool {
      return handSet
    }
    return false
  }

  public func setHandSetMode(_ value: Bool) {
    userDefault.setValue(value, forKey: HandSetModeKey)
    userDefault.synchronize()
  }

  public func getMessageRead() -> Bool {
    if let read = userDefault.value(forKey: MessageHasRead) as? Bool {
      return read
    }
    return false
  }

  public func setMessageRead(_ value: Bool) {
    userDefault.setValue(value, forKey: MessageHasRead)
    userDefault.synchronize()
    NotificationCenter.default.post(name: Notification.Name("ShowReadStateChange"), object: nil)
  }

  public func getPushEnable() -> Bool {
    if let setting = NIMSDK.shared().apnsManager.currentSetting() {
      return !setting.noDisturbing
    }
    return false
  }

  public func setPushEnable(_ value: Bool) {
    if let setting = NIMSDK.shared().apnsManager.currentSetting() {
      setting.noDisturbing = !value
      if setting.noDisturbing == true {
        setting.noDisturbingStartH = 0
        setting.noDisturbingStartM = 0
        setting.noDisturbingEndH = 23
        setting.noDisturbingEndM = 59
      }
      NIMSDK.shared().apnsManager.updateApnsSetting(setting) { error in
        print("update setting finish : ", error as Any)
      }
    }
  }

  public func getPushDetailEnable() -> Bool {
    if let setting = NIMSDK.shared().apnsManager.currentSetting() {
      if setting.type == .detail {
        return true
      }
    }
    return false
  }

  public func setPushDetailEnable(_ value: Bool) {
    if let setting = NIMSDK.shared().apnsManager.currentSetting() {
      if value == true {
        setting.type = .detail
      } else {
        setting.type = .noDetail
      }
      NIMSDK.shared().apnsManager.updateApnsSetting(setting) { error in
        print("update setting finish : ", error as Any)
      }
    }
  }

  public func getPcWebPushEnable() -> Bool {
    if let config = NIMSDK.shared().apnsManager.currentMultiportConfig() {
      return config.shouldPushNotificationWhenPCOnline
    }
    return true
  }

  public func updatePcWebPushEnable(_ value: Bool) {
    if let config = NIMSDK.shared().apnsManager.currentMultiportConfig() {
      config.shouldPushNotificationWhenPCOnline = value
      NIMSDK.shared().apnsManager.updateApnsMultiportConfig(config) { error in
        print("update config finish : ", error as Any)
      }
    }
  }

  public func getPushAudioEnable() -> Bool {
    if let audio = userDefault.value(forKey: PushAudio) as? Bool {
      return audio
    }
    return false
  }

  public func setPushAudioEnable(_ value: Bool) {
    userDefault.setValue(value, forKey: PushAudio)
    userDefault.synchronize()
  }

  public func getPushShakeEnable() -> Bool {
    if let shake = userDefault.value(forKey: PushShake) as? Bool {
      return shake
    }
    return false
  }

  public func setPushShakeEnable(_ value: Bool) {
    userDefault.setValue(value, forKey: PushShake)
    userDefault.synchronize()
  }

  /// 配置节点
  /// - Parameter value: value
  public func setNodeConfig(_ value: Bool) {
    userDefault.setValue(value, forKey: NodeConfigKey)
    userDefault.synchronize()
  }

  /// 获取节点配置
  /// - Returns: value
  public func getNodeConfig() -> Bool {
    if let shake = userDefault.value(forKey: NodeConfigKey) as? Bool {
      return shake
    }
    return true
  }
}

//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class IMPushConfigModel: NSObject {
  public var configMap = NSMutableDictionary()

  public var customJson: String?

  public var config = V2NIMMessagePushConfig()
}

class IMPushConfigManager: NSObject {
  static let instance = IMPushConfigManager()

  private let filename = "im_sdk_push_config"

  private var configModel: IMPushConfigModel?

  override private init() {
    super.init()
    configModel = loadObjectFromDisk(fileName: filename)
  }

  /// 保存推送配置
  open func saveConfig(model: IMPushConfigModel) {
    configModel = model
    saveObjectToDisk(model, fileName: filename)
    SettingRepo.shared.setMessagePushConfig(getPushConfig())
  }

  /// 获取推送配置
  open func getConfig() -> IMPushConfigModel {
    configModel ?? IMPushConfigModel()
  }

  /// 获取推送配置
  open func getPushConfig() -> V2NIMMessagePushConfig {
    var customMap: NSMutableDictionary? = configModel?.configMap
    if let customJson = configModel?.customJson, !customJson.isEmpty,
       let costommap = NECommonUtil.getDictionaryFromJSONString(customJson) as? NSMutableDictionary {
      customMap = costommap
    }

    let pushConfig = configModel?.config ?? V2NIMMessagePushConfig()

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.pushEnabled)] as? Bool {
      pushConfig.pushEnabled = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.pushNickEnabled)] as? Bool {
      pushConfig.pushNickEnabled = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.pushContent)] as? String {
      pushConfig.pushContent = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.pushPayload)] as? String {
      pushConfig.pushPayload = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.forcePush)] as? Bool {
      pushConfig.forcePush = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.forcePushContent)] as? String {
      pushConfig.forcePushContent = customValue
    }

    if let customValue = customMap?[#keyPath(V2NIMMessagePushConfig.forcePushAccountIds)] as? [String] {
      pushConfig.forcePushAccountIds = customValue
    }

    return pushConfig
  }

  func saveObjectToDisk(_ object: IMPushConfigModel, fileName: String) {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let archiveURL = documentsDirectory.appendingPathComponent(fileName)
      let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
      do {
        try data?.write(to: archiveURL)
      } catch {
        print("saveObjectToDisk error: \(error)")
      }
    }
  }

  func loadObjectFromDisk(fileName: String) -> IMPushConfigModel? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    let archiveURL = documentsDirectory.appendingPathComponent(fileName)
    if FileManager.default.fileExists(atPath: archiveURL.path) {
      do {
        let retrievedData = try Data(contentsOf: archiveURL)
        if let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(retrievedData) as? IMPushConfigModel {
          return object
        }
      } catch {
        print("loadObjectFromDisk error: \(error)")
      }
    }

    return nil
  }

  /// 删除配置
  func clearConfig() {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let deleteFileUrl = documentsDirectory.appendingPathComponent(filename)
      // 移除文件
      do {
        try FileManager.default.removeItem(at: deleteFileUrl)
      } catch {
        print("clear config error \(error.localizedDescription)")
      }
      configModel = nil
    }
  }
}

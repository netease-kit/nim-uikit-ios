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

  func dictionaryRepresentation() -> [String: Any] {
    var dictionary = [String: Any]()
    dictionary["configMap"] = configMap as? [String: Any] ?? [:]
    if let customJson {
      dictionary["customJson"] = customJson
    }

    var configDictionary = [String: Any]()
    configDictionary["pushEnabled"] = config.pushEnabled
    configDictionary["pushNickEnabled"] = config.pushNickEnabled
    if let pushContent = config.pushContent {
      configDictionary["pushContent"] = pushContent
    }
    if let pushPayload = config.pushPayload {
      configDictionary["pushPayload"] = pushPayload
    }
    configDictionary["forcePush"] = config.forcePush
    if let forcePushContent = config.forcePushContent {
      configDictionary["forcePushContent"] = forcePushContent
    }
    if let forcePushAccountIds = config.forcePushAccountIds, !forcePushAccountIds.isEmpty {
      configDictionary["forcePushAccountIds"] = forcePushAccountIds
    }
    dictionary["config"] = configDictionary
    return dictionary
  }

  static func model(from dictionary: [String: Any]) -> IMPushConfigModel {
    let model = IMPushConfigModel()
    if let configMap = dictionary["configMap"] as? [String: Any] {
      model.configMap = NSMutableDictionary(dictionary: configMap)
    }
    if let customJson = dictionary["customJson"] as? String {
      model.customJson = customJson
    }
    if let configDictionary = dictionary["config"] as? [String: Any] {
      let pushConfig = V2NIMMessagePushConfig()
      if let pushEnabled = configDictionary["pushEnabled"] as? Bool {
        pushConfig.pushEnabled = pushEnabled
      }
      if let pushNickEnabled = configDictionary["pushNickEnabled"] as? Bool {
        pushConfig.pushNickEnabled = pushNickEnabled
      }
      if let pushContent = configDictionary["pushContent"] as? String {
        pushConfig.pushContent = pushContent
      }
      if let pushPayload = configDictionary["pushPayload"] as? String {
        pushConfig.pushPayload = pushPayload
      }
      if let forcePush = configDictionary["forcePush"] as? Bool {
        pushConfig.forcePush = forcePush
      }
      if let forcePushContent = configDictionary["forcePushContent"] as? String {
        pushConfig.forcePushContent = forcePushContent
      }
      if let forcePushAccountIds = configDictionary["forcePushAccountIds"] as? [String] {
        pushConfig.forcePushAccountIds = forcePushAccountIds
      }
      model.config = pushConfig
    }
    return model
  }
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
      do {
        let data = try PropertyListSerialization.data(
          fromPropertyList: object.dictionaryRepresentation(),
          format: .binary,
          options: 0
        )
        try data.write(to: archiveURL, options: .atomic)
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
        let propertyList = try PropertyListSerialization.propertyList(from: retrievedData, options: [], format: nil)
        if let dictionary = propertyList as? [String: Any],
           dictionary["configMap"] != nil || dictionary["customJson"] != nil || dictionary["config"] != nil {
          return IMPushConfigModel.model(from: dictionary)
        }
      } catch {
        print("loadObjectFromDisk error: \(error)")
      }

      do {
        try FileManager.default.removeItem(at: archiveURL)
      } catch {
        print("remove invalid push config error: \(error)")
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

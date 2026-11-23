//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class IMPocConfigModel: NSObject {
  public var configMap = NSMutableDictionary()

  public var customJson: String?

  public var enableCustomConfig = NSNumber(booleanLiteral: false)

  public var accountId: String?

  public var accountIdToken: String?

  func dictionaryRepresentation() -> [String: Any] {
    var dictionary = [String: Any]()
    dictionary["configMap"] = configMap as? [String: Any] ?? [:]
    dictionary["enableCustomConfig"] = enableCustomConfig
    if let customJson {
      dictionary["customJson"] = customJson
    }
    if let accountId {
      dictionary["accountId"] = accountId
    }
    if let accountIdToken {
      dictionary["accountIdToken"] = accountIdToken
    }
    return dictionary
  }

  static func model(from dictionary: [String: Any]) -> IMPocConfigModel {
    let model = IMPocConfigModel()
    if let configMap = dictionary["configMap"] as? [String: Any] {
      model.configMap = NSMutableDictionary(dictionary: configMap)
    }
    if let customJson = dictionary["customJson"] as? String {
      model.customJson = customJson
    }
    if let enableCustomConfig = dictionary["enableCustomConfig"] as? NSNumber {
      model.enableCustomConfig = enableCustomConfig
    } else if let enableCustomConfig = dictionary["enableCustomConfig"] as? Bool {
      model.enableCustomConfig = NSNumber(booleanLiteral: enableCustomConfig)
    }
    model.accountId = dictionary["accountId"] as? String
    model.accountIdToken = dictionary["accountIdToken"] as? String
    return model
  }
}

class IMPocConfigManager: NSObject {
  static let instance = IMPocConfigManager()

  private let filename = "sdk_config"

  private var configModel: IMPocConfigModel?

  override private init() {
    super.init()
    configModel = loadObjectFromDisk(fileName: filename)
  }

  /// 保存私有化配置
  open func saveConfig(model: IMPocConfigModel) {
    configModel = model
    saveObjectToDisk(model, fileName: filename)
  }

  /// 获取私有化配置
  open func getConfig() -> IMPocConfigModel {
    configModel ?? IMPocConfigModel()
  }

  func saveObjectToDisk(_ object: IMPocConfigModel, fileName: String) {
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

  func loadObjectFromDisk(fileName: String) -> IMPocConfigModel? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    let archiveURL = documentsDirectory.appendingPathComponent(fileName)
    if FileManager.default.fileExists(atPath: archiveURL.path) {
      do {
        let retrievedData = try Data(contentsOf: archiveURL)
        let propertyList = try PropertyListSerialization.propertyList(from: retrievedData, options: [], format: nil)
        if let dictionary = propertyList as? [String: Any],
           dictionary["configMap"] != nil || dictionary["customJson"] != nil || dictionary["enableCustomConfig"] != nil ||
           dictionary["accountId"] != nil || dictionary["accountIdToken"] != nil {
          return IMPocConfigModel.model(from: dictionary)
        }
      } catch {
        print("loadObjectFromDisk error: \(error)")
      }

      do {
        try FileManager.default.removeItem(at: archiveURL)
      } catch {
        print("remove invalid config error: \(error)")
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

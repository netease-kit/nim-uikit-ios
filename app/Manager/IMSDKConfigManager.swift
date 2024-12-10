//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class IMSDKConfigModel: NSObject {
  public var configMap = NSMutableDictionary()

  public var customJson: String?

  public var enableCustomConfig = NSNumber(booleanLiteral: false)

  public var accountId: String?

  public var accountIdToken: String?
}

class IMSDKConfigManager: NSObject {
  public static let instance = IMSDKConfigManager()

  private let filename = "sdk_config"

  private var configModel: IMSDKConfigModel?

  override private init() {
    super.init()
    configModel = loadObjectFromDisk(fileName: filename)
  }

  /// 保存私有化配置
  public func saveConfig(model: IMSDKConfigModel) {
    configModel = model
    saveObjectToDisk(model, fileName: filename)
  }

  /// 获取私有化配置
  public func getConfig() -> IMSDKConfigModel {
    configModel ?? IMSDKConfigModel()
  }

  func saveObjectToDisk(_ object: IMSDKConfigModel, fileName: String) {
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

  func loadObjectFromDisk(fileName: String) -> IMSDKConfigModel? {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let archiveURL = documentsDirectory.appendingPathComponent(fileName)
      do {
        let retrievedData = try Data(contentsOf: archiveURL)
        if let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(retrievedData) as? IMSDKConfigModel {
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

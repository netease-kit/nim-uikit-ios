/// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK

@objc
public protocol IMKitPluginService: NSObjectProtocol {
  /// 注册插件模型
  /// - Parameter text: 文本内容
  /// - Returns: 插件模型
  @objc optional func registerPlugin(_ text: String) -> OperationItem?
}

/// 插件管理类
@objcMembers
public class IMKitPluginManager: NSObject {
  public static let shared = IMKitPluginManager()
  var pluginProvider: [String: IMKitPluginService] = [:]

  override private init() {
    super.init()
  }

  /// 注册插件
  /// - Parameter filter: 过滤器，根据消息类型（可选）返回插件
  open func registerPlugin(_ name: String, _ plugin: IMKitPluginService) {
    pluginProvider[name] = plugin
  }

  /// 获取插件
  /// - Parameter model: 消息模型
  /// - Returns: 消息对应的插件列表（按权重升序）
  open func getPlugins(_ findName: String, _ text: String) -> [OperationItem] {
    var plugins: [OperationItem] = []
    for (name, plugin) in pluginProvider {
      if name == findName, let item = plugin.registerPlugin?(text) {
        plugins.append(item)
      }
    }

    plugins.sort { item1, item2 in
      (item1.type?.rawValue ?? 0) < (item2.type?.rawValue ?? 0)
    }
    return plugins
  }
}

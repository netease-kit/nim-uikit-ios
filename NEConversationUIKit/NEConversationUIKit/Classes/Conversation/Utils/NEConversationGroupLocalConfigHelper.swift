// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

enum NEConversationGroupLocalConfigHelper {
  /// 本地分组配置变更通知：磁盘配置是分组顺序的唯一权威来源，
  /// 保存后通知所有内存副本同步，避免双栏同时可见时显示旧顺序。
  static let didChangeNotification = Notification.Name("NEConversationGroupLocalConfigDidChange")

  private static func key() -> String {
    let account = IMKitClient.instance.account()
    return "NEConversationGroupConfig_\(account)"
  }

  static func load() -> NEConversationGroupLocalConfig {
    guard let data = UserDefaults.standard.data(forKey: key()),
          let config = try? JSONDecoder().decode(NEConversationGroupLocalConfig.self, from: data) else {
      return NEConversationGroupLocalConfig(items: [])
    }
    return config
  }

  static func save(_ config: NEConversationGroupLocalConfig) {
    if let data = try? JSONEncoder().encode(config) {
      UserDefaults.standard.set(data, forKey: key())
    }
  }

  static func mergeAndSave(groups: [V2NIMConversationGroup]) -> NEConversationGroupLocalConfig {
    var config = load()
    var items = config.items
    var existingIds = Set(groups.compactMap(\.groupId))
    existingIds.insert(NEConversationGroupModel.atMeId)
    existingIds.insert(NEConversationGroupModel.unreadId)
    items.removeAll { !existingIds.contains($0.groupId) }

    var maxOrder = items.map(\.order).max() ?? -1
    for group in groups {
      guard let groupId = group.groupId else {
        continue
      }
      if !items.contains(where: { $0.groupId == groupId }) {
        maxOrder += 1
        items.append(NEConversationGroupLocalConfigItem(groupId: groupId, hidden: true, order: maxOrder))
      }
    }

    config.items = items
    save(config)
    return config
  }

  static func update(common: [NEConversationGroupModel], hidden: [NEConversationGroupModel]) {
    var items = [NEConversationGroupLocalConfigItem]()
    for (index, group) in common.enumerated() where group.type != .all {
      items.append(NEConversationGroupLocalConfigItem(groupId: group.groupId, hidden: false, order: index))
    }
    for (index, group) in hidden.enumerated() where group.type != .all {
      items.append(NEConversationGroupLocalConfigItem(groupId: group.groupId, hidden: true, order: common.count + index))
    }
    save(NEConversationGroupLocalConfig(items: items))
    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit

public extension OperationItem {
  /// 复制
  static func copyItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_copy")
    item.imageName = "op_copy"
    item.type = .copy
    return item
  }

  /// 回复
  static func replayItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_replay")
    item.imageName = "op_replay"
    item.type = .reply
    return item
  }

  /// 转发
  static func forwardItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_forward")
    item.imageName = "op_forward"
    item.type = .forward
    return item
  }

  /// 标记
  static func pinItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_pin")
    item.imageName = "op_pin"
    item.type = .pin
    return item
  }

  /// 取消标记
  static func removePinItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_cancel_pin")
    item.imageName = "op_pin"
    item.type = .removePin
    return item
  }

  /// 多选
  static func selectItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_select")
    item.imageName = "op_select"
    item.type = .multiSelect
    return item
  }

  /// 收藏
  static func collectionItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_collection")
    item.imageName = "op_collect"
    item.type = .collection
    return item
  }

  /// 置顶
  static func topItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_top")
    item.imageName = "op_top"
    item.type = .top
    return item
  }

  /// 移除置顶
  static func untopItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_untop")
    item.imageName = "op_untop"
    item.type = .untop
    return item
  }

  /// 删除
  static func deleteItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_delete")
    item.imageName = "op_delete"
    item.type = .delete
    return item
  }

  /// 撤回
  static func recallItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_recall")
    item.imageName = "op_recall"
    item.type = .recall
    return item
  }
}

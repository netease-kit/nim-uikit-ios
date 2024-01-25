
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public enum OperationType: Int {
  case copy = 1
  case reply
  case forward
  case pin
  case removePin
  case multiSelect
  case collection
  case delete
  case recall
}

@objcMembers
open class OperationItem: NSObject {
  public var text: String = ""
  public var imageName: String = ""
  public var type: OperationType?

  public static func copyItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_copy")
    item.imageName = "op_copy"
    item.type = .copy
    return item
  }

  public static func replayItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_replay")
    item.imageName = "op_replay"
    item.type = .reply
    return item
  }

  public static func forwardItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_forward")
    item.imageName = "op_forward"
    item.type = .forward
    return item
  }

  public static func pinItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_pin")
    item.imageName = "op_pin"
    item.type = .pin
    return item
  }

  public static func removePinItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_cancel_pin")
    item.imageName = "op_pin"
    item.type = .removePin
    return item
  }

  public static func selectItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_select")
    item.imageName = "op_select"
    item.type = .multiSelect
    return item
  }

//  static open func collectionItem() -> OperationItem {
//    OperationItem(
//      text: chatLocalizable("operation_collection"),
//      imageName: "op_collection",
//      type: .collection
//    )
//  }

  public static func deleteItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_delete")
    item.imageName = "op_delete"
    item.type = .delete
    return item
  }

  public static func recallItem() -> OperationItem {
    let item = OperationItem()
    item.text = chatLocalizable("operation_recall")
    item.imageName = "op_recall"
    item.type = .recall
    return item
  }
}

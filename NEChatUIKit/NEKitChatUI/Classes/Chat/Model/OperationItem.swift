
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public enum OperationType {
  case copy
  case reply
  case forward
  case pin
  case removePin
  case multiSelect
  case collection
  case delete
  case recall
}

public struct OperationItem {
  public var text: String
  public var imageName: String
  public var type: OperationType

  static func copyItem() -> OperationItem {
    OperationItem(text: localizable("operation_copy"), imageName: "op_copy", type: .copy)
  }

  static func replayItem() -> OperationItem {
    OperationItem(text: localizable("operation_replay"), imageName: "op_replay", type: .reply)
  }

  static func forwardItem() -> OperationItem {
    OperationItem(
      text: localizable("operation_forward"),
      imageName: "op_forward",
      type: .forward
    )
  }

  static func pinItem() -> OperationItem {
    OperationItem(text: localizable("operation_pin"), imageName: "op_pin", type: .pin)
  }

  static func removePinItem() -> OperationItem {
    OperationItem(
      text: localizable("operation_cancel_pin"),
      imageName: "op_pin",
      type: .removePin
    )
  }

//  static func selectItem() -> OperationItem {
//    OperationItem(
//      text: localizable("operation_select"),
//      imageName: "op_select",
//      type: .multiSelect
//    )
//  }

//  static func collectionItem() -> OperationItem {
//    OperationItem(
//      text: localizable("operation_collection"),
//      imageName: "op_collection",
//      type: .collection
//    )
//  }

  static func deleteItem() -> OperationItem {
    OperationItem(text: localizable("operation_delete"), imageName: "op_delete", type: .delete)
  }

  static func recallItem() -> OperationItem {
    OperationItem(text: localizable("operation_recall"), imageName: "op_recall", type: .recall)
  }
}

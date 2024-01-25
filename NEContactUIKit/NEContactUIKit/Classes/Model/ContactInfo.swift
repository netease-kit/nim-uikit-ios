
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NECoreKit
import UIKit

/*
 通讯录 cell 数据模型
 // contactCellType: 自定义 UI 类型，其在注册会话列表 cell 时作为 key 与自定义 cell 进行绑定
 // localExtension: 本地扩展字段，可根据业务需求添加数据，与 contactCellType 结合可实现多种自定义 cell 的展示
 */
@objcMembers
open class ContactInfo: NSObject {
  func getRowHeight() -> CGFloat? {
    nil
  }

  public var user: NEKitUser?
  public var contactCellType = ContactCellType.ContactPerson.rawValue
  public var router = ContactPersonRouter
  public var isSelected = false
  public var headerBackColor: UIColor?
  public var localExtension: [String: Any]?
}

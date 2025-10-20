
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit

/*
     通讯录 section 数据模型
     // initial: tableView 对应 section 的标题
     // contacts: tableView 对应 section 的数据
 */
@objcMembers
open class ContactSection: Comparable {
  public static func == (lhs: ContactSection, rhs: ContactSection) -> Bool {
    lhs.initial == rhs.initial
  }

  public static func < (lhs: ContactSection, rhs: ContactSection) -> Bool {
    lhs.initial < rhs.initial
  }

  public var initial: String
  public var contacts: Array = [ContactInfo]()
  public init(initial: String, contacts: [ContactInfo]) {
    self.initial = initial
    self.contacts = contacts
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit

@objcMembers
open class ContactSection {
  public var initial: String
  public var contacts: Array = [ContactInfo]()
  init(initial: String, contacts: [ContactInfo]) {
    self.initial = initial
    self.contacts = contacts
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class Contact {
  public var account: String?
  public var name: String?
  public var avatar: String?

  public init(account: String?) {
    self.account = account
  }
}

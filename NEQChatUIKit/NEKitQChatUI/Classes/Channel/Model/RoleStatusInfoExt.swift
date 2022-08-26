
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCoreIM

public struct RoleStatusInfoExt {
  public var status: RoleStatusInfo?
  public var title: String?

  public init(status: RoleStatusInfo?) {
    self.status = status
  }
}

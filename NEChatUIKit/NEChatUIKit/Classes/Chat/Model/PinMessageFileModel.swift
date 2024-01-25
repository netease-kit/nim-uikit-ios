//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class PinMessageFileModel: NSObject {
  public var progress: Float = 0
  public var size: Float = 0

  public var state = DownloadState.Success
  public weak var cell: NEBasePinMessageFileCell?
}

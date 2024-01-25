
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEEmotionAttachment: NSTextAttachment {
  private var _emotion: NIMInputEmoticon?

  public var emotion: NIMInputEmoticon? {
    set {
      _emotion = newValue
      image = UIImage.ne_bundleImage(name: emotion?.fileName ?? "")
    }
    get {
      _emotion
    }
  }
}

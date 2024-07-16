
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
open class NEAIWordSearchModel: NSObject {
  var content: NSAttributedString?
  var height: CGFloat = 0

  init(_ content: NSAttributedString?) {
    self.content = content
    let textSize = NSAttributedString.getRealSize(content, textFont, textMaxSize)
    height = ceil(textSize.height)
  }
}

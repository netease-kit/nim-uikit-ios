
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class NEChatUITool {
  // 计算富文本size
  class func getSizeWithAtt(att: NSAttributedString, font: UIFont, maxSize: CGSize) -> CGSize {
    if att.length == 0 {
      return CGSize.zero
    }
    var size = att.boundingRect(
      with: maxSize,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
    ).size

    if att.length > 0, size.width == 0, size.height == 0 {
      size = maxSize
    }
    return CGSize(width: ceil(size.width), height: ceil(size.height))
  }
}

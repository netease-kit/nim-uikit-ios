
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public extension Bundle {
  class func nim_defaultEmojiBundle() -> Bundle? {
    let bundle = Bundle(for: NIMInputEmoticonManager.self)
    let url = bundle.url(forResource: "NIMKitEmoticon", withExtension: "bundle")
    var emojiBundle: Bundle?
    if let url = url {
      emojiBundle = Bundle(url: url)
    }
    return emojiBundle
  }

  class func nim_EmojiPlistFile() -> String? {
    let bundle = Bundle.nim_defaultEmojiBundle()

    let resource = (CommonTool.getCurrentLanguage() == "cn") ?"emoji_ios_cn" : "emoji_ios_en"
    let filepath = bundle?.path(
      forResource: resource,
      ofType: "plist",
      inDirectory: NIMKit_EmojiPath
    )
    return filepath
  }

  class func nim_EmojiImage(imageName: String) -> String? {
    let bundle = Bundle.nim_defaultEmojiBundle()
    var ext = URL(fileURLWithPath: imageName).pathExtension
    if ext.count == 0 {
      ext = "png"
    }
    let name = URL(fileURLWithPath: imageName).deletingPathExtension().path
    let doubleImage = name + "@2x"
    let tribleImage = name + "@3x"
    var path: String?
    if UIScreen.main.scale == 3.0 {
      path = bundle?.path(
        forResource: tribleImage,
        ofType: ext,
        inDirectory: NIMKit_EmojiPath
      )
    }
    if let imagePath = path, imagePath.count > 0 {
    } else {
      path = bundle?.path(
        forResource: doubleImage,
        ofType: ext,
        inDirectory: NIMKit_EmojiPath
      )
    }
    return path
  }
}

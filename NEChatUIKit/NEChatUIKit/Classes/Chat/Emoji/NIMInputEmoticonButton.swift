
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit
public protocol NIMInputEmoticonButtonDelegate: NSObjectProtocol {
  func selectedEmoticon(emotion: NIMInputEmoticon, catalogID: String)
}

public class NIMInputEmoticonButton: UIButton {
  public var emotionData: NIMInputEmoticon?
  public var catalogID: String?
  public weak var delegate: NIMInputEmoticonButtonDelegate?
  private let classsTag = "NIMInputEmoticonButton"

  public class func iconButtonWithData(data: NIMInputEmoticon, catalogID: String,
                                       delegate: NIMInputEmoticonButtonDelegate)
    -> NIMInputEmoticonButton {
    let icon = NIMInputEmoticonButton()
    icon.addTarget(icon, action: #selector(onIconSelected), for: .touchUpInside)
    icon.emotionData = data
    icon.catalogID = catalogID
    icon.isUserInteractionEnabled = true
    icon.isExclusiveTouch = true
    icon.contentMode = .scaleToFill
    icon.delegate = delegate
    switch data.type {
    case .unicode:
      icon.setTitle(data.unicode, for: .normal)
      icon.setTitle(data.unicode, for: .highlighted)
      icon.titleLabel?.font = DefaultTextFont(32)
    default:
      let image = UIImage.ne_bundleImage(name: data.fileName ?? "")
      icon.setImage(image, for: .normal)
      icon.setImage(image, for: .highlighted)
    }
    return icon
  }

  @objc func onIconSelected(sender: NIMInputEmoticonButton) {
    guard let data = emotionData, let id = catalogID else {
      NELog.errorLog(classsTag, desc: "emotionData or catalogID maybe nil")
      return
    }
    delegate?.selectedEmoticon(emotion: data, catalogID: id)
  }
}

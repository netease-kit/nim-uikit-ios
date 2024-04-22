
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

public protocol NIMInputEmoticonButtonDelegate: NSObjectProtocol {
  func selectedEmoticon(emotion: NIMInputEmoticon, catalogID: String)
}

open class NIMInputEmoticonButton: UIButton {
  public var emotionData: NIMInputEmoticon?
  public var catalogID: String?
  public weak var delegate: NIMInputEmoticonButtonDelegate?
  private let classsTag = "NIMInputEmoticonButton"

  open class func iconButtonWithData(data: NIMInputEmoticon, catalogID: String,
                                     delegate: NIMInputEmoticonButtonDelegate)
    -> NIMInputEmoticonButton {
    let iconButton = NIMInputEmoticonButton()
    iconButton.addTarget(iconButton, action: #selector(onIconSelected), for: .touchUpInside)
    iconButton.emotionData = data
    iconButton.catalogID = catalogID
    iconButton.isUserInteractionEnabled = true
    iconButton.isExclusiveTouch = true
    iconButton.contentMode = .scaleToFill
    iconButton.delegate = delegate
    iconButton.accessibilityIdentifier = "id.emoji"
    iconButton.accessibilityValue = data.tag
    switch data.type {
    case .unicode:
      iconButton.setTitle(data.unicode, for: .normal)
      iconButton.setTitle(data.unicode, for: .highlighted)
      iconButton.titleLabel?.font = DefaultTextFont(32)
    default:
      let image = UIImage.ne_bundleImage(name: data.fileName ?? "")
      iconButton.setImage(image, for: .normal)
      iconButton.setImage(image, for: .highlighted)
    }
    return iconButton
  }

  @objc func onIconSelected(sender: NIMInputEmoticonButton) {
    guard let data = emotionData, let id = catalogID else {
      NEALog.errorLog(classsTag, desc: "emotionData or catalogID maybe nil")
      return
    }
    delegate?.selectedEmoticon(emotion: data, catalogID: id)
  }
}

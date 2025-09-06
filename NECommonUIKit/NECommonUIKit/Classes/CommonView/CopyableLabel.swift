
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MobileCoreServices
import UIKit

@objcMembers
open class CopyableLabel: NELinkableLabel {
  public var copyString: String?

  override public var canBecomeFirstResponder: Bool {
    true
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    sharedInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    sharedInit()
  }

  func sharedInit() {
    isUserInteractionEnabled = true
    addGestureRecognizer(UILongPressGestureRecognizer(
      target: self,
      action: #selector(showMenu(sender:))
    ))
  }

  func copyText(_ sender: Any?) {
    if let copy = copyString {
      UIPasteboard.general.string = copy
    } else {
      UIPasteboard.general.string = text
    }

    UIMenuController.shared.setMenuVisible(false, animated: true)
    UIApplication.shared.keyWindow?.makeToast(commonLocalizable("copy_success"), position: .center)
  }

  override open func copy(_ sender: Any?) {
    if let attribute = attributedText {
      if let data = try? attribute.data(from: NSMakeRange(0, attribute.length)) {
        UIPasteboard.general.setData(data, forPasteboardType: (kUTTypeRTF as NSString) as String)
      }
    }
    UIMenuController.shared.setMenuVisible(false, animated: true)
  }

  func showMenu(sender: Any?) {
    becomeFirstResponder()
    let menu = UIMenuController.shared
    if !menu.isMenuVisible {
      let copyMenu = UIMenuItem(title: commonLocalizable("copy"), action: #selector(copyText))
      menu.menuItems = [copyMenu]
      menu.setTargetRect(bounds, in: self)
      menu.setMenuVisible(true, animated: true)
    }
  }

  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(copyText) {
      return true
    }
    return false
  }
}

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

@objc
public protocol ChatInputViewDelegate: NSObjectProtocol {
  func sendText(text: String?, attribute: NSAttributedString?)
  @objc optional func didSelectSticker(_ sticker: NIMInputSticker)
  func willSelectItem(button: UIButton?, index: Int)
  func didSelectMoreCell(cell: NEInputMoreCell)

  @discardableResult
  func textChanged(text: String) -> Bool
  func textDelete(range: NSRange, text: String) -> Bool
  func startRecord()
  func moveOutView()
  func moveInView()
  func endRecord(insideView: Bool)
  func textFieldDidChange(_ text: String?)
  func textFieldDidEndEditing(_ text: String?)
  func textFieldDidBeginEditing(_ text: String?)
  func titleTextDidClearEmpty()
  func textViewDidChange()
}

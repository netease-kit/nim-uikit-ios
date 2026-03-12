// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
open class FunTextViewController: TextViewController {
  override public init(title: String?, body: NSAttributedString?) {
    super.init(title: title, body: body)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .funChatBackgroundColor
  }

  override open func didTapTel(_ url: URL) {
    showCustomBottomTelAction(url)
  }

  override open func didTapMailto(_ url: URL) {
    showCustomBottomMailAction(url)
  }
}

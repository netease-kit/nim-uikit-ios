//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

open class FunChatNewMessageView: NEBaseChatNewMessageView {
  override open func setupUI() {
    super.setupUI()
    jumpDownImageView.image = .ne_imageNamed(name: "fun_chat_jump_to_new")
    messageCountLabel.textColor = .ne_funTheme
  }
}

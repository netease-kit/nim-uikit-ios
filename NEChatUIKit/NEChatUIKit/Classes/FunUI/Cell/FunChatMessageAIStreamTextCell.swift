
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreKit
import UIKit

@objcMembers
open class FunChatMessageAIStreamTextCell: FunChatMessageTextCell {
  public lazy var loadingViewLeft: NELottieAnimationView = {
    let view = NELottieAnimationView(name: "ai_stream_loading_data", bundle: coreLoader.bundle)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.loopMode = .loop
    view.contentMode = .scaleAspectFill
    view.isHidden = true
    view.accessibilityIdentifier = "id.loadingView"
    return view
  }()

  public lazy var stopStreamButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "fun_ai_stream_stop"), for: .normal)
    button.isHidden = true
    button.addTarget(self, action: #selector(stopStreamButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.stopStreamButton"
    return button
  }()

  public lazy var regenStreamButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "fun_ai_stream_regen"), for: .normal)
    button.isHidden = true
    button.addTarget(self, action: #selector(regenStreamButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.regenStreamButton"
    return button
  }()

  override open func commonUILeft() {
    super.commonUILeft()
    contentLabelLeft.font = nil

    if IMKitConfigCenter.shared.enableAIStream {
      bubbleImageLeft.addSubview(loadingViewLeft)
      NSLayoutConstraint.activate([
        loadingViewLeft.leftAnchor.constraint(equalTo: contentLabelLeft.leftAnchor, constant: 4),
        loadingViewLeft.topAnchor.constraint(equalTo: contentLabelLeft.topAnchor),
        loadingViewLeft.widthAnchor.constraint(equalToConstant: 24),
        loadingViewLeft.heightAnchor.constraint(equalToConstant: 24),
      ])
    }

    contentView.addSubview(stopStreamButton)
    NSLayoutConstraint.activate([
      stopStreamButton.leftAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: 7),
      stopStreamButton.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      stopStreamButton.widthAnchor.constraint(equalToConstant: 24),
      stopStreamButton.heightAnchor.constraint(equalToConstant: 24),
    ])

    contentView.addSubview(regenStreamButton)
    NSLayoutConstraint.activate([
      regenStreamButton.leftAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: 7),
      regenStreamButton.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      regenStreamButton.widthAnchor.constraint(equalToConstant: 24),
      regenStreamButton.heightAnchor.constraint(equalToConstant: 24),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    contentLabelRight.font = nil
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    loadingViewLeft.isHidden = showRight
    stopStreamButton.isHidden = showRight
    regenStreamButton.isHidden = showRight
  }

  override open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    super.setSelect(model, enableSelect)
    if enableSelect {
      selectedButton.isHidden = (model.message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_PLACEHOLDER ||
        model.message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_STREAMING)
      stopStreamButton.isHidden = true
      regenStreamButton.isHidden = true
    }
  }

  override func getTextSize(_ attributedText: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributedText, messageTextFont, messageMaxSize)
  }

  func stopStreamButtonAction() {
    delegate?.stopAIStreamMessage?(self, contentModel)
  }

  func regenStreamButtonAction() {
    delegate?.regenAIStreamMessage?(self, contentModel)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentLabel = isSend ? contentLabelRight : contentLabelLeft

    if IMKitConfigCenter.shared.enableAIStream,
       model.message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_PLACEHOLDER {
      contentLabel.isHidden = true
      loadingViewLeft.isHidden = false
      loadingViewLeft.play()
      stopStreamButton.isHidden = model.message?.threadReply?.senderId != IMKitClient.instance.account()
      regenStreamButton.isHidden = true
    } else {
      contentLabel.isHidden = false
      loadingViewLeft.isHidden = true
      loadingViewLeft.stop()

      stopStreamButton.isHidden = model.message?.threadReply?.senderId != IMKitClient.instance.account() ||
        model.message?.aiConfig?.aiStreamStatus != .MESSAGE_AI_STREAM_STATUS_STREAMING
      regenStreamButton.isHidden = model.message?.threadReply?.senderId != IMKitClient.instance.account() ||
        model.message?.aiConfig?.aiStreamStatus == .MESSAGE_AI_STREAM_STATUS_STREAMING
    }
  }
}

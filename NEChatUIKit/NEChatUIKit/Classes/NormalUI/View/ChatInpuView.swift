// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
open class ChatInputView: NEBaseChatInputView {
  public var backViewHeightConstraint: NSLayoutConstraint?
  public var toolsBarTopMargin: NSLayoutConstraint?

  override open func commonUI() {
    super.commonUI()
    backgroundColor = UIColor.normalChatInputViewBg

    addSubview(textView)
    textView.delegate = self
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: getTextviewRightConstraint())
    NSLayoutConstraint.activate([
      textviewLeftConstraint!,
      textviewRightConstraint!,
      textView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      textView.heightAnchor.constraint(equalToConstant: 40),
    ])
    textInput = textView

    backViewHeightConstraint = backView.heightAnchor.constraint(equalToConstant: 40)
    insertSubview(backView, belowSubview: textView)
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
      backView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
      backView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      backViewHeightConstraint!,
    ])

    if let expandButton = expandButton {
      addSubview(expandButton)
      NSLayoutConstraint.activate([
        expandButton.topAnchor.constraint(equalTo: topAnchor, constant: 7),
        expandButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
        expandButton.heightAnchor.constraint(equalToConstant: 40),
        expandButton.widthAnchor.constraint(equalToConstant: 44.0),
      ])
      expandButton.setImage(.ne_imageNamed(name: "normal_input_unfold"), for: .normal)
      expandButton.addTarget(self, action: #selector(didClickExpandButton), for: .touchUpInside)
    }

    if let aiChatButton = aiChatButton,
       conversationType == .CONVERSATION_TYPE_P2P {
      addSubview(aiChatButton)
      NSLayoutConstraint.activate([
        aiChatButton.topAnchor.constraint(equalTo: topAnchor, constant: 7),
        aiChatButton.rightAnchor.constraint(equalTo: expandButton?.leftAnchor ?? rightAnchor, constant: expandButton != nil ? 8 : 0),
        aiChatButton.heightAnchor.constraint(equalToConstant: 40),
        aiChatButton.widthAnchor.constraint(equalToConstant: 44.0),
      ])
      aiChatButton.setImage(.ne_imageNamed(name: "ai_icon_default"), for: .normal)
      aiChatButton.setImage(.ne_imageNamed(name: "ai_icon_highlight"), for: .selected)
      aiChatButton.addTarget(self, action: #selector(didClickAIChatButton), for: .touchUpInside)
    } else {
      aiChatButton = nil
    }

    let imageNames = ["mic", "emoji", "photo", "add"]
    let imageNamesSelected = ["mic_selected", "emoji_selected", "photo", "add_selected"]

    var items = [UIButton]()
    for i in 0 ..< imageNames.count {
      let button = UIButton(type: .custom)
      button.setImage(UIImage.ne_imageNamed(name: imageNames[i]), for: .normal)
      button.setImage(UIImage.ne_imageNamed(name: imageNamesSelected[i]), for: .selected)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
      button.tag = i + 5
      button.accessibilityIdentifier = "id.chatMessageActionItemBtn"
      items.append(button)
    }

    if let chatInputBar = ChatUIConfig.shared.chatInputBar {
      chatInputBar(neParentContainerViewController() as? ChatViewController, &items)
    }

    stackView = UIStackView(arrangedSubviews: items)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.distribution = .fillEqually
    stackView.backgroundColor = .clear

    toolsBarTopMargin = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 46)
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor),
      stackView.rightAnchor.constraint(equalTo: rightAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 54),
      toolsBarTopMargin!,
    ])

    greyView.translatesAutoresizingMaskIntoConstraints = false
    greyView.backgroundColor = .clear
    greyView.isHidden = true
    addSubview(greyView)
    NSLayoutConstraint.activate([
      greyView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      greyView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      greyView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      greyView.heightAnchor.constraint(equalToConstant: 400),
    ])

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.rightAnchor.constraint(equalTo: rightAnchor),
      contentView.heightAnchor.constraint(equalToConstant: contentHeight),
      contentView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 0),
    ])

    recordView.isHidden = true
    recordView.translatesAutoresizingMaskIntoConstraints = false
    recordView.delegate = self
    recordView.backgroundColor = .normalChatRecordViewBg
    contentView.addSubview(recordView)
    NSLayoutConstraint.activate([
      recordView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      recordView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      recordView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      recordView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
    ])

    contentView.addSubview(emojiView)

    chatAddMoreView.backgroundColor = .normalChatAddMoreViewBg
    contentView.addSubview(chatAddMoreView)

    setupMultipleLineView()
    multipleLineExpandButton.setImage(chatCoreLoader.loadImage("normal_input_fold"), for: .normal)
  }

  override open func setLayerContents(_ open: Bool) {
    super.setLayerContents(open)
    if open {
      if let cgImage = UIImage.ne_imageNamed(name: "ai_back")?.cgImage {
        layer.contents = cgImage
        layer.contentsGravity = .resizeAspectFill // 内容填充模式
        layer.contentsScale = UIScreen.main.scale // 适配 Retina 屏幕
      }
    } else {
      layer.contents = nil
    }
  }

  func getTextviewRightConstraint() -> CGFloat {
    let expandButtonWidth = IMKitConfigCenter.shared.enableRichTextMessage ? 40 : 0
    let aiChatButtonWidth = IMKitConfigCenter.shared.enableAIChatHelper ? 40 : 0
    let totalWidth = expandButtonWidth + aiChatButtonWidth

    if totalWidth > 0 {
      return -CGFloat(min(totalWidth, 70))
    } else {
      return -7
    }
  }

  override open func didClickAIChatButton() {
    let multiInputOffset: CGFloat = chatInpuMode == .normal ? 0 : 50
    aiChatViewControllerTopConstant = 54 + multiInputOffset
    super.didClickAIChatButton()
  }

  override open func restoreNormalInputStyle() {
    super.restoreNormalInputStyle()

    guard let expandButton = expandButton else {
      return
    }

    textView.returnKeyType = .send
    textView.removeAllAutoLayout()
    textView.removeConstraints(textView.constraints)
    insertSubview(textView, aboveSubview: backView)
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7)
    if chatInpuMode == .normal {
      titleField.isHidden = true
      textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: getTextviewRightConstraint())
      NSLayoutConstraint.activate([
        textviewLeftConstraint!,
        textviewRightConstraint!,
        textView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
        textView.heightAnchor.constraint(equalToConstant: 40),
      ])
      backViewHeightConstraint?.constant = 46
      toolsBarTopMargin?.constant = 46
    } else if chatInpuMode == .multipleSend {
      titleField.isHidden = false
      textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7)
      NSLayoutConstraint.activate([
        textviewLeftConstraint!,
        textviewRightConstraint!,
        textView.topAnchor.constraint(equalTo: topAnchor, constant: 45),
        textView.heightAnchor.constraint(equalToConstant: 45),
      ])

      titleField.removeAllAutoLayout()
      insertSubview(titleField, belowSubview: textView)
      NSLayoutConstraint.activate([
        titleField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 4),
        titleField.rightAnchor.constraint(equalTo: aiChatButton?.leftAnchor ?? expandButton.leftAnchor),
        titleField.topAnchor.constraint(equalTo: backView.topAnchor),
        titleField.heightAnchor.constraint(equalToConstant: 40),
      ])

      backViewHeightConstraint?.constant = 96
      toolsBarTopMargin?.constant = 96
    }
  }

  override open func changeToMultipleLineStyle() {
    super.changeToMultipleLineStyle()
    textView.removeAllAutoLayout()
    multipleLineView.addSubview(textView)
    textView.removeConstraints(textView.constraints)
    textView.returnKeyType = .default
    titleField.isHidden = false

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: multipleLineView.leftAnchor, constant: 13),
      textView.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor, constant: -16),
      textView.topAnchor.constraint(equalTo: multipleLineView.topAnchor, constant: 48),
      textView.heightAnchor.constraint(equalToConstant: 183),
    ])

    if titleField.superview == nil || titleField.superview != multipleLineView {
      titleField.removeAllAutoLayout()
      multipleLineView.addSubview(titleField)
      NSLayoutConstraint.activate([
        titleField.leftAnchor.constraint(equalTo: multipleLineView.leftAnchor, constant: 16),
        titleField.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor, constant: -56),
        titleField.topAnchor.constraint(equalTo: multipleLineView.topAnchor, constant: 5),
        titleField.heightAnchor.constraint(equalToConstant: 40),
      ])
    }
  }

  override open func setMuteInputStyle() {
    super.setMuteInputStyle()
    backView.backgroundColor = .normalChatInputMuteBg
  }

  override open func setUnMuteInputStyle() {
    super.setUnMuteInputStyle()
    backView.backgroundColor = .normalChatInputBg
  }
}

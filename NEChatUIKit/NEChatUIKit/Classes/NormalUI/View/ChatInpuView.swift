// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class ChatInputView: NEBaseChatInputView {
  public var backViewHeightConstraint: NSLayoutConstraint?
  public var toolsBarTopMargin: NSLayoutConstraint?

  override open func commonUI() {
    backgroundColor = UIColor.normalChatInputBg
    addSubview(textView)
    textView.delegate = self
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -44)
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

    addSubview(expandButton)
    NSLayoutConstraint.activate([
      expandButton.topAnchor.constraint(equalTo: topAnchor, constant: 7),
      expandButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      expandButton.heightAnchor.constraint(equalToConstant: 40),
      expandButton.widthAnchor.constraint(equalToConstant: 44.0),
    ])
    expandButton.setImage(coreLoader.loadImage("normal_input_unfold"), for: .normal)
    expandButton.addTarget(self, action: #selector(didClickExpandButton), for: .touchUpInside)

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

    if let chatInputBar = NEKitChatConfig.shared.ui.chatInputBar {
      chatInputBar(&items)
    }

    stackView = UIStackView(arrangedSubviews: items)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.distribution = .fillEqually

    toolsBarTopMargin = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 46)
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor),
      stackView.rightAnchor.constraint(equalTo: rightAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 54),
      toolsBarTopMargin!,
    ])

    greyView.translatesAutoresizingMaskIntoConstraints = false
    greyView.backgroundColor = .ne_backgroundColor
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
    recordView.backgroundColor = UIColor.ne_backgroundColor
    contentView.addSubview(recordView)
    NSLayoutConstraint.activate([
      recordView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      recordView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      recordView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      recordView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
    ])

    contentView.addSubview(emojiView)

    contentView.addSubview(chatAddMoreView)

    setupMultipleLineView()
    multipleLineExpandButton.setImage(coreLoader.loadImage("normal_input_fold"), for: .normal)
  }

  override open func restoreNormalInputStyle() {
    super.restoreNormalInputStyle()
    textView.returnKeyType = .send
    textView.removeAllAutoLayout()
    textView.removeConstraints(textView.constraints)
    insertSubview(textView, aboveSubview: backView)
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -44)
    if chatInpuMode == .normal {
      NSLayoutConstraint.activate([
        textviewLeftConstraint!,
        textviewRightConstraint!,
        textView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
        textView.heightAnchor.constraint(equalToConstant: 40),
      ])
      backViewHeightConstraint?.constant = 46
      toolsBarTopMargin?.constant = 46
      titleField.isHidden = true
    } else if chatInpuMode == .multipleSend {
      titleField.isHidden = false
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
        titleField.rightAnchor.constraint(equalTo: expandButton.leftAnchor),
        titleField.topAnchor.constraint(equalTo: backView.topAnchor),
        titleField.heightAnchor.constraint(equalToConstant: 40),
      ])

      backViewHeightConstraint?.constant = 100
      toolsBarTopMargin?.constant = 100
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
    backView.backgroundColor = UIColor(hexString: "#E3E4E4")
  }

  override open func setUnMuteInputStyle() {
    super.setUnMuteInputStyle()
    backView.backgroundColor = .white
  }
}

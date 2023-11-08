// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class ChatInputView: NEBaseChatInputView {
  override public func commonUI() {
    backgroundColor = UIColor.normalChatInputBg
    addSubview(textView)
    textView.delegate = self
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 7)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7)
    NSLayoutConstraint.activate([
      textviewLeftConstraint!,
      textviewRightConstraint!,
      textView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      textView.heightAnchor.constraint(equalToConstant: 40),
    ])
    textInput = textView

    let imageNames = ["mic", "emoji", "photo", "add"]
    let imageNamesSelected = ["mic_selected", "emoji_selected", "photo", "add_selected"]

    var items = [UIButton]()
    for i in 0 ... 3 {
      let button = UIButton(type: .custom)
      button.setImage(UIImage.ne_imageNamed(name: imageNames[i]), for: .normal)
      button.setImage(UIImage.ne_imageNamed(name: imageNamesSelected[i]), for: .selected)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
      button.tag = i + 5
      button.accessibilityIdentifier = "id.chatMessageActionItemBtn"
      items.append(button)
    }

    stackView = UIStackView(arrangedSubviews: items)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.distribution = .fillEqually
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor),
      stackView.rightAnchor.constraint(equalTo: rightAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 54),
      stackView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 0),
    ])

    greyView.translatesAutoresizingMaskIntoConstraints = false
    greyView.backgroundColor = UIColor(hexString: "#EFF1F3")
    greyView.isHidden = true
    addSubview(greyView)
    NSLayoutConstraint.activate([
      greyView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      greyView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      greyView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      greyView.heightAnchor.constraint(equalToConstant: 100),
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
  }
}

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

let addMoreBtnTag = 8
let addEmojBtnTag = 6
let showPhotoTag = 2

@objc
public protocol FunChatInputViewDelegate: NSObjectProtocol {
  func recordModeChangeDidClick()
  func didHideReplyMode()
  func didShowReplyMode() // 内部状态转换的回调，上次是回复UI样式，转转成录音模式后再转换回来，还要保持回复样式，此场景下对外回调
}

@objcMembers
open class FunChatInputView: NEBaseChatInputView {
  /*
   // Only override draw() if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   override func draw(_ rect: CGRect) {
       // Drawing code
   }
   */

  var replyViewTopConstraint: NSLayoutConstraint?

  weak var funDelegate: FunChatInputViewDelegate?

  var defaultReplyTopSpace: CGFloat = 8

  public var replyBackView: UIView = {
    let back = UIView()
    back.translatesAutoresizingMaskIntoConstraints = false
    back.layer.cornerRadius = 4.0
    back.clipsToBounds = true
    back.backgroundColor = UIColor.funChatInputReplyBg
    return back
  }()

  public lazy var replyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.backgroundColor = UIColor.clear
    label.numberOfLines = 2
    return label
  }()

  public var clearBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.setImage(coreLoader.loadImage("fun_chat_input_reply_clear"), for: .normal)
    return button
  }()

  public var changeRecordModeBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.setImage(coreLoader.loadImage("fun_chat_input_change_record"), for: .normal)
    button.setImage(coreLoader.loadImage("fun_chat_input_keyboard"), for: .selected)
    return button
  }()

  public var showMoreActionBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.tag = addMoreBtnTag
    button.setImage(coreLoader.loadImage("fun_chat_input_show_more"), for: .normal)
    return button
  }()

  public var showEmojBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.tag = addEmojBtnTag
    button.setImage(coreLoader.loadImage("fun_chat_input_show_emoj"), for: .normal)
    return button
  }()

  public var holdToSpeakView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.funChatInputHoldspeakBg
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 4.0

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.funChatInputHoldspeakTextColor
    label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])
    label.text = chatLocalizable("fun_hold_to_talk")

    return view
  }()

  override open func commonUI() {
    backgroundColor = UIColor.funChatInputBg

    addSubview(textView)
    textView.layer.cornerRadius = 4.0
    textView.delegate = self
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -88)

    NSLayoutConstraint.activate([
      textviewLeftConstraint!,
      textviewRightConstraint!,
      textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      textView.heightAnchor.constraint(equalToConstant: 40),
    ])
    textInput = textView

    insertSubview(replyBackView, belowSubview: textView)
    replyViewTopConstraint = replyBackView.topAnchor.constraint(equalTo: topAnchor, constant: defaultReplyTopSpace)
    NSLayoutConstraint.activate([
      replyViewTopConstraint!,
      replyBackView.heightAnchor.constraint(equalToConstant: 40),
      replyBackView.leftAnchor.constraint(equalTo: textView.leftAnchor),
      replyBackView.rightAnchor.constraint(equalTo: textView.rightAnchor),
    ])

    replyBackView.addSubview(replyLabel)
    NSLayoutConstraint.activate([
      replyLabel.leftAnchor.constraint(equalTo: replyBackView.leftAnchor, constant: 5),
      replyLabel.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      replyLabel.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      replyLabel.rightAnchor.constraint(equalTo: replyBackView.rightAnchor, constant: -42),
    ])

    replyBackView.addSubview(clearBtn)
    NSLayoutConstraint.activate([
      clearBtn.rightAnchor.constraint(equalTo: replyBackView.rightAnchor),
      clearBtn.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      clearBtn.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      clearBtn.leftAnchor.constraint(equalTo: replyLabel.rightAnchor),
    ])
    clearBtn.addTarget(self, action: #selector(clearReplyMode), for: .touchUpInside)

    addSubview(changeRecordModeBtn)
    NSLayoutConstraint.activate([
      changeRecordModeBtn.leftAnchor.constraint(equalTo: leftAnchor),
      changeRecordModeBtn.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      changeRecordModeBtn.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      changeRecordModeBtn.rightAnchor.constraint(equalTo: replyBackView.leftAnchor),
    ])
    changeRecordModeBtn.addTarget(self, action: #selector(changeToRecordMode), for: .touchUpInside)

    addSubview(showMoreActionBtn)
    NSLayoutConstraint.activate([
      showMoreActionBtn.rightAnchor.constraint(equalTo: rightAnchor),
      showMoreActionBtn.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      showMoreActionBtn.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      showMoreActionBtn.widthAnchor.constraint(equalToConstant: 44),
    ])

    showMoreActionBtn.addTarget(self, action: #selector(moreBtnClick), for: .touchUpInside)

    addSubview(showEmojBtn)
    NSLayoutConstraint.activate([
      showEmojBtn.rightAnchor.constraint(equalTo: showMoreActionBtn.leftAnchor),
      showEmojBtn.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      showEmojBtn.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      showEmojBtn.widthAnchor.constraint(equalToConstant: 44),
    ])
    showEmojBtn.addTarget(self, action: #selector(emojBtnClick), for: .touchUpInside)

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.rightAnchor.constraint(equalTo: rightAnchor),
      contentView.heightAnchor.constraint(equalToConstant: contentHeight),
      contentView.topAnchor.constraint(equalTo: replyBackView.bottomAnchor, constant: 15),
    ])

    contentView.addSubview(emojiView)

    chatAddMoreView.frame = CGRect(x: chatAddMoreView.frame.origin.x,
                                   y: chatAddMoreView.frame.origin.y + 10,
                                   width: chatAddMoreView.frame.size.width,
                                   height: chatAddMoreView.frame.size.height)
    contentView.addSubview(chatAddMoreView)

    let moreActionViewLine = UIView()
    moreActionViewLine.translatesAutoresizingMaskIntoConstraints = false
    chatAddMoreView.addSubview(moreActionViewLine)
    chatAddMoreView.clipsToBounds = false
    moreActionViewLine.frame = CGRect(x: 0, y: -10, width: chatAddMoreView.width, height: 1.0)
    moreActionViewLine.backgroundColor = UIColor.funChatInputMoreActionViewLineColor

    addSubview(holdToSpeakView)
    NSLayoutConstraint.activate([
      holdToSpeakView.leftAnchor.constraint(equalTo: textView.leftAnchor),
      holdToSpeakView.rightAnchor.constraint(equalTo: textView.rightAnchor),
      holdToSpeakView.topAnchor.constraint(equalTo: textView.topAnchor),
      holdToSpeakView.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
    ])
    holdToSpeakView.isHidden = true
  }

  open func changeToRecordMode(_ button: UIButton) {
    button.isSelected = !button.isSelected
    if button.isSelected == true {
      showRecordMode()
    } else {
      hideRecordMode()
    }
  }

  open func clearReplyMode() {
    replyLabel.attributedText = nil
    hideReplyMode()
  }

  open func showRecordMode() {
    currentType = .audio
    holdToSpeakView.isHidden = false
    hideReplyMode()
    funDelegate?.recordModeChangeDidClick()
  }

  open func hideRecordMode() {
    holdToSpeakView.isHidden = true
    changeRecordModeBtn.isSelected = false
    if let replyText = replyLabel.attributedText, replyText.length > 0 {
      showReplyMode()
      funDelegate?.didShowReplyMode()
    }
  }

  open func showReplyMode() {
    replyViewTopConstraint?.constant = 52
    if replyLabel.attributedText == nil {
      hideRecordMode()
    } else if let replyText = replyLabel.attributedText, replyText.length <= 0 {
      hideRecordMode()
    }
  }

  open func hideReplyMode() {
    if let topSpace = replyViewTopConstraint?.constant, topSpace == defaultReplyTopSpace {
      return
    }
    replyViewTopConstraint?.constant = 8
    funDelegate?.didHideReplyMode()
  }

  open func isRecordMode() -> Bool {
    changeRecordModeBtn.isSelected
  }

  @objc
  private func moreBtnClick() {
    hideRecordMode()
    changeRecordModeBtn.isSelected = false
    buttonEvent(button: showMoreActionBtn)
  }

  @objc
  private func emojBtnClick() {
    hideRecordMode()
    changeRecordModeBtn.isSelected = false
    buttonEvent(button: showEmojBtn)
  }
}

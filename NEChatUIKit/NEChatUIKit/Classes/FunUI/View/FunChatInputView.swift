// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

let addMoreBtnTag = 8
let addEmojBtnTag = 6
let showPhotoTag = 2

@objc
public protocol FunChatInputViewDelegate: NSObjectProtocol {
  func recordModeChangeDidClick()
  func didHideRecordMode()
  func didHideReplyMode()
  func didShowReplyMode() // 内部状态转换的回调，上次是回复UI样式，转转成录音模式后再转换回来，还要保持回复样式，此场景下对外回调
}

@objcMembers
open class FunChatInputView: NEBaseChatInputView {
  var replyViewTopConstraint: NSLayoutConstraint?

  weak var funDelegate: FunChatInputViewDelegate?

  var defaultReplyTopSpace: CGFloat = 8

  var multipleReplyTopSpace: CGFloat = 48

  public var backViewHeightConstaint: NSLayoutConstraint?

  public var textViewTop: NSLayoutConstraint?

//    public var textViewHeight: NSLayoutConstraint?

  public var replyBackView: UIView = {
    let backView = UIView()
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.layer.cornerRadius = 8.0
    backView.clipsToBounds = true
    backView.backgroundColor = UIColor.funChatReplyViewBg
    return backView
  }()

  public lazy var replyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.backgroundColor = UIColor.clear
    label.numberOfLines = 2
    label.accessibilityIdentifier = "id.replyContent"
    return label
  }()

  public var clearBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.setImage(chatCoreLoader.loadImage("fun_chat_input_reply_clear"), for: .normal)
    button.accessibilityIdentifier = "id.replyClose"
    return button
  }()

  public var changeRecordModeBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.setImage(chatCoreLoader.loadImage("fun_chat_input_change_record"), for: .normal)
    button.setImage(chatCoreLoader.loadImage("fun_chat_input_keyboard"), for: .selected)
    button.accessibilityIdentifier = "id.changeRecordMode"
    return button
  }()

  public var showMoreActionBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.tag = addMoreBtnTag
    button.setImage(chatCoreLoader.loadImage("fun_chat_input_show_more"), for: .normal)
    button.accessibilityIdentifier = "id.inputMore"
    return button
  }()

  public var showEmojBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor.clear
    button.tag = addEmojBtnTag
    button.setImage(chatCoreLoader.loadImage("fun_chat_input_show_emoj"), for: .normal)
    button.accessibilityIdentifier = "id.inputEmoji"
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
    super.commonUI()
    backgroundColor = UIColor.funChatInputViewBg

    addSubview(textView)
    textView.layer.cornerRadius = 4.0
    textView.delegate = self
    textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48)
    textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: getTextviewRightConstraint())
    textViewTop = textView.topAnchor.constraint(equalTo: topAnchor, constant: 8)

    NSLayoutConstraint.activate([
      textviewLeftConstraint!,
      textviewRightConstraint!,
      textViewTop!,
      textView.heightAnchor.constraint(equalToConstant: 40),
    ])
    textInput = textView

    backViewHeightConstaint = backView.heightAnchor.constraint(equalToConstant: 40)
    insertSubview(backView, belowSubview: textView)
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48),
      backView.rightAnchor.constraint(equalTo: rightAnchor, constant: -88),
      backView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      backViewHeightConstaint!,
    ])

    if let expandButton = expandButton {
      addSubview(expandButton)
      NSLayoutConstraint.activate([
        expandButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        expandButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: 7),
        expandButton.heightAnchor.constraint(equalToConstant: 40),
        expandButton.widthAnchor.constraint(equalToConstant: 44.0),
      ])
      expandButton.setImage(chatCoreLoader.loadImage("fun_input_unfold"), for: .normal)
      expandButton.addTarget(self, action: #selector(didClickExpandButton), for: .touchUpInside)
    }

    aiChatButton = nil

    insertSubview(replyBackView, belowSubview: backView)
    replyViewTopConstraint = replyBackView.topAnchor.constraint(equalTo: topAnchor, constant: defaultReplyTopSpace)
    NSLayoutConstraint.activate([
      replyViewTopConstraint!,
      replyBackView.heightAnchor.constraint(equalToConstant: 40),
      replyBackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48),
      replyBackView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: 0),
    ])

    replyBackView.addSubview(replyLabel)
    NSLayoutConstraint.activate([
      replyLabel.leftAnchor.constraint(equalTo: replyBackView.leftAnchor, constant: 5),
      replyLabel.topAnchor.constraint(equalTo: replyBackView.topAnchor),
      replyLabel.bottomAnchor.constraint(equalTo: replyBackView.bottomAnchor),
      replyLabel.rightAnchor.constraint(equalTo: replyBackView.rightAnchor, constant: -fun_chat_min_h),
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

    chatAddMoreView.backgroundColor = .funChatAddMoreViewBg
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
    moreActionViewLine.backgroundColor = UIColor.funChatAddMoreActionViewLineColor

    addSubview(holdToSpeakView)
    NSLayoutConstraint.activate([
      holdToSpeakView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48),
      holdToSpeakView.rightAnchor.constraint(equalTo: backView.rightAnchor),
      holdToSpeakView.topAnchor.constraint(equalTo: backView.topAnchor),
      holdToSpeakView.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])
    holdToSpeakView.isHidden = true

    setupMultipleLineView()
    multipleLineExpandButton.setImage(chatCoreLoader.loadImage("fun_input_fold"), for: .normal)
  }

  override open func setLayerContents(_ open: Bool) {
    super.setLayerContents(open)
    if open {
      if let cgImage = UIImage.ne_imageNamed(name: "fun_ai_back")?.cgImage {
        aiChatViewController.view.layer.contents = cgImage
        aiChatViewController.view.layer.contentsGravity = .resizeAspectFill // 内容填充模式
        aiChatViewController.view.layer.contentsScale = UIScreen.main.scale // 适配 Retina 屏幕
      }
    } else {
      aiChatViewController.view.layer.contents = nil
    }
  }

  open func getTextviewRightConstraint() -> CGFloat {
    let expandButtonWidth = IMKitConfigCenter.shared.enableRichTextMessage ? 32 : 0
    let totalWidth = expandButtonWidth + 88
    return -CGFloat(totalWidth)
  }

  override open func didClickAIChatButton() {
    let replyViewOffset: CGFloat = replyLabel.attributedText == nil ? 0 : 40
    let multiInputOffset: CGFloat = chatInpuMode == .normal ? 0 : 40
    aiChatViewControllerTopConstant = 54 + replyViewOffset + multiInputOffset
    super.didClickAIChatButton()
  }

  open func changeToRecordMode(_ button: UIButton) {
    button.isSelected = !button.isSelected
    if button.isSelected == true {
      showRecordMode()
    } else {
      funDelegate?.didHideRecordMode()
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
    hideAIChatView()
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
    if chatInpuMode == .normal {
      replyViewTopConstraint?.constant = 52
    } else {
      replyViewTopConstraint?.constant = 90
    }
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
    if chatInpuMode == .normal {
      replyViewTopConstraint?.constant = 8
    } else {
      replyViewTopConstraint?.constant = multipleReplyTopSpace
    }
    funDelegate?.didHideReplyMode()
  }

  open func isRecordMode() -> Bool {
    changeRecordModeBtn.isSelected
  }

  @objc
  private func moreBtnClick() {
    if changeRecordModeBtn.isSelected == true, chatInpuMode == .multipleSend {
      funDelegate?.didHideRecordMode()
    }
    hideRecordMode()
    hideAIChatView()
    changeRecordModeBtn.isSelected = false
    buttonEvent(button: showMoreActionBtn)
  }

  @objc
  private func emojBtnClick() {
    if changeRecordModeBtn.isSelected == true, chatInpuMode == .multipleSend {
      funDelegate?.didHideRecordMode()
    }
    hideRecordMode()
    hideAIChatView()
    changeRecordModeBtn.isSelected = false
    buttonEvent(button: showEmojBtn)
  }

  override open func restoreNormalInputStyle() {
    super.restoreNormalInputStyle()

    guard let expandButton = expandButton else {
      return
    }

    contentSubView?.isHidden = true
    textView.returnKeyType = .send
    textView.removeAllAutoLayout()
    insertSubview(textView, belowSubview: holdToSpeakView)
    textView.removeConstraints(textView.constraints)

    if chatInpuMode == .normal {
      titleField.isHidden = true
      textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48)
      textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: getTextviewRightConstraint())
      textViewTop = textView.topAnchor.constraint(equalTo: topAnchor, constant: 8)
      NSLayoutConstraint.activate([
        textviewLeftConstraint!,
        textviewRightConstraint!,
        textViewTop!,
        textView.heightAnchor.constraint(equalToConstant: 40),
      ])
      backViewHeightConstaint?.constant = 40
      if let replyText = replyLabel.attributedText, replyText.length > 0 {
        replyViewTopConstraint?.constant = 51
      } else {
        replyViewTopConstraint?.constant = defaultReplyTopSpace
      }
    } else if chatInpuMode == .multipleSend {
      titleField.isHidden = false
      titleField.removeAllAutoLayout()
      insertSubview(titleField, aboveSubview: backView)
      NSLayoutConstraint.activate([
        titleField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 4),
        titleField.rightAnchor.constraint(equalTo: aiChatButton?.leftAnchor ?? expandButton.leftAnchor, constant: 2),
        titleField.topAnchor.constraint(equalTo: backView.topAnchor),
        titleField.heightAnchor.constraint(equalToConstant: 40),
      ])

      textviewLeftConstraint = textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 48)
      textviewRightConstraint = textView.rightAnchor.constraint(equalTo: rightAnchor, constant: -88)
      textViewTop = textView.topAnchor.constraint(equalTo: topAnchor, constant: 40)

      NSLayoutConstraint.activate([
        textviewLeftConstraint!,
        textviewRightConstraint!,
        textViewTop!,
        textView.heightAnchor.constraint(equalToConstant: 40),
      ])
      backViewHeightConstaint?.constant = 80
      if let replyText = replyLabel.attributedText, replyText.length > 0 {
        replyViewTopConstraint?.constant = 90
      } else {
        replyViewTopConstraint?.constant = multipleReplyTopSpace
      }
    }
  }

  override open func changeToMultipleLineStyle() {
    super.changeToMultipleLineStyle()
    titleField.isHidden = false
    textView.removeAllAutoLayout()
    textView.returnKeyType = .default
    multipleLineView.addSubview(textView)
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
    backView.backgroundColor = .funChatInputMuteBg
  }

  override open func setUnMuteInputStyle() {
    super.setUnMuteInputStyle()
    backView.backgroundColor = .funChatInputBg
  }

  // 多行输入模式下进入录音模式，切换回单行样式
  open func setRecordNormalStyle() {
    backViewHeightConstaint?.constant = 40
    textViewTop?.constant = 8
    replyViewTopConstraint?.constant = defaultReplyTopSpace
  }

  // 从录音模式切换回多行模式
  open func resotreMutipleModeFromRecordMode() {
    backViewHeightConstaint?.constant = 80
    textViewTop?.constant = 40
    if let replyText = replyLabel.attributedText, replyText.length > 0 {
      replyViewTopConstraint?.constant = 90
    } else {
      replyViewTopConstraint?.constant = multipleReplyTopSpace
    }
  }
}

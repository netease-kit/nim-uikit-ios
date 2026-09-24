
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import UIKit
import NEBaseUIKit

public enum EditType: Int {
  case nickName = 0
  case cellphone
  case email
  case specialSign
}

class InputPersonInfoController: NEBaseViewController, UITextFieldDelegate, UITextViewDelegate {
  typealias ResultCallBack = (String) -> Void
  var contentText: String? {
    didSet {
      textField.text = contentText
      signatureTextView.text = contentText
    }
  }

  var callBack: ResultCallBack?
  private var limitNumberCount = 0
  private var editType = EditType.nickName

  lazy var textField: UITextField = {
    let text = NESingleLineTextField()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = UIColor(hexString: "0x333333")
    text.font = UIFont.systemFont(ofSize: 14)
    text.delegate = self
    text.clearButtonMode = .always
    text.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    if let clearButton = text.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    text.accessibilityIdentifier = "id.nickname"
    return text
  }()

  lazy var signatureTextView: UITextView = {
    let text = UITextView()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.font = UIFont.systemFont(ofSize: 14)
    text.textColor = textField.textColor
    text.backgroundColor = .clear
    text.textContainer.lineFragmentPadding = 0
    text.delegate = self
    text.accessibilityIdentifier = "id.signature"
    return text
  }()

  lazy var textfieldBgView: UIView = {
    let backView = UIView()
    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    backView.translatesAutoresizingMaskIntoConstraints = false
    return backView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      guard let self = self else { return }
      if self.editType == .specialSign {
        self.signatureTextView.becomeFirstResponder()
      } else {
        self.textField.becomeFirstResponder()
      }
    }))
  }

  /// 初始化UI(内容区域)
  func setupSubviews() {
    view.addSubview(textfieldBgView)
    let inputView: UIView = editType == .specialSign ? signatureTextView : textField
    textfieldBgView.addSubview(inputView)

    /// 文本框白色背景
    NSLayoutConstraint.activate([
      textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
      textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + topConstant),
      textfieldBgView.heightAnchor.constraint(equalToConstant: editType == .specialSign ? 120 : 50),
    ])

    /// 文本框
    NSLayoutConstraint.activate([
      inputView.leftAnchor.constraint(equalTo: textfieldBgView.leftAnchor, constant: 16),
      inputView.rightAnchor.constraint(equalTo: textfieldBgView.rightAnchor, constant: -12),
      inputView.centerYAnchor.constraint(equalTo: textfieldBgView.centerYAnchor),
    ])
    if editType == .specialSign {
      signatureTextView.heightAnchor.constraint(equalTo: textfieldBgView.heightAnchor, constant: -16).isActive = true
    }
  }

  /// 初始化UI(导航栏)
  func initialConfig() {
    addRightAction(commonLocalizable("complete"), #selector(saveName), self)

    view.backgroundColor = UIColor(hexString: "#EFF1F4")
    navigationView.setMoreButtonTitle(commonLocalizable("complete"))
    navigationView.setMoreButtonWidth(NEAppLanguageUtil.getCurrentLanguage() == .english ? 80 : 60)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    view.backgroundColor = .ne_backgroundColor
    navigationView.backgroundColor = .ne_backgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
    navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
  }

  /// 保存昵称
  @objc func saveName() {
    view.endEditing(true)
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if let block = callBack {
      block(editType == .specialSign ? signatureTextView.text : (textField.text ?? ""))
//      navigationController?.popViewController(animated: true)
    }
  }

  /// 配置标题类型
  /// - Parameter editType: 标题类型
  func configTitle(editType: EditType) {
    self.editType = editType
    switch editType {
    case .nickName:
      title = localizable("nickname")
      limitNumberCount = 15
    case .cellphone:
      title = localizable("phone")
      limitNumberCount = 11
      textField.keyboardType = .phonePad
    case .email:
      title = localizable("email")
      limitNumberCount = 30
      textField.keyboardType = .emailAddress
    case .specialSign:
      title = localizable("individuality_sign")
      limitNumberCount = 50
    }
  }

  @objc
  func textFieldChange() {
    guard let _ = textField.markedTextRange else {
      if let text = textField.text,
         text.utf16.count > limitNumberCount {
        textField.text = String(text.prefix(limitNumberCount))
        showToast(String(format: localizable("text_count_limit"), limitNumberCount))
      }
      return
    }
  }

  func textViewDidChange(_ textView: UITextView) {
    guard textView.markedTextRange == nil else { return }
    var text = textView.text ?? ""
    if text.utf16.count > limitNumberCount {
      while text.utf16.count > limitNumberCount { text.removeLast() }
      textView.text = text
      showToast(String(format: localizable("text_count_limit"), limitNumberCount))
    }
  }
}

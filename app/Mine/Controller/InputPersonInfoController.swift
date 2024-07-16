
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import UIKit

public enum EditType: Int {
  case nickName = 0
  case cellphone
  case email
  case specialSign
}

class InputPersonInfoController: NEBaseViewController, UITextFieldDelegate {
  typealias ResultCallBack = (String) -> Void
  public var contentText: String? {
    didSet {
      textField.text = contentText
    }
  }

  public var callBack: ResultCallBack?
  private var limitNumberCount = 0

  lazy var textField: UITextField = {
    let text = UITextField()
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
      self?.textField.becomeFirstResponder()
    }))
  }

  /// 初始化UI(内容区域)
  func setupSubviews() {
    view.addSubview(textfieldBgView)
    textfieldBgView.addSubview(textField)

    /// 文本框白色背景
    if NEStyleManager.instance.isNormalStyle() {
      NSLayoutConstraint.activate([
        textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
        textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + topConstant),
        textfieldBgView.heightAnchor.constraint(equalToConstant: 50),
      ])

    } else {
      NSLayoutConstraint.activate([
        textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
        textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + topConstant),
        textfieldBgView.heightAnchor.constraint(equalToConstant: 50),
      ])
      textfieldBgView.layer.cornerRadius = 0
    }

    /// 文本框
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: textfieldBgView.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: textfieldBgView.rightAnchor, constant: -12),
      textField.centerYAnchor.constraint(equalTo: textfieldBgView.centerYAnchor),
    ])
  }

  /// 初始化UI(导航栏)
  func initialConfig() {
    addRightAction(commonLocalizable("complete"), #selector(saveName), self)

    view.backgroundColor = NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#EFF1F4") : UIColor(hexString: "#EDEDED")
    navigationView.setMoreButtonTitle(commonLocalizable("complete"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
      navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
    } else {
      view.backgroundColor = .funChatBackgroundColor
      navigationView.moreButton.setTitleColor(.funChatThemeColor, for: .normal)
      navigationView.moreButton.titleLabel?.font = .systemFont(ofSize: 17)
    }
  }

  /// 保存昵称
  @objc func saveName() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if let block = callBack {
      block(textField.text ?? "")
//      navigationController?.popViewController(animated: true)
    }
  }

  /// 配置标题类型
  /// - Parameter editType: 标题类型
  func configTitle(editType: EditType) {
    switch editType {
    case .nickName:
      title = NSLocalizedString("nickname", comment: "")
      limitNumberCount = 15
    case .cellphone:
      title = NSLocalizedString("phone", comment: "")
      limitNumberCount = 11
      textField.keyboardType = .phonePad
    case .email:
      title = NSLocalizedString("email", comment: "")
      limitNumberCount = 30
      textField.keyboardType = .emailAddress
    case .specialSign:
      title = NSLocalizedString("individuality_sign", comment: "")
      limitNumberCount = 50
    }
  }

  @objc
  func textFieldChange() {
    guard let _ = textField.markedTextRange else {
      if let text = textField.text,
         text.utf16.count > limitNumberCount {
        textField.text = String(text.prefix(limitNumberCount))
        showToast(String(format: NSLocalizedString("text_count_limit", comment: ""), limitNumberCount))
      }
      return
    }
  }
}

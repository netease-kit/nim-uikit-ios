
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit
import NEChatUIKit

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
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.textField.becomeFirstResponder()
    }))
  }

  func setupSubviews() {
    view.addSubview(textfieldBgView)
    textfieldBgView.addSubview(textField)

    if NEStyleManager.instance.isNormalStyle() {
      NSLayoutConstraint.activate([
        textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
        textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + kNavigationHeight + KStatusBarHeight),
        textfieldBgView.heightAnchor.constraint(equalToConstant: 50),
      ])

    } else {
      NSLayoutConstraint.activate([
        textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
        textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + kNavigationHeight + KStatusBarHeight),
        textfieldBgView.heightAnchor.constraint(equalToConstant: 50),
      ])
      textfieldBgView.layer.cornerRadius = 0
    }
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: textfieldBgView.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: textfieldBgView.rightAnchor, constant: -12),
      textField.centerYAnchor.constraint(equalTo: textfieldBgView.centerYAnchor),
    ])
  }

  func initialConfig() {
    addRightAction(NSLocalizedString("save", comment: ""), #selector(saveName), self)

    view.backgroundColor = NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#EFF1F4") : UIColor(hexString: "#EDEDED")
    customNavigationView.setMoreButtonTitle(NSLocalizedString("save", comment: ""))
    customNavigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      customNavigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
      customNavigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
    } else {
      view.backgroundColor = .funChatBackgroundColor
      customNavigationView.moreButton.setTitleColor(.funChatThemeColor, for: .normal)
      customNavigationView.moreButton.titleLabel?.font = .systemFont(ofSize: 17)
    }
  }

  @objc func saveName() {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    if let block = callBack {
      block(textField.text ?? "")
//      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  func configTitle(editType: EditType) {
    switch editType {
    case .nickName:
      title = NSLocalizedString("nickname", comment: "")
      limitNumberCount = 15
    case .cellphone:
      title = NSLocalizedString("phone", comment: "")
      limitNumberCount = 11
      textField.keyboardType = .numberPad
    case .email:
      title = NSLocalizedString("email", comment: "")
      limitNumberCount = 30
    case .specialSign:
      title = NSLocalizedString("individuality_sign", comment: "")
      limitNumberCount = 50
    }
  }

  // MARK: lazy Method

  lazy var textField: UITextField = {
    let text = UITextField()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = UIColor(hexString: "0x333333")
    text.font = UIFont.systemFont(ofSize: 14)
    text.delegate = self
    text.clearButtonMode = .always
    text.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
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

  @objc
  func textFieldChange() {
    guard let _ = textField.markedTextRange else {
      if let text = textField.text,
         text.count > limitNumberCount {
        textField.text = String(text.prefix(limitNumberCount))
        showToast(String(format: NSLocalizedString("text_count_limit", comment: ""), limitNumberCount))
      }
      return
    }
  }
}

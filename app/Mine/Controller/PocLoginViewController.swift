// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
public class PocLoginViewController: NEBaseViewController {
  // 成功回调
  public var loginSuccess: (() -> Void)?

  let usernameTextField = UITextField()
  let passwordTextField = UITextField()

  // 登录状态记录
  var isLogining = false

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = navigationView.backgroundColor
    navigationView.moreButton.isHidden = true

    // 设置用户名输入框
    usernameTextField.placeholder = "用户名"
    usernameTextField.borderStyle = .roundedRect
    usernameTextField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(usernameTextField)

    // 设置密码输入框
    passwordTextField.placeholder = "密码"
    passwordTextField.isSecureTextEntry = true
    passwordTextField.borderStyle = .roundedRect
    passwordTextField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(passwordTextField)

    // 布局
    NSLayoutConstraint.activate([
      usernameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topConstant),
      usernameTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      usernameTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      usernameTextField.heightAnchor.constraint(equalToConstant: 40),

      passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
      passwordTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      passwordTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      passwordTextField.heightAnchor.constraint(equalToConstant: 40),
    ])

    // 登录按钮
    let loginButton = UIButton()
    loginButton.setTitle("登录", for: .normal)
    loginButton.setTitleColor(.blue, for: .normal)
    loginButton.translatesAutoresizingMaskIntoConstraints = false
    loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
    loginButton.setTitleColor(.white, for: .normal)

    view.addSubview(loginButton)

    NSLayoutConstraint.activate([
      loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
      loginButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      loginButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      loginButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    // 清除私有化配置按钮
    let clearConfigButton = UIButton()
    clearConfigButton.setTitle("清除私有化配置", for: .normal)
    clearConfigButton.setTitleColor(.blue, for: .normal)
    clearConfigButton.translatesAutoresizingMaskIntoConstraints = false
    clearConfigButton.addTarget(self, action: #selector(clearConfig), for: .touchUpInside)
    clearConfigButton.setTitleColor(.white, for: .normal)
    view.addSubview(clearConfigButton)

    NSLayoutConstraint.activate([
      clearConfigButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
      clearConfigButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      clearConfigButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      clearConfigButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    loginButton.backgroundColor = .ne_normalTheme
    clearConfigButton.backgroundColor = .ne_normalTheme
  }

  // 登录
  func login() {
    if isLogining {
      return
    }

    guard let username = usernameTextField.text, let password = passwordTextField.text else {
      // 输入为空提示
      view.endEditing(true)
      view.makeToast("请输入用户名和密码")
      return
    }

    isLogining = true

    // 登录
    let option = V2NIMLoginOption()
    option.syncLevel = .DATA_SYNC_TYPE_LEVEL_BASIC
    IMKitClient.instance.login(username, password, option) { [weak self] error in
      self?.isLogining = false
      if let error = error {
        // 收回键盘
        self?.view.endEditing(true)
        self?.view.makeToast("登录失败: \(error.localizedDescription)")
      } else {
        let config = IMPocConfigManager.instance.getConfig()
        config.accountId = username
        config.accountIdToken = password
        IMPocConfigManager.instance.saveConfig(model: config)
        print("登录成功")
        self?.loginSuccess?()
      }
    }
  }

  /// 清除私有化配置
  func clearConfig() {
    // 弹出确认框
    let alert = UIAlertController(title: "提示", message: "确定要清除私有化配置吗？", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: commonLocalizable("cancel"), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: commonLocalizable("sure"), style: .default, handler: { [weak self] _ in
      IMPocConfigManager.instance.clearConfig()
      self?.view.makeToast("清除成功，请重新启动应用")
      self?.view.endEditing(true)
    }))
    present(alert, animated: true, completion: nil)
  }
}

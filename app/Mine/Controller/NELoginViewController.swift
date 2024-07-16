
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonKit
import NECoreIM2Kit
import NIMSDK
import UIKit
import YXLogin

public class NELoginViewController: UIViewController {
  // 登录成功
  public typealias LoginBlock = () -> Void

  public var successLogin: LoginBlock?

  lazy var launchIconView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage(named: "launchIcon")
    return imageView
  }()

  lazy var launchIconLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = NSLocalizedString("appName", comment: "")
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.textColor = UIColor(hexString: "333333")
    label.accessibilityIdentifier = "id.appYunxin"
    return label
  }()

  lazy var loginButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.cornerRadius = 8
    button.backgroundColor = UIColor.ne_normalTheme
    button.setTitleColor(UIColor.white, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
    button.setTitle(NSLocalizedString("register_login", comment: ""), for: .normal)
    button.addTarget(self, action: #selector(loginBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.loginButton"
    return button
  }()

  lazy var emailLoginButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(NSLocalizedString("email_login", comment: ""), for: .normal)
    button.addTarget(self, action: #selector(emailLoginBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.emailLogin"
    return button
  }()

  lazy var dividerLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_lightText
    return view
  }()

  /// 节点按钮
  lazy var nodeButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(NSLocalizedString("node_select", comment: ""), for: .normal)
    button.addTarget(self, action: #selector(nodeBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.serverConfig"
    return button
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override public func viewWillAppear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = true
  }

  override public func viewWillDisappear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = false
  }

  func setupUI() {
    view.addSubview(launchIconView)
    view.addSubview(launchIconLabel)
    view.addSubview(loginButton)
    view.addSubview(emailLoginButton)
    view.addSubview(dividerLineView)
    view.addSubview(nodeButton)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        launchIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIconView.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 145.0
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        launchIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 145.0),
      ])
    }
    NSLayoutConstraint.activate([
      launchIconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconLabel.topAnchor.constraint(equalTo: launchIconView.bottomAnchor, constant: -12.0),
    ])

    NSLayoutConstraint.activate([
      loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loginButton.topAnchor.constraint(equalTo: launchIconLabel.bottomAnchor, constant: 20),
      loginButton.widthAnchor.constraint(equalToConstant: NEConstant.screenWidth - 80),
      loginButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    NSLayoutConstraint.activate([
      dividerLineView.bottomAnchor.constraint(
        equalTo: view.bottomAnchor,
        constant: -10 - NEConstant.statusBarHeight
      ),
      dividerLineView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      dividerLineView.widthAnchor.constraint(equalToConstant: 1),
      dividerLineView.heightAnchor.constraint(equalToConstant: 10),
    ])

    NSLayoutConstraint.activate([
      emailLoginButton.centerYAnchor.constraint(equalTo: dividerLineView.centerYAnchor),
      emailLoginButton.rightAnchor.constraint(equalTo: dividerLineView.leftAnchor, constant: -8),
    ])

    NSLayoutConstraint.activate([
      nodeButton.centerYAnchor.constraint(equalTo: dividerLineView.centerYAnchor),
      nodeButton.leftAnchor.constraint(equalTo: dividerLineView.rightAnchor, constant: 8),
    ])
  }

  @objc func loginBtnClick(sender: UIButton) {
    // login to business server
    let config = YXConfig()
    config.appKey = ServerAddresses.getAppkey()
    config.parentScope = NSNumber(integerLiteral: 2)
    config.scope = NSNumber(integerLiteral: 7)
    config.supportInternationalize = true
    config.type = .phone
    #if DEBUG
      config.isOnline = false
      print("debug")
    #else
      config.isOnline = true
      print("release")
    #endif
    AuthorManager.shareInstance()?.initAuthor(with: config)

    weak var weakSelf = self
    AuthorManager.shareInstance()?.startLogin(completion: { user, error in
      if let err = error {
        print("login error : ", err)
      } else {
        weakSelf?.setupSuccessLogic(user)
      }
    })
  }

  @objc func emailLoginBtnClick(sender: UIButton) {
    // login to business server
    let config = YXConfig()
    config.appKey = ServerAddresses.getAppkey()
    config.parentScope = NSNumber(integerLiteral: 2)
    config.scope = NSNumber(integerLiteral: 7)
    config.supportInternationalize = false
    config.type = .email
    #if DEBUG
      config.isOnline = false
      print("debug")
    #else
      config.isOnline = true
      print("release")
    #endif
    AuthorManager.shareInstance()?.initAuthor(with: config)

    weak var weakSelf = self
    AuthorManager.shareInstance()?.startLogin(completion: { user, error in
      if let err = error {
        print("login error : ", err)
      } else {
        weakSelf?.setupSuccessLogic(user)
      }
    })
  }

  @objc func nodeBtnClick(sender: UIButton) {
    let ctrl = NENodeViewController()
    navigationController?.pushViewController(ctrl, animated: true)
  }

  private func setupSuccessLogic(_ user: YXUserInfo?) {
    if let token = user?.imToken, let account = user?.imAccid {
      weak var weakSelf = self
      print("login accid : ", account)
      print("login token : ", token)

      let option = V2NIMLoginOption()
      IMKitClient.instance.login(account, token, option) { error in
        if let err = error {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: "login IM error : \(err.localizedDescription)")
          UIApplication.shared.keyWindow?.makeToast(err.localizedDescription)
        } else {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: "login IM Success")
          if let block = weakSelf?.successLogin {
            block()
          }
        }
      }
    }
  }
}

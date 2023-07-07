
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import YXLogin
import NECoreIMKit
import NEChatUIKit

public class NELoginViewController: UIViewController {
  // 登录成功
  public typealias LoginBlock = () -> Void

  public var successLogin: LoginBlock?

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
    view.addSubview(launchIcon)
    view.addSubview(launchIconLabel)
    view.addSubview(loginBtn)
    view.addSubview(emailLoginBtn)
    view.addSubview(divideView)
    view.addSubview(nodeBtn)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIcon.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 145.0
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 145.0),
      ])
    }
    NSLayoutConstraint.activate([
      launchIconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconLabel.topAnchor.constraint(equalTo: launchIcon.bottomAnchor, constant: -12.0),
    ])

    NSLayoutConstraint.activate([
      loginBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loginBtn.topAnchor.constraint(equalTo: launchIconLabel.bottomAnchor, constant: 20),
      loginBtn.widthAnchor.constraint(equalToConstant: NEConstant.screenWidth - 80),
      loginBtn.heightAnchor.constraint(equalToConstant: 44),
    ])

    NSLayoutConstraint.activate([
      divideView.bottomAnchor.constraint(
        equalTo: view.bottomAnchor,
        constant: -10 - NEConstant.statusBarHeight
      ),
      divideView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      divideView.widthAnchor.constraint(equalToConstant: 1),
      divideView.heightAnchor.constraint(equalToConstant: 10),
    ])

    NSLayoutConstraint.activate([
      emailLoginBtn.centerYAnchor.constraint(equalTo: divideView.centerYAnchor),
      emailLoginBtn.rightAnchor.constraint(equalTo: divideView.leftAnchor, constant: -8),
    ])

    NSLayoutConstraint.activate([
      nodeBtn.centerYAnchor.constraint(equalTo: divideView.centerYAnchor),
      nodeBtn.leftAnchor.constraint(equalTo: divideView.rightAnchor, constant: 8),
    ])
  }

  @objc func loginBtnClick(sender: UIButton) {
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
    config.appKey = AppKey.appKey
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
      IMKitClient.instance.loginIM(account, token) { error in
        if let err = error {
          print("loginIM error : ", err)
          UIApplication.shared.keyWindow?.makeToast(err.localizedDescription)
        } else {
          ChatRouter.setupInit()
          if let block = weakSelf?.successLogin {
            block()
          }
        }
      }
    }
  }

  // lazy method
  lazy var launchIcon: UIImageView = {
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
    return label
  }()

  lazy var loginBtn: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.layer.cornerRadius = 8
    btn.backgroundColor = UIColor.ne_blueText
    btn.setTitleColor(UIColor.white, for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
    btn.setTitle(NSLocalizedString("register_login", comment: ""), for: .normal)
    btn.addTarget(self, action: #selector(loginBtnClick), for: .touchUpInside)
    return btn
  }()

  lazy var emailLoginBtn: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitleColor(UIColor.ne_lightText, for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    btn.setTitle(NSLocalizedString("email_login", comment: ""), for: .normal)
    btn.addTarget(self, action: #selector(emailLoginBtnClick), for: .touchUpInside)

    return btn
  }()

  lazy var divideView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_lightText
    return view
  }()

  lazy var nodeBtn: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitleColor(UIColor.ne_lightText, for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    btn.setTitle(NSLocalizedString("node_select", comment: ""), for: .normal)
    btn.addTarget(self, action: #selector(nodeBtnClick), for: .touchUpInside)

    return btn
  }()
}

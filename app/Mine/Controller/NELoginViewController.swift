// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
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
    label.text = localizable("appName")
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
    button.setTitle(localizable("register_login"), for: .normal)
    button.addTarget(self, action: #selector(loginBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.loginButton"
    return button
  }()

  /// 配置信息按钮
  lazy var configInfoButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    button.setTitle("智能体配置", for: .normal)
    button.addTarget(self, action: #selector(configInfoBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.configInfo"
    return button
  }()

  lazy var emailLoginButton: UIButton = {
    let button = UIButton()
    button.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(localizable("email_login"), for: .normal)
    button.addTarget(self, action: #selector(emailLoginBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.emailLogin"
    return button
  }()

  /// 节点按钮
  lazy var nodeButton: UIButton = {
    let button = UIButton()
    button.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(localizable("node_select"), for: .normal)
    button.addTarget(self, action: #selector(nodeBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.serverConfig"
    return button
  }()

  /// poc 登录
  lazy var pocLoginButton: UIButton = {
    let button = UIButton()
    button.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(localizable("login_by_account"), for: .normal)
    button.addTarget(self, action: #selector(pocLoginBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.pocLogin"
    return button
  }()

  /// poc 配置
  lazy var pocSettingButton: UIButton = {
    let button = UIButton()
    button.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
    button.setTitleColor(UIColor.ne_lightText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    button.setTitle(localizable("privatized_configuration"), for: .normal)
    button.addTarget(self, action: #selector(pocSettingBtnClick), for: .touchUpInside)
    button.accessibilityIdentifier = "id.pocSetting"
    return button
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override open func viewWillAppear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = true
  }

  override open func viewWillDisappear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = false
  }

  func setupUI() {
    view.backgroundColor = .white
    view.addSubview(launchIconView)
    view.addSubview(launchIconLabel)
    view.addSubview(loginButton)
    view.addSubview(configInfoButton)

    NSLayoutConstraint.activate([
      launchIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconView.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 145.0
      ),
    ])

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
      configInfoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      configInfoButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
      configInfoButton.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  func loginBtnClick(sender: UIButton) {
    // 优先从本地存储读取 account 和 token
    let loginAccount = UserDefaults.standard.string(forKey: ConfigInfoKeys.account) ?? account
    let loginToken = UserDefaults.standard.string(forKey: ConfigInfoKeys.token) ?? token
    let openclawAccount = UserDefaults.standard.string(forKey: ConfigInfoKeys.openclawAccount) ?? ""

    weak var weakSelf = self
    print("login accid : ", loginAccount)
    print("login token : ", loginToken)
    
    let option = V2NIMLoginOption()
    option.syncLevel = .DATA_SYNC_TYPE_LEVEL_BASIC
    IMKitClient.instance.login(loginAccount, loginToken, option) { error in
        if let err = error {
            NEALog.infoLog(weakSelf?.className() ?? "", desc: "login IM error : \(err.localizedDescription)")
            UIApplication.shared.keyWindow?.makeToast(err.localizedDescription)
        } else {
            NEALog.infoLog(weakSelf?.className() ?? "", desc: "login IM Success")
          
          if let conversaionId = V2NIMConversationIdUtil.p2pConversationId(openclawAccount) {
            let message = MessageUtils.tipMessage(text: localizable("open_claw_hello"))
            if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
              LocalConversationRepo.shared.getConversation(conversaionId) { conversaion, error in
                if conversaion == nil {
                  LocalConversationRepo.shared.createConversation(conversaionId) { conversaion, error in
                    if let conversaionId = conversaion?.conversationId {
                      ChatRepo.shared.insertMessageToLocal(message: message, conversationId: conversaionId) { msg, error in
                        
                      }
                    }
                  }
                }
              }
            } else {
              ConversationRepo.shared.getConversation(conversaionId) { conversaion, error in
                if conversaion == nil {
                  ConversationRepo.shared.createConversation(conversaionId) { conversaion, error in
                    if let conversaionId = conversaion?.conversationId {
                      ChatRepo.shared.insertMessageToLocal(message: message, conversationId: conversaionId) { msg, error in
                        
                      }
                    }
                  }
                }
              }
            }
          }
          
            if let block = weakSelf?.successLogin {
                block()
            }
        }
    }
  }

  func configInfoBtnClick(sender: UIButton) {
    let ctrl = NEConfigInfoViewController()
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func emailLoginBtnClick(sender: UIButton) {
  }

  func nodeBtnClick(sender: UIButton) {
    let ctrl = NENodeViewController()
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func pocLoginBtnClick(sender: UIButton) {
    let ctrl = PocLoginViewController()
    ctrl.loginSuccess = { [weak self] in
      self?.successLogin?()
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func pocSettingBtnClick(sender: UIButton) {
    let pocConfigController = IMPocConfigViewController()
    navigationController?.pushViewController(pocConfigController, animated: true)
  }
}

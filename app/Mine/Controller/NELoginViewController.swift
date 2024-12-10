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
    
    lazy var dividerLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.ne_lightText
        return view
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
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.addArrangedSubview(emailLoginButton)
        stackView.addArrangedSubview(nodeButton)
        stackView.addArrangedSubview(pocSettingButton)
        stackView.addArrangedSubview(pocLoginButton)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    func loginBtnClick(sender: UIButton) {
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
    
    func emailLoginBtnClick(sender: UIButton) {
        
    }
    
    func nodeBtnClick(sender: UIButton) {
        let ctrl = NENodeViewController()
        navigationController?.pushViewController(ctrl, animated: true)
    }
    
    func pocLoginBtnClick(sender: UIButton) {
        let ctrl = PocLoginController()
        ctrl.loginSuccess = { [weak self] in
            self?.successLogin?()
        }
        navigationController?.pushViewController(ctrl, animated: true)
    }
    
    func pocSettingBtnClick(sender: UIButton) {
        let configeController = IMSDKConfigViewController()
        navigationController?.pushViewController(configeController, animated: true)
    }
}

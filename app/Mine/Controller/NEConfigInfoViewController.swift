// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

/// 配置信息本地存储 Keys
struct ConfigInfoKeys {
  static let appKey = "nim_config_appKey"
  static let account = "nim_config_account"
  static let token = "nim_config_token"
  static let openclawAccount = "nim_config_openclawAccount"
}

@objcMembers
public class NEConfigInfoViewController: NEBaseViewController {

  // MARK: - UI Elements

  /// 滚动容器
  lazy var scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.translatesAutoresizingMaskIntoConstraints = false
    sv.alwaysBounceVertical = true
    sv.keyboardDismissMode = .onDrag
    return sv
  }()

  lazy var contentView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  /// 提示信息卡片
  lazy var tipCardView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1.0)
    v.layer.cornerRadius = 8
    v.layer.borderWidth = 1
    v.layer.borderColor = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0).cgColor
    return v
  }()

  lazy var tipLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
    label.text = """
    如何获取云信凭证：
    1. 登录网易云信控制台（yunxin.163.com）
    2. 创建或选择应用，获取 App Key
    3.在"账号管理"中创建 IM 账号(accid)
    4.为该账号生成Token（建议长期有效）
    """
    return label
  }()

  // AppKey
  lazy var appKeyTitleLabel: UILabel = {
    createTitleLabel("AppKey")
  }()

  lazy var appKeyTextField: UITextField = {
    createTextField("请输入Appkey")
  }()

  lazy var appKeyHintLabel: UILabel = {
    createHintLabel("从云信控制台获取")
  }()

  // Account
  lazy var accountTitleLabel: UILabel = {
    createTitleLabel("Account")
  }()

  lazy var accountTextField: UITextField = {
    createTextField("请输入账号")
  }()

  lazy var accountHintLabel: UILabel = {
    createHintLabel("云信控制台\"账号数-子功能配置\"中生成")
  }()

  // Token（密码）
  lazy var tokenTitleLabel: UILabel = {
    createTitleLabel("Token（密码）")
  }()

  lazy var tokenTextField: UITextField = {
    createTextField("请输入账号对应的token")
  }()

  lazy var tokenHintLabel: UILabel = {
    createHintLabel("云信控制台\"账号数-子功能配置\"中生成")
  }()

  // Openclaw Account
  lazy var openclawTitleLabel: UILabel = {
    createTitleLabel("OpenClaw Account")
  }()

  lazy var openclawTextField: UITextField = {
    createTextField("请输入龙虾对应的账号")
  }()

  lazy var openclawHintLabel: UILabel = {
    createHintLabel("龙虾登录账号，云信控制台\"账号数-子功能配置\"中生成")
  }()

  /// 重置配置按钮
  lazy var resetButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle("重置配置", for: .normal)
    btn.setTitleColor(UIColor(hexString: "FF4D4F"), for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    btn.layer.borderWidth = 1
    btn.layer.borderColor = UIColor(hexString: "FF4D4F").cgColor
    btn.layer.cornerRadius = 8
    btn.addTarget(self, action: #selector(resetConfig), for: .touchUpInside)
    return btn
  }()

  // MARK: - Lifecycle

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = "配置信息"
    setupSaveButton()
    setupConfigUI()
    loadSavedConfig()
  }

  // MARK: - Setup

  func setupSaveButton() {
    navigationView.setMoreButtonTitle("保存")
    navigationView.moreButton.isHidden = false
  }

  override open func toSetting() {
    // 点击保存按钮
    saveConfig()
  }

  func setupConfigUI() {
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
      scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
      contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
    ])

    let margin: CGFloat = 20

    // 提示卡片
    contentView.addSubview(tipCardView)
    tipCardView.addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      tipCardView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      tipCardView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),

      tipLabel.topAnchor.constraint(equalTo: tipCardView.topAnchor, constant: 12),
      tipLabel.leftAnchor.constraint(equalTo: tipCardView.leftAnchor, constant: 12),
      tipLabel.rightAnchor.constraint(equalTo: tipCardView.rightAnchor, constant: -12),
      tipLabel.bottomAnchor.constraint(equalTo: tipCardView.bottomAnchor, constant: -12),
    ])

    // AppKey Section
    contentView.addSubview(appKeyTitleLabel)
    contentView.addSubview(appKeyTextField)
    contentView.addSubview(appKeyHintLabel)
    NSLayoutConstraint.activate([
      appKeyTitleLabel.topAnchor.constraint(equalTo: tipCardView.bottomAnchor, constant: 24),
      appKeyTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      appKeyTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),

      appKeyTextField.topAnchor.constraint(equalTo: appKeyTitleLabel.bottomAnchor, constant: 8),
      appKeyTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      appKeyTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
      appKeyTextField.heightAnchor.constraint(equalToConstant: 44),

      appKeyHintLabel.topAnchor.constraint(equalTo: appKeyTextField.bottomAnchor, constant: 6),
      appKeyHintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      appKeyHintLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
    ])

    // Account Section
    contentView.addSubview(accountTitleLabel)
    contentView.addSubview(accountTextField)
    contentView.addSubview(accountHintLabel)
    NSLayoutConstraint.activate([
      accountTitleLabel.topAnchor.constraint(equalTo: appKeyHintLabel.bottomAnchor, constant: 24),
      accountTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      accountTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),

      accountTextField.topAnchor.constraint(equalTo: accountTitleLabel.bottomAnchor, constant: 8),
      accountTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      accountTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
      accountTextField.heightAnchor.constraint(equalToConstant: 44),

      accountHintLabel.topAnchor.constraint(equalTo: accountTextField.bottomAnchor, constant: 6),
      accountHintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      accountHintLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
    ])

    // Token Section
    contentView.addSubview(tokenTitleLabel)
    contentView.addSubview(tokenTextField)
    contentView.addSubview(tokenHintLabel)
    NSLayoutConstraint.activate([
      tokenTitleLabel.topAnchor.constraint(equalTo: accountHintLabel.bottomAnchor, constant: 24),
      tokenTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      tokenTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),

      tokenTextField.topAnchor.constraint(equalTo: tokenTitleLabel.bottomAnchor, constant: 8),
      tokenTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      tokenTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
      tokenTextField.heightAnchor.constraint(equalToConstant: 44),

      tokenHintLabel.topAnchor.constraint(equalTo: tokenTextField.bottomAnchor, constant: 6),
      tokenHintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      tokenHintLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
    ])

    // Openclaw Account Section
    contentView.addSubview(openclawTitleLabel)
    contentView.addSubview(openclawTextField)
    contentView.addSubview(openclawHintLabel)
    NSLayoutConstraint.activate([
      openclawTitleLabel.topAnchor.constraint(equalTo: tokenHintLabel.bottomAnchor, constant: 24),
      openclawTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      openclawTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),

      openclawTextField.topAnchor.constraint(equalTo: openclawTitleLabel.bottomAnchor, constant: 8),
      openclawTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      openclawTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
      openclawTextField.heightAnchor.constraint(equalToConstant: 44),

      openclawHintLabel.topAnchor.constraint(equalTo: openclawTextField.bottomAnchor, constant: 6),
      openclawHintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      openclawHintLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
    ])

    // 重置配置按钮
    contentView.addSubview(resetButton)
    NSLayoutConstraint.activate([
      resetButton.topAnchor.constraint(equalTo: openclawHintLabel.bottomAnchor, constant: 40),
      resetButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
      resetButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
      resetButton.heightAnchor.constraint(equalToConstant: 44),
      resetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
    ])
  }

  // MARK: - Helper: create UI elements

  func createTitleLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = UIFont.boldSystemFont(ofSize: 16)
    label.textColor = UIColor(hexString: "333333")
    return label
  }

  func createTextField(_ placeholder: String) -> UITextField {
    let tf = UITextField()
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.placeholder = placeholder
    tf.borderStyle = .none
    tf.font = UIFont.systemFont(ofSize: 15)
    tf.layer.borderWidth = 1
    tf.layer.borderColor = UIColor(hexString: "DCDFE6").cgColor
    tf.layer.cornerRadius = 4
    tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
    tf.leftViewMode = .always
    tf.clearButtonMode = .whileEditing
    tf.autocorrectionType = .no
    tf.autocapitalizationType = .none
    return tf
  }

  func createHintLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = UIColor(hexString: "999999")
    label.numberOfLines = 0
    return label
  }

  // MARK: - Load / Save

  func loadSavedConfig() {
    let ud = UserDefaults.standard
    appKeyTextField.text = ud.string(forKey: ConfigInfoKeys.appKey)
    accountTextField.text = ud.string(forKey: ConfigInfoKeys.account)
    tokenTextField.text = ud.string(forKey: ConfigInfoKeys.token)
    openclawTextField.text = ud.string(forKey: ConfigInfoKeys.openclawAccount)
  }

  func saveConfig() {
    view.endEditing(true)

    // 检测所有输入框不为空
    let appKeyText = appKeyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let accountText = accountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let tokenText = tokenTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let openclawText = openclawTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if appKeyText.isEmpty || accountText.isEmpty || tokenText.isEmpty || openclawText.isEmpty {
      view.neMakeToast("需要所有输入框均不为空")
      return
    }

    let ud = UserDefaults.standard
    ud.set(appKeyText, forKey: ConfigInfoKeys.appKey)
    ud.set(accountText, forKey: ConfigInfoKeys.account)
    ud.set(tokenText, forKey: ConfigInfoKeys.token)
    ud.set(openclawText, forKey: ConfigInfoKeys.openclawAccount)
    ud.synchronize()

    // 保存成功后提示重启
    let alert = UIAlertController(title: "保存成功", message: "配置信息已保存，需要重新启动 App 以使配置生效。", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "立即重启", style: .default, handler: { _ in
      exit(0)
    }))
    present(alert, animated: true)
  }

  // MARK: - Reset

  @objc func resetConfig() {
    let alert = UIAlertController(title: "提示", message: "确定要重置所有配置信息吗？重置后需要重新填写。", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "确定重置", style: .destructive, handler: { [weak self] _ in
      // 清空 UserDefaults
      let ud = UserDefaults.standard
      ud.removeObject(forKey: ConfigInfoKeys.appKey)
      ud.removeObject(forKey: ConfigInfoKeys.account)
      ud.removeObject(forKey: ConfigInfoKeys.token)
      ud.removeObject(forKey: ConfigInfoKeys.openclawAccount)
      ud.synchronize()

      // 清空输入框
      self?.appKeyTextField.text = nil
      self?.accountTextField.text = nil
      self?.tokenTextField.text = nil
      self?.openclawTextField.text = nil

      self?.view.neMakeToast("配置已重置")
    }))
    present(alert, animated: true)
  }

  // MARK: - Back with prompt

  override open func backEvent() {
    view.endEditing(true)

    let appKeyText = appKeyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let accountText = accountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let tokenText = tokenTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let openclawText = openclawTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if appKeyText.isEmpty || accountText.isEmpty || tokenText.isEmpty || openclawText.isEmpty {
      let alert = UIAlertController(title: "提示", message: "输入框内容为空，需要填入相关信息", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "确定返回", style: .default, handler: { [weak self] _ in
        self?.navigationController?.popViewController(animated: true)
      }))
      present(alert, animated: true)
      return
    }

    // 检测是否有未保存的变更
    let ud = UserDefaults.standard
    let savedAppKey = ud.string(forKey: ConfigInfoKeys.appKey) ?? ""
    let savedAccount = ud.string(forKey: ConfigInfoKeys.account) ?? ""
    let savedToken = ud.string(forKey: ConfigInfoKeys.token) ?? ""
    let savedOpenclaw = ud.string(forKey: ConfigInfoKeys.openclawAccount) ?? ""

    let hasChanges = (appKeyText != savedAppKey) || (accountText != savedAccount) ||
      (tokenText != savedToken) || (openclawText != savedOpenclaw)

    if hasChanges {
      let alert = UIAlertController(title: "提示", message: "是否保存相关设置？", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "不保存", style: .cancel, handler: { [weak self] _ in
        self?.navigationController?.popViewController(animated: true)
      }))
      alert.addAction(UIAlertAction(title: "保存", style: .default, handler: { [weak self] _ in
        self?.saveConfig()
        self?.navigationController?.popViewController(animated: true)
      }))
      present(alert, animated: true)
    } else {
      navigationController?.popViewController(animated: true)
    }
  }
}

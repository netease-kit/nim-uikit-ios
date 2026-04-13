// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 机器人配置串查看页面（Base）
@objcMembers
open class NEBaseAIRobotConfigController: NEContactBaseViewController {
  // MARK: - 数据

  /// 当前机器人
  public var bot: V2NIMUserAIBot

  /// 完整配置串（appKey|accid|token），懒计算
  private var fullConfigString: String {
    let appKey = IMKitClient.instance.appKey()
    let accid = bot.accid
    let token = bot.token ?? ""
    return "\(appKey)|\(accid)|\(token)"
  }

  // MARK: - 子视图

  /// 卡片容器
  public lazy var cardView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  /// "配置串"标签
  public lazy var titleLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_config_title")
    l.font = .systemFont(ofSize: 16)
    l.textColor = .ne_darkText
    return l
  }()

  /// 分隔线（标题/配置串之间）
  public lazy var divider: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .funContactLineBorderColor
    return v
  }()

  /// 配置串展示（单行，超出尾部省略）
  public lazy var configLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = .systemFont(ofSize: 14)
    l.textColor = .ne_lightText
    l.numberOfLines = 1
    l.lineBreakMode = .byTruncatingTail
    return l
  }()

  /// 复制按钮
  public lazy var copyButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle(localizable("ai_robot_config_copy"), for: .normal)
    btn.setTitleColor(.white, for: .normal)
    btn.titleLabel?.font = .systemFont(ofSize: 16)
    btn.layer.cornerRadius = copyButtonCornerRadius()
    btn.clipsToBounds = true
    btn.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)
    return btn
  }()

  /// 安全提示
  public lazy var warningLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_config_warning")
    l.font = .systemFont(ofSize: 14)
    l.textColor = UIColor(hexString: "#FF9000") // 橙色警告色，无对应全局颜色变量
    l.textAlignment = .center
    l.numberOfLines = 1
    return l
  }()

  // MARK: - Init

  public init(bot: V2NIMUserAIBot) {
    self.bot = bot
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - 生命周期

  override open func viewDidLoad() {
    super.viewDidLoad()
    // 导航栏标题和卡片内 titleLabel 均显示"配置串"
    title = localizable("ai_robot_config_title")
    navigationView.moreButton.isHidden = true
    setupConfigUI()
    configLabel.text = fullConfigString
  }

  // MARK: - UI

  open func setupConfigUI() {
    view.backgroundColor = pageBackgroundColor()

    // 卡片
    view.addSubview(cardView)
    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + cardTopMargin()),
      cardView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      cardView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
    ])
    setupCardCornerRadius()

    // "配置串"标题行
    cardView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor),
      titleLabel.leftAnchor.constraint(equalTo: cardView.leftAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: cardView.rightAnchor, constant: -16),
      titleLabel.heightAnchor.constraint(equalToConstant: 52),
    ])

    // 配置串内容（无分割线，直接跟在标题下方）
    cardView.addSubview(configLabel)
    NSLayoutConstraint.activate([
      configLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      configLabel.leftAnchor.constraint(equalTo: cardView.leftAnchor, constant: 16),
      configLabel.rightAnchor.constraint(equalTo: cardView.rightAnchor, constant: -16),
      configLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
    ])

    // 复制按钮
    view.addSubview(copyButton)
    NSLayoutConstraint.activate([
      copyButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 24),
      copyButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: copyButtonHorizontalMargin()),
      copyButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -copyButtonHorizontalMargin()),
      copyButton.heightAnchor.constraint(equalToConstant: 50),
    ])
    copyButton.backgroundColor = copyButtonColor()

    // 安全提示
    view.addSubview(warningLabel)
    NSLayoutConstraint.activate([
      warningLabel.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 16),
      warningLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      warningLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
    ])
  }

  // MARK: - Customization（子类 override）

  /// 页面背景色
  open func pageBackgroundColor() -> UIColor { .funContactNavigationBackgroundColor }

  /// 卡片距导航栏间距
  open func cardTopMargin() -> CGFloat { 0 }

  /// 卡片水平边距
  open func cardHorizontalMargin() -> CGFloat { 0 }

  /// 复制按钮水平边距
  open func copyButtonHorizontalMargin() -> CGFloat { 20 }

  /// 复制按钮圆角
  open func copyButtonCornerRadius() -> CGFloat { 4 }

  /// 复制按钮背景色 — 子类 override（Normal: normalContactThemeColor，Fun: funContactThemeColor）
  open func copyButtonColor() -> UIColor { .normalContactThemeColor }

  /// 卡片圆角 — 子类 override
  open func setupCardCornerRadius() {
    cardView.layer.cornerRadius = 0
    cardView.clipsToBounds = true
  }

  // MARK: - Action

  open func didTapCopy() {
    UIPasteboard.general.string = fullConfigString
    showToast(localizable("ai_robot_config_copy_success"))
  }
}

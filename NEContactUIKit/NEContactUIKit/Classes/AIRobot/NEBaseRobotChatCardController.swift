// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

/// 从聊天页头像点击进入的机器人名片页
/// 只展示头像、名称和「去聊天」按钮
open class NEBaseRobotChatCardController: NEContactBaseViewController {
  public let bot: V2NIMUserAIBot

  // MARK: - Views

  public lazy var avatarView: NEUserHeaderView = {
    let v = NEUserHeaderView(frame: .zero)
    v.translatesAutoresizingMaskIntoConstraints = false
    v.layer.cornerRadius = avatarSize() / 2
    v.clipsToBounds = true
    v.titleLabel.font = .systemFont(ofSize: 20)
    v.titleLabel.textColor = .white
    return v
  }()

  public lazy var nameLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = .systemFont(ofSize: 16, weight: .medium)
    l.textColor = .ne_darkText
    l.textAlignment = .center
    return l
  }()

  public lazy var chatButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle(localizable("ai_robot_chat"), for: .normal)
    btn.setTitleColor(.white, for: .normal)
    btn.titleLabel?.font = .systemFont(ofSize: 16)
    btn.backgroundColor = chatButtonColor()
    btn.layer.cornerRadius = 8
    btn.clipsToBounds = true
    btn.addTarget(self, action: #selector(didTapChatButton), for: .touchUpInside)
    return btn
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
    title = localizable("ai_robot_detail_title")
    navigationView.moreButton.isHidden = true
    view.backgroundColor = cardPageBackgroundColor()
    setupCardUI()
    configCard()
  }

  // MARK: - UI

  open func setupCardUI() {
    // 白色卡片容器
    let card = UIView()
    card.translatesAutoresizingMaskIntoConstraints = false
    card.backgroundColor = .white
    card.layer.cornerRadius = 8
    card.clipsToBounds = true
    view.addSubview(card)
    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      card.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      card.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
    ])

    card.addSubview(avatarView)
    NSLayoutConstraint.activate([
      avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      avatarView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: avatarSize()),
      avatarView.heightAnchor.constraint(equalToConstant: avatarSize()),
    ])

    card.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
      nameLabel.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 16),
      nameLabel.rightAnchor.constraint(equalTo: card.rightAnchor, constant: -16),
      nameLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
    ])

    // 「去聊天」按钮（卡片下方间距 12）
    view.addSubview(chatButton)
    NSLayoutConstraint.activate([
      chatButton.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
      chatButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      chatButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
      chatButton.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  open func configCard() {
    let name = bot.name ?? bot.accid
    nameLabel.text = name
    let shortName = NEFriendUserCache.getShortName(name)
    avatarView.configHeadData(headUrl: bot.icon, name: shortName, uid: bot.accid)
  }

  // MARK: - Customization

  open func cardPageBackgroundColor() -> UIColor { .ne_lightBackgroundColor }
  open func cardHorizontalMargin() -> CGFloat { 20 }
  open func avatarSize() -> CGFloat { 60 }
  open func chatButtonColor() -> UIColor { .normalContactThemeColor }

  // MARK: - Actions

  @objc open func didTapChatButton() {
    guard let nav = navigationController else { return }
    guard let conversationId = V2NIMConversationIdUtil.p2pConversationId(bot.accid) else { return }
    // 先 pop 当前名片页，再 push 聊天页（复用已有 ChatVC）
    CATransaction.begin()
    CATransaction.setCompletionBlock {
      Router.shared.use(PushP2pChatVCRouter,
                        parameters: ["nav": nav,
                                     "conversationId": conversationId as Any,
                                     "animated": true],
                        closure: nil)
    }
    nav.popViewController(animated: true)
    CATransaction.commit()
  }
}

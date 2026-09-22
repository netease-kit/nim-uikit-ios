
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objc
public protocol ChatBaseCellDelegate: NSObjectProtocol {
  // 单击头像
  func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 长按头像
  func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击消息体
  func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: MessageModel?)

  // 长按消息体
  func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击重发按钮
  func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击重新编辑按钮
  func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击已读未读按钮
  func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击多选按钮
  func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 划词选中失去焦点
  @objc optional func didTextViewLoseFocus(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 消息即将展示
  @objc optional func messageWillShow(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 停止流式消息
  @objc optional func stopAIStreamMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 重新生成流式消息
  @objc optional func regenAIStreamMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 点击自动检测的链接（url、mobile、email）
  @objc optional func didTapDetectedLink(_ cell: UITableViewCell, _ model: MessageContentModel?, _ url: URL)

  // 长按译文区域（弹出「复制 / 转发 / 隐藏」菜单）
  @objc optional func didLongPressTranslationView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 点击翻译失败提示，重新发起翻译
  @objc optional func didTapTranslationRetryView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  /// 点击消息下方的 Reaction 胶囊或添加按钮。
  @objc optional func didTapReaction(_ cell: UITableViewCell, _ model: MessageContentModel?, _ index: Int)
}

@objc
public protocol ChatAudioCellProtocol: NSObjectProtocol {
  var isPlaying: Bool { get set }
  var messageId: String? { get set }
  func startAnimation(byRight: Bool)
  func stopAnimation(byRight: Bool)
}

@objcMembers
open class NEBaseChatMessageCell: NEChatBaseCell, NEMessageReactionViewDelegate {
  /// Text reactions start on the same content column as the message text.
  /// Full-bleed media keeps the compact 4pt inset required by its surface.
  public static let reactionHorizontalPadding: CGFloat = chat_content_margin
  /// Media content is full-bleed inside its message surface, while the
  /// Reaction row keeps the 4pt design inset so both edges remain inside the
  /// media/card surface.
  public static let reactionMediaHorizontalPadding: CGFloat = 4
  /// Fixed-format image/video/file bodies need a visible gap from the expanded
  /// Reaction bubble surface. Keep the body size unchanged and grow the
  /// surrounding surface instead.
  public static let reactionMediaBodyPadding: CGFloat = 4
  public static let reactionBottomPadding: CGFloat = 8
  /// Reaction capsules normally share the message long-press entry point.
  /// Audio cells override this so their visual reaction row never expands the
  /// audio bubble's interaction range.
  open var supportsReactionLongPress: Bool { true }
  /// Text cells place Reaction inside the message bubble, between the body and
  /// translation. Other cells render it as a sibling below the bubble.
  open var usesInlineReactionSurface: Bool { false }

  private let pinLabelMaxWidth: CGFloat = 280 // pin 文案最大宽度
  public weak var delegate: ChatBaseCellDelegate?
  public var contentModel: MessageContentModel? // 消息模型
  public var singleLeft: Bool = false // 消息是否全部左侧展示
  public let reactionViewLeft = NEMessageReactionView(frame: .zero)
  public let reactionViewRight = NEMessageReactionView(frame: .zero)
  public let reactionBackdropLeft = UIImageView()
  public let reactionBackdropRight = UIImageView()
  /// The default anchor places Reaction below the message bubble. Normal text
  /// cells replace it with an inline anchor between body text and translation.
  public var reactionTopAnchorLeft: NSLayoutConstraint?
  public var reactionTopAnchorRight: NSLayoutConstraint?
  private var reactionWidthLeft: NSLayoutConstraint?
  private var reactionHeightLeft: NSLayoutConstraint?
  private var reactionWidthRight: NSLayoutConstraint?
  private var reactionHeightRight: NSLayoutConstraint?
  private var reactionLeadingLeft: NSLayoutConstraint?
  private var reactionTrailingLeft: NSLayoutConstraint?
  private var reactionLeadingRight: NSLayoutConstraint?
  private var reactionTrailingRight: NSLayoutConstraint?
  private var reactionBackdropLeadingLeft: NSLayoutConstraint?
  private var reactionBackdropTrailingRight: NSLayoutConstraint?
  private var reactionBackdropTopAnchorLeft: NSLayoutConstraint?
  private var reactionBackdropTopAnchorRight: NSLayoutConstraint?
  private var reactionBackdropWidthLeft: NSLayoutConstraint?
  private var reactionBackdropHeightLeft: NSLayoutConstraint?
  private var reactionBackdropWidthRight: NSLayoutConstraint?
  private var reactionBackdropHeightRight: NSLayoutConstraint?
  private var readViewRightToBubbleAnchor: NSLayoutConstraint?
  private var readViewRightToReactionBackdropAnchor: NSLayoutConstraint?
  private var readViewBottomAnchor: NSLayoutConstraint?

  /// Left
  public var userHeaderViewLeft = NEUserHeaderView(frame: .zero) // 左侧头像
  public var avatarImageLeftAnchor: NSLayoutConstraint? // 左侧头像左侧布局依赖
  public var bubbleImageLeft = UIImageView() // 左侧气泡
  public var bubbleTopAnchorLeft: NSLayoutConstraint? // 左侧气泡顶部布局约束
  public var bubbleWLeft: NSLayoutConstraint? // 左侧气泡宽度布局约束
  public var bubbleHLeft: NSLayoutConstraint? // 左侧气泡高度布局约束
  private var bubbleLeadingLeft: NSLayoutConstraint?
  public var pinImageLeft = UIImageView() // 左侧标记图片
  public var pinLabelLeft = UILabel() // 左侧标记文案
  private var pinLabelHLeft: NSLayoutConstraint? // 左侧标记文案宽度布局约束
  private var pinLabelWLeft: NSLayoutConstraint? // 左侧标记文案高度布局约束
  public var fullNameLabel = UILabel() // 群昵称（只在群聊中有效）
  public var fullNameH: NSLayoutConstraint? // 群昵称高度布局约束

  /// Right
  public var userHeaderViewRight = NEUserHeaderView(frame: .zero) // 右侧头像
  public var bubbleImageRight = UIImageView() // 右侧气泡
  public var bubbleWRight: NSLayoutConstraint? // 右侧气泡宽度布局约束
  public var bubbleHRight: NSLayoutConstraint? // 右侧气泡高度布局约束
  private var bubbleTrailingRight: NSLayoutConstraint?
  public var pinImageRight = UIImageView() // 右侧标记图片
  public var pinLabelRight = UILabel() // 右侧标记文案
  private var pinLabelHRight: NSLayoutConstraint? // 右侧标记文案宽度布局约束
  private var pinLabelWRight: NSLayoutConstraint? // 右侧标记文案高度布局约束

  // 已读未读视图
  public var readView = CirleProgressView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
  public var activityView = ChatActivityIndicatorView() // 消息状态视图
  public var activityViewCenterYAnchor: NSLayoutConstraint? // 消息状态视图 Y 布局约束
  public var selectedButton = UIButton(type: .custom) // 多选按钮
  public var selectedButtonCenterYAnchor: NSLayoutConstraint? // 多选按钮中心 Y 布局约束
  public var timeLabel = UILabel() // 消息时间
  public var timeLabelHeightAnchor: NSLayoutConstraint? // 消息时间高度约束

  // 已读未读点击手势
  private var tapGesture: UITapGestureRecognizer?

  public var messageTextFont = UIFont.systemFont(ofSize: 16)
  public let messageMaxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    initProperty()
    reactionViewLeft.delegate = self
    reactionViewRight.delegate = self
    baseCommonUI()
    addGesture()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    reactionViewLeft.delegate = self
    reactionViewRight.delegate = self
  }

  deinit {
    gestureRecognizers?.forEach { gestrue in
      removeGestureRecognizer(gestrue)
    }
  }

  override open func layoutSubviews() {
    // Resolve the supplemental surface before UIKit lays out this pass, not
    // from the previous message's frame after layout has already completed.
    updateReactionSurface(reactionViewLeft,
                          backdrop: reactionBackdropLeft,
                          bubble: bubbleImageLeft)
    updateReactionSurface(reactionViewRight,
                          backdrop: reactionBackdropRight,
                          bubble: bubbleImageRight)
    super.layoutSubviews()
    // The original message surface must remain above the expandable Reaction
    // backdrop, especially for Fun media/card cells with transparent bubbles.
    contentView.bringSubviewToFront(bubbleImageLeft)
    contentView.bringSubviewToFront(bubbleImageRight)
    contentView.bringSubviewToFront(reactionViewLeft)
    contentView.bringSubviewToFront(reactionViewRight)
  }

  override open func prepareForReuse() {
    super.prepareForReuse()
    // A cell can be reused by a revoke/media row immediately after a reacted
    // row. Remove the supplemental surface before Auto Layout gets a chance
    // to render the old model for one frame.
    resetReactionSurfaceForReuse()
    contentModel = nil
  }

  open func setBubbleImage() {
    var image = ChatUIConfig.shared.messageProperties.receiveMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_receive")
    bubbleImageLeft.backgroundColor = ChatUIConfig.shared.messageProperties.receiveMessageBgColor

    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageLeft.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageLeft.image = image
      bubbleImageLeft.contentMode = .scaleAspectFill
    }

    image = ChatUIConfig.shared.messageProperties.selfMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_send")
    bubbleImageRight.backgroundColor = ChatUIConfig.shared.messageProperties.selfMessageBgColor

    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageRight.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageRight.image = image
      bubbleImageRight.contentMode = .scaleAspectFill
    }
  }

  open func initProperty() {
    timeLabel.font = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.timeTextSize)
    timeLabel.textColor = ChatUIConfig.shared.messageProperties.timeTextColor
    timeLabel.textAlignment = .center
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.accessibilityIdentifier = "id.messageTimeText"
    timeLabel.backgroundColor = .clear

    // avatar
    userHeaderViewLeft.translatesAutoresizingMaskIntoConstraints = false
    userHeaderViewLeft.clipsToBounds = true
    userHeaderViewLeft.isUserInteractionEnabled = true
    userHeaderViewLeft.titleLabel.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.userNickTextSize)
    userHeaderViewLeft.titleLabel.textColor = ChatUIConfig.shared.messageProperties.userNickColor

    userHeaderViewRight.translatesAutoresizingMaskIntoConstraints = false
    userHeaderViewRight.clipsToBounds = true
    userHeaderViewRight.isUserInteractionEnabled = true
    userHeaderViewRight.titleLabel.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.userNickTextSize)
    userHeaderViewRight.titleLabel.textColor = ChatUIConfig.shared.messageProperties.userNickColor

    // fullName
    fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
    fullNameLabel.font = UIFont.systemFont(ofSize: 12)
    fullNameLabel.textColor = UIColor.ne_lightText
    fullNameLabel.accessibilityIdentifier = "id.fullNameLabel"

    // bubbleImage
    setBubbleImage()
    bubbleImageLeft.translatesAutoresizingMaskIntoConstraints = false
    bubbleImageLeft.isUserInteractionEnabled = true

    bubbleImageRight.translatesAutoresizingMaskIntoConstraints = false
    bubbleImageRight.isUserInteractionEnabled = true

    pinLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    pinLabelLeft.textColor = UIColor.ne_greenText
    pinLabelLeft.font = UIFont.systemFont(ofSize: 12)
    pinLabelLeft.textAlignment = .left
    pinLabelLeft.lineBreakMode = .byTruncatingMiddle
    pinLabelLeft.accessibilityIdentifier = "id.signal"

    pinLabelRight.translatesAutoresizingMaskIntoConstraints = false
    pinLabelRight.textColor = UIColor.ne_greenText
    pinLabelRight.font = UIFont.systemFont(ofSize: 12)
    pinLabelRight.textAlignment = .right
    pinLabelRight.lineBreakMode = .byTruncatingMiddle
    pinLabelRight.accessibilityIdentifier = "id.signal"

    pinImageLeft.translatesAutoresizingMaskIntoConstraints = false
    pinImageLeft.contentMode = .scaleAspectFit

    pinImageRight.translatesAutoresizingMaskIntoConstraints = false
    pinImageRight.contentMode = .scaleAspectFit

    readView.translatesAutoresizingMaskIntoConstraints = false
    readView.accessibilityIdentifier = "id.readView"

    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.failButton.addTarget(self, action: #selector(resend), for: .touchUpInside)
    activityView.accessibilityIdentifier = "id.status"

    selectedButton.translatesAutoresizingMaskIntoConstraints = false
    selectedButton.setImage(coreLoader.loadImage("unselect"), for: .normal)
    selectedButton.setImage(coreLoader.loadImage("select"), for: .selected)
    selectedButton.addTarget(self, action: #selector(selectButtonClicked), for: .touchUpInside)
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .clear

    // time
    contentView.addSubview(timeLabel)
    timeLabelHeightAnchor = timeLabel.heightAnchor.constraint(equalToConstant: 22)
    timeLabelHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      timeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -0),
    ])

    baseCommonUILeft()
    baseCommonUIRight()
  }

  open func baseCommonUILeft() {
    contentView.addSubview(userHeaderViewLeft)
    avatarImageLeftAnchor = userHeaderViewLeft.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
    avatarImageLeftAnchor?.isActive = true
    NSLayoutConstraint.activate([
      userHeaderViewLeft.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: chat_content_margin),
      userHeaderViewLeft.widthAnchor.constraint(equalToConstant: 32),
      userHeaderViewLeft.heightAnchor.constraint(equalToConstant: 32),
    ])

    contentView.addSubview(fullNameLabel)
    fullNameH = fullNameLabel.heightAnchor.constraint(equalToConstant: 20)
    fullNameH?.isActive = true
    NSLayoutConstraint.activate([
      fullNameLabel.leftAnchor.constraint(equalTo: userHeaderViewLeft.rightAnchor, constant: chat_content_margin),
      fullNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      fullNameLabel.topAnchor.constraint(equalTo: userHeaderViewLeft.topAnchor),
    ])

    // Keep the message bubble as the original layout surface. Reaction is a
    // sibling below it so a wider reaction row never stretches text or media.
    contentView.addSubview(bubbleImageLeft)
    bubbleTopAnchorLeft = bubbleImageLeft.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 0)
    bubbleTopAnchorLeft?.isActive = true
    bubbleImageLeft.translatesAutoresizingMaskIntoConstraints = false
    bubbleWLeft = bubbleImageLeft.widthAnchor.constraint(equalToConstant: 0)
    bubbleWLeft?.isActive = true
    bubbleHLeft = bubbleImageLeft.heightAnchor.constraint(equalToConstant: 0)
    bubbleHLeft?.isActive = true
    bubbleLeadingLeft = bubbleImageLeft.leftAnchor.constraint(
      equalTo: userHeaderViewLeft.rightAnchor,
      constant: chat_content_margin
    )
    bubbleLeadingLeft?.isActive = true

    reactionBackdropLeft.translatesAutoresizingMaskIntoConstraints = false
    reactionBackdropLeft.image = bubbleImageLeft.image
    reactionBackdropLeft.backgroundColor = bubbleImageLeft.backgroundColor
    reactionBackdropLeft.contentMode = bubbleImageLeft.contentMode
    reactionBackdropLeft.isUserInteractionEnabled = true
    reactionBackdropLeft.isHidden = true
    contentView.insertSubview(reactionBackdropLeft, belowSubview: bubbleImageLeft)
    reactionBackdropLeadingLeft = reactionBackdropLeft.leftAnchor.constraint(
      equalTo: bubbleImageLeft.leftAnchor
    )
    reactionBackdropTopAnchorLeft = reactionBackdropLeft.topAnchor.constraint(
      equalTo: bubbleImageLeft.topAnchor
    )
    reactionBackdropWidthLeft = reactionBackdropLeft.widthAnchor.constraint(equalToConstant: 0)
    reactionBackdropHeightLeft = reactionBackdropLeft.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      reactionBackdropLeadingLeft!,
      reactionBackdropTopAnchorLeft!,
      reactionBackdropWidthLeft!,
      reactionBackdropHeightLeft!,
    ])

    contentView.addSubview(reactionViewLeft)
    reactionViewLeft.translatesAutoresizingMaskIntoConstraints = false
    reactionViewLeft.isHidden = true
    reactionWidthLeft = reactionViewLeft.widthAnchor.constraint(equalToConstant: 0)
    reactionHeightLeft = reactionViewLeft.heightAnchor.constraint(equalToConstant: 0)
    reactionTopAnchorLeft = reactionViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor)
    reactionLeadingLeft = reactionViewLeft.leftAnchor.constraint(
      equalTo: reactionBackdropLeft.leftAnchor,
      constant: Self.reactionHorizontalPadding
    )
    reactionTrailingLeft = reactionViewLeft.rightAnchor.constraint(
      lessThanOrEqualTo: reactionBackdropLeft.rightAnchor,
      constant: -Self.reactionHorizontalPadding
    )
    NSLayoutConstraint.activate([
      reactionLeadingLeft!,
      reactionTrailingLeft!,
      reactionTopAnchorLeft!,
      reactionWidthLeft!,
      reactionHeightLeft!,
    ])

    contentView.addSubview(pinLabelLeft)
    pinLabelHLeft = pinLabelLeft.heightAnchor.constraint(equalToConstant: 16)
    pinLabelHLeft?.isActive = true
    pinLabelWLeft = pinLabelLeft.widthAnchor.constraint(equalToConstant: pinLabelMaxWidth)
    pinLabelWLeft?.isActive = true
    NSLayoutConstraint.activate([
      pinLabelLeft.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      pinLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 14),
    ])

    contentView.addSubview(pinImageLeft)
    NSLayoutConstraint.activate([
      pinImageLeft.rightAnchor.constraint(equalTo: pinLabelLeft.leftAnchor, constant: -2),
      pinImageLeft.widthAnchor.constraint(equalToConstant: 10),
      pinImageLeft.centerYAnchor.constraint(equalTo: pinLabelLeft.centerYAnchor),
    ])
  }

  open func baseCommonUIRight() {
    contentView.addSubview(userHeaderViewRight)
    NSLayoutConstraint.activate([
      userHeaderViewRight.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      userHeaderViewRight.widthAnchor.constraint(equalToConstant: 32),
      userHeaderViewRight.heightAnchor.constraint(equalToConstant: 32),
      userHeaderViewRight.topAnchor.constraint(equalTo: userHeaderViewLeft.topAnchor, constant: 0),
    ])

    contentView.addSubview(bubbleImageRight)
    bubbleImageRight.translatesAutoresizingMaskIntoConstraints = false
    bubbleWRight = bubbleImageRight.widthAnchor.constraint(equalToConstant: 0)
    bubbleWRight?.isActive = true
    bubbleHRight = bubbleImageRight.heightAnchor.constraint(equalToConstant: 0)
    bubbleHRight?.isActive = true
    bubbleTrailingRight = bubbleImageRight.rightAnchor.constraint(
      equalTo: userHeaderViewRight.leftAnchor,
      constant: -chat_content_margin
    )
    NSLayoutConstraint.activate([
      bubbleImageRight.topAnchor.constraint(equalTo: userHeaderViewRight.topAnchor, constant: 0),
      bubbleTrailingRight!,
    ])

    reactionBackdropRight.translatesAutoresizingMaskIntoConstraints = false
    reactionBackdropRight.image = bubbleImageRight.image
    reactionBackdropRight.backgroundColor = bubbleImageRight.backgroundColor
    reactionBackdropRight.contentMode = bubbleImageRight.contentMode
    reactionBackdropRight.isUserInteractionEnabled = true
    reactionBackdropRight.isHidden = true
    contentView.insertSubview(reactionBackdropRight, belowSubview: bubbleImageRight)
    reactionBackdropTrailingRight = reactionBackdropRight.rightAnchor.constraint(
      equalTo: bubbleImageRight.rightAnchor
    )
    reactionBackdropTopAnchorRight = reactionBackdropRight.topAnchor.constraint(
      equalTo: bubbleImageRight.topAnchor
    )
    reactionBackdropWidthRight = reactionBackdropRight.widthAnchor.constraint(equalToConstant: 0)
    reactionBackdropHeightRight = reactionBackdropRight.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      reactionBackdropTrailingRight!,
      reactionBackdropTopAnchorRight!,
      reactionBackdropWidthRight!,
      reactionBackdropHeightRight!,
    ])

    contentView.addSubview(reactionViewRight)
    reactionViewRight.translatesAutoresizingMaskIntoConstraints = false
    reactionViewRight.isHidden = true
    reactionWidthRight = reactionViewRight.widthAnchor.constraint(equalToConstant: 0)
    reactionHeightRight = reactionViewRight.heightAnchor.constraint(equalToConstant: 0)
    reactionTopAnchorRight = reactionViewRight.topAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor)
    reactionLeadingRight = reactionViewRight.leftAnchor.constraint(
      equalTo: reactionBackdropRight.leftAnchor,
      constant: Self.reactionHorizontalPadding
    )
    reactionTrailingRight = reactionViewRight.rightAnchor.constraint(
      lessThanOrEqualTo: reactionBackdropRight.rightAnchor,
      constant: -Self.reactionHorizontalPadding
    )
    NSLayoutConstraint.activate([
      // Both directions stay leading-aligned inside the combined surface.
      reactionLeadingRight!,
      reactionTrailingRight!,
      reactionTopAnchorRight!,
      reactionWidthRight!,
      reactionHeightRight!,
    ])

//        activityView
    contentView.addSubview(activityView)
    activityViewCenterYAnchor = activityView.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor, constant: 0)
    activityViewCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      activityView.rightAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: -chat_content_margin),
      activityView.widthAnchor.constraint(equalToConstant: 22),
      activityView.heightAnchor.constraint(equalToConstant: 22),
    ])

//        readView
    contentView.addSubview(readView)
    readViewBottomAnchor = readView.bottomAnchor.constraint(
      equalTo: bubbleImageRight.bottomAnchor,
      constant: 0
    )
    readViewRightToBubbleAnchor = readView.rightAnchor.constraint(
      equalTo: bubbleImageRight.leftAnchor,
      constant: -chat_content_margin
    )
    readViewRightToReactionBackdropAnchor = readView.rightAnchor.constraint(
      equalTo: reactionBackdropRight.leftAnchor,
      constant: -chat_content_margin
    )
    NSLayoutConstraint.activate([
      readViewRightToBubbleAnchor!,
      readViewBottomAnchor!,
      readView.widthAnchor.constraint(equalToConstant: 16),
      readView.heightAnchor.constraint(equalToConstant: 16),
    ])

//        selectedButton
    contentView.addSubview(selectedButton)
    NSLayoutConstraint.activate([
      selectedButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      selectedButton.widthAnchor.constraint(equalToConstant: 18),
      selectedButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    contentView.addSubview(pinLabelRight)
    pinLabelHRight = pinLabelRight.heightAnchor.constraint(equalToConstant: 16)
    pinLabelHRight?.isActive = true
    pinLabelWRight = pinLabelRight.widthAnchor.constraint(equalToConstant: 210)
    pinLabelWRight?.isActive = true
    NSLayoutConstraint.activate([
      pinLabelRight.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      pinLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
    ])

    contentView.addSubview(pinImageRight)
    NSLayoutConstraint.activate([
      pinImageRight.rightAnchor.constraint(equalTo: pinLabelRight.leftAnchor, constant: -2),
      pinImageRight.centerYAnchor.constraint(equalTo: pinLabelRight.centerYAnchor),
      pinImageRight.widthAnchor.constraint(equalToConstant: 10),
    ])
  }

  open func addGesture() {
//        avatar
    let avatarTapRight = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarTapRight.cancelsTouchesInView = true
    userHeaderViewRight.addGestureRecognizer(avatarTapRight)
    let avatarTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarTapLeft.cancelsTouchesInView = true
    userHeaderViewLeft.addGestureRecognizer(avatarTapLeft)

    let avatarLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAvatar))
    avatarLongGesture.cancelsTouchesInView = false
    userHeaderViewLeft.addGestureRecognizer(avatarLongGesture)

    let messageTapRight = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapRight.cancelsTouchesInView = false
    let messageTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapLeft.cancelsTouchesInView = false
    let messageLongPressRight = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    let messageLongPressLeft = UILongPressGestureRecognizer(target: self, action: #selector(longPress))

    // A tap must wait for the long-press recognizer to fail, otherwise a
    // long press can also trigger the message tap callback on release.
    messageTapRight.require(toFail: messageLongPressRight)
    messageTapLeft.require(toFail: messageLongPressLeft)
    bubbleImageRight.addGestureRecognizer(messageTapRight)
    bubbleImageLeft.addGestureRecognizer(messageTapLeft)
    bubbleImageRight.addGestureRecognizer(messageLongPressRight)
    bubbleImageLeft.addGestureRecognizer(messageLongPressLeft)

    if supportsReactionLongPress {
      let reactionLongPressRight = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
      let reactionLongPressLeft = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
      let reactionBackdropLongPressRight = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
      let reactionBackdropLongPressLeft = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
      reactionViewRight.addGestureRecognizer(reactionLongPressRight)
      reactionViewLeft.addGestureRecognizer(reactionLongPressLeft)
      reactionBackdropRight.addGestureRecognizer(reactionBackdropLongPressRight)
      reactionBackdropLeft.addGestureRecognizer(reactionBackdropLongPressLeft)
    }

    let tapReadView = UITapGestureRecognizer(target: self, action: #selector(tapReadView))
    tapReadView.cancelsTouchesInView = true
    readView.addGestureRecognizer(tapReadView)
    tapGesture = tapReadView
  }

  open func initSubviewsLayout() {
    if ChatUIConfig.shared.messageProperties.avatarType == .cycle {
      userHeaderViewRight.layer.cornerRadius = 16.0
      userHeaderViewLeft.layer.cornerRadius = 16.0
    } else if ChatUIConfig.shared.messageProperties.avatarCornerRadius > 0 {
      userHeaderViewRight.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
      userHeaderViewLeft.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
    } else {
      userHeaderViewRight.layer.cornerRadius = 16.0
      userHeaderViewLeft.layer.cornerRadius = 16.0
    }
  }

//    MARK: event

  open func tapAvatar(tap: UITapGestureRecognizer) {
    delegate?.didTapAvatarView(self, contentModel)
  }

  open func tapMessage(tap: UITapGestureRecognizer) {
    delegate?.didTapMessageView(self, contentModel, contentModel?.replyedModel)
  }

  open func longPressAvatar(longPress: UITapGestureRecognizer) {
    if longPress.state == .began {
      delegate?.didLongPressAvatar(self, contentModel)
    }
  }

  open func longPress(longPress: UILongPressGestureRecognizer) {
    if longPress.state == .began {
      delegate?.didLongPressMessageView(self, contentModel)
    }
  }

  open func resend(button: UIButton) {
    print("state:default")
    delegate?.didTapResendView(self, contentModel)
  }

  open func tapReadView(tap: UITapGestureRecognizer) {
    delegate?.didTapReadView(self, contentModel)
  }

  public func reactionView(_ view: NEMessageReactionView, didSelectIndex index: Int) {
    delegate?.didTapReaction?(self, contentModel, index)
  }

  open func selectButtonClicked() {
    selectedButton.isSelected = !selectedButton.isSelected
    if let model = contentModel {
      model.isSelected = !model.isSelected
    }
    delegate?.didTapSelectButton(self, contentModel)
  }

//    MARK: set data

  /// 设置是否允许多选
  /// - Parameters:
  ///   - model: 数据模型
  ///   - enableSelect: 是否处于多选状态
  open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    // 多选框
    selectedButton.isHidden = model.isRevoked || !enableSelect
    selectedButton.isSelected = model.isSelected

    // 多选状态下，头像右移
    avatarImageLeftAnchor?.constant = enableSelect ? chat_min_h : 16

    // 多选状态下，消息状态视图（发送失败）位置下移，避免与多选重叠
    activityViewCenterYAnchor?.constant = enableSelect ? model.contentSize.height / 2 - 12 : 0
  }

  override open func setModel(_ model: MessageContentModel) {
    setModel(model, ChatMessageHelper.isSelf(message: model.message))
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    // Reaction expands the current bubble and must never replace its skin.
    // Clear only supplemental surfaces from the previous model; subclasses
    // may install a custom card image again after this call.
    reactionBackdropLeft.image = nil
    reactionBackdropRight.image = nil
    reactionBackdropLeft.backgroundColor = .clear
    reactionBackdropRight.backgroundColor = .clear
    reactionBackdropLeft.isHidden = true
    reactionBackdropRight.isHidden = true
    reactionBackdropLeft.alpha = 0
    reactionBackdropRight.alpha = 0
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubbleH = isSend ? bubbleHRight : bubbleHLeft
    let userHeaderView = isSend ? userHeaderViewRight : userHeaderViewLeft
    messageTextFont = UIFont.systemFont(ofSize: isSend ? ChatUIConfig.shared.messageProperties.receiveMessageTextSize : ChatUIConfig.shared.messageProperties.selfMessageTextSize)

    contentModel = model
    contentModel?.cell = self
    // Reaction measurement can trigger layout while binding a reused cell.
    // Install the current body dimensions before measuring its subviews.
    bubbleW?.constant = model.contentSize.width
    bubbleH?.constant = model.contentSize.height
    let reactionEnabled = IMKitConfigCenter.shared.enableEmojiReaction &&
      !model.isRevoked &&
      model.message?.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED
    reactionViewLeft.configure(groups: model.reactionGroups,
                               enabled: !isSend && reactionEnabled,
                               isOutgoing: false)
    reactionViewRight.configure(groups: model.reactionGroups,
                                enabled: isSend && reactionEnabled,
                                isOutgoing: true)
    let reactionView = isSend ? reactionViewRight : reactionViewLeft
    let hasReaction = reactionEnabled && !model.reactionGroups.isEmpty
    let reactionTopSpacing = hasReaction ? reactionTopSpacing(for: model) : 0
    let reactionBottomSpacing = hasReaction ? reactionBottomSpacing(for: model) : 0
    let reactionVerticalSpacing = reactionTopSpacing + reactionBottomSpacing
    reactionTopAnchorLeft?.constant = reactionTopSpacing
    reactionTopAnchorRight?.constant = reactionTopSpacing
    let leadingInset = reactionLeadingInset(for: model, isOutgoing: isSend)
    let trailingInset = reactionTrailingInset(for: model, isOutgoing: isSend)
    reactionLeadingLeft?.constant = leadingInset
    reactionTrailingLeft?.constant = -trailingInset
    reactionLeadingRight?.constant = leadingInset
    reactionTrailingRight?.constant = -trailingInset
    // Resolve the capsule subviews before measuring. This is important for
    // the right-hand surface, which otherwise has no trailing constraint and
    // can be laid out with a transient zero width on the first pass.
    reactionView.layoutIfNeeded()
    // Text reactions use the available message width rather than the measured
    // glyph width. Short message bubbles otherwise force every capsule
    // onto its own row because their minimum bubble height resembles a
    // multi-line message.
    let locksSurfaceWidth = locksReactionSurfaceToMessageWidth(for: model)
    let tailInset = hasReaction
      ? reactionBackdropTailInset(for: model, isOutgoing: isSend)
      : 0
    let reactionMaxWidth = locksSurfaceWidth
      ? max(26, model.contentSize.width + tailInset - leadingInset - trailingInset)
      : max(26, chat_content_maxW - leadingInset - trailingInset)
    let bodyPadding = hasReaction ? reactionBodyPadding(for: model) : 0
    let measuredReactionWidth = hasReaction
      ? reactionView.layoutWidth(forMaxWidth: reactionMaxWidth)
      : 0
    // Use the widest row produced by the actual flow calculation. The natural
    // total width is intentionally not a lower bound after wrapping.
    let reactionWidth = hasReaction
      ? min(reactionMaxWidth, max(measuredReactionWidth, 26))
      : 0
    let reactionViewHeight = hasReaction
      ? reactionView.height(forWidth: reactionWidth)
      : 0
    model.reactionHeight = hasReaction
      ? reactionViewHeight + reactionVerticalSpacing
      : 0
    // Keep the hidden backdrop measured to the primary bubble so Fun/WeChat
    // supplemental content can always anchor below the same body surface.
    let reactionBackdropWidth: CGFloat
    if hasReaction, locksSurfaceWidth {
      reactionBackdropWidth = model.contentSize.width + tailInset + bodyPadding * 2
    } else {
      reactionBackdropWidth = hasReaction
        ? max(model.contentSize.width + tailInset + bodyPadding * 2,
              reactionWidth + leadingInset + trailingInset)
        : model.contentSize.width
    }
    // The backdrop starts bodyPadding above the message body and needs the
    // same clearance below the Reaction row, so reserve both sides.
    let reactionBackdropHeight = model.contentSize.height + model.reactionHeight + bodyPadding * 2
    if isSend {
      reactionWidthRight?.constant = reactionWidth
      reactionHeightRight?.constant = reactionViewHeight
      reactionBackdropWidthRight?.constant = reactionBackdropWidth
      reactionBackdropHeightRight?.constant = reactionBackdropHeight
    } else {
      reactionWidthLeft?.constant = reactionWidth
      reactionHeightLeft?.constant = reactionViewHeight
      reactionBackdropWidthLeft?.constant = reactionBackdropWidth
      reactionBackdropHeightLeft?.constant = reactionBackdropHeight
    }
    if !usesInlineReactionSurface {
      updateReactionSurfacePosition(messageWidth: model.contentSize.width,
                                    backdropWidth: reactionBackdropWidth,
                                    tailInset: tailInset,
                                    bodyPadding: bodyPadding,
                                    isOutgoing: isSend)
    }
    updateReadViewPosition(
      isOutgoing: isSend,
      usesReactionBackdrop: hasReaction && !usesInlineReactionSurface,
      bottomOffset: usesInlineReactionSurface ? 0 : model.reactionHeight + bodyPadding
    )
    tapGesture?.isEnabled = true
    showLeftOrRight(showRight: isSend)
    if hasReaction {
      let backdrop = isSend ? reactionBackdropRight : reactionBackdropLeft
      let bubble = isSend ? bubbleImageRight : bubbleImageLeft
      applyReactionBackdropAppearance(backdrop, bubble: bubble)
      if !usesInlineReactionSurface {
        backdrop.alpha = 1
      }
    }
    updatePinStatus(model, isSend)

    // time
    if let time = model.timeContent, !time.isEmpty {
      timeLabelHeightAnchor?.constant = chat_timeCellH
      timeLabel.text = time
      timeLabel.isHidden = false
    } else {
      timeLabelHeightAnchor?.constant = 0
      timeLabel.text = ""
      timeLabel.isHidden = true
    }

    selectedButtonCenterYAnchor = selectedButton.centerYAnchor.constraint(equalTo: isSend ? bubbleImageRight.centerYAnchor : bubbleImageLeft.centerYAnchor)
    selectedButtonCenterYAnchor?.priority = .defaultHigh
    selectedButtonCenterYAnchor?.isActive = true

    // avatar
    let url = model.avatar
    let name = model.shortName ?? ""
    let accountId = ChatMessageHelper.getSenderId(model.message) ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)

    if model.fullNameHeight > 0 {
      fullNameLabel.text = model.fullName
      fullNameLabel.isHidden = false
      bubbleTopAnchorLeft?.constant = 0
    } else {
      fullNameLabel.text = nil
      fullNameLabel.isHidden = true
      bubbleTopAnchorLeft?.constant = 4
    }
    fullNameH?.constant = CGFloat(model.fullNameHeight)

    if isSend, model.message?.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED {
      if model.message?.conversationType == .CONVERSATION_TYPE_P2P {
        // 话单消息不显示已读未读
        let receiptEnable = model.type != .rtcCallRecord
        if receiptEnable,
           !model.isRevoked,
           SettingRepo.shared.getShowReadStatus(),
           ChatUIConfig.shared.messageProperties.showP2PMessageStatus == true {
          readView.isHidden = false
          if model.readCount == 1, model.unreadCount == 0 {
            readView.progress = 1
          } else {
            readView.progress = 0
          }
        } else {
          readView.isHidden = true
        }
      } else if model.message?.conversationType == .CONVERSATION_TYPE_TEAM {
        // readReceiptEnabled 配置只对群聊消息有效
        let receiptEnable = model.message?.messageConfig?.readReceiptEnabled ?? false
        if receiptEnable,
           !model.isRevoked,
           SettingRepo.shared.getShowReadStatus(),
           ChatUIConfig.shared.messageProperties.showTeamMessageStatus == true {
          readView.isHidden = false
          var total = NETeamUserManager.shared.getTeamInfo()?.memberCount ?? 0
          if model.readCount + model.unreadCount != 0 {
            total = model.readCount + model.unreadCount + 1
          }
          if total > ChatUIConfig.shared.maxReadingNum {
            readView.isHidden = true
          } else {
            if total - 1 > 0 {
              let progress = Float(model.readCount) / Float(total - 1)
              readView.progress = progress
              if progress >= 1.0 {
                tapGesture?.isEnabled = false
              }
            } else {
              readView.progress = 0
            }
          }
        } else {
          readView.isHidden = true
        }
      }
    } else {
      readView.isHidden = true
    }

    if isSend {
      switch model.message?.sendingState {
      case .MESSAGE_SENDING_STATE_SENDING:
        activityView.messageStatus = .sending
      case .MESSAGE_SENDING_STATE_SUCCEEDED:
        if model.message?.messageStatus.errorCode != operationSuccess {
          activityView.messageStatus = .sendingFailed
          readView.isHidden = true
        } else {
          activityView.messageStatus = .successed
        }
      case .MESSAGE_SENDING_STATE_FAILED:
        activityView.messageStatus = .failed
      default:
        activityView.messageStatus = .sending
      }
    } else {
      activityView.messageStatus = .successed
    }

    delegate?.messageWillShow?(self, model)
  }

  /// Clears a reused Reaction surface while retaining the original bubble
  /// artwork for the next model configured into this cell.
  open func resetReactionSurfaceForReuse() {
    reactionBackdropLeft.image = nil
    reactionBackdropRight.image = nil
    reactionBackdropLeft.backgroundColor = .clear
    reactionBackdropRight.backgroundColor = .clear
    reactionViewLeft.configure(groups: [], enabled: false, isOutgoing: false)
    reactionViewRight.configure(groups: [], enabled: false, isOutgoing: true)
    reactionWidthLeft?.constant = 0
    reactionHeightLeft?.constant = 0
    reactionWidthRight?.constant = 0
    reactionHeightRight?.constant = 0
    reactionBackdropWidthLeft?.constant = 0
    reactionBackdropHeightLeft?.constant = 0
    reactionBackdropWidthRight?.constant = 0
    reactionBackdropHeightRight?.constant = 0
    bubbleLeadingLeft?.constant = chat_content_margin
    bubbleTrailingRight?.constant = -chat_content_margin
    reactionBackdropLeadingLeft?.constant = 0
    reactionBackdropTrailingRight?.constant = 0
    reactionBackdropTopAnchorLeft?.constant = 0
    reactionBackdropTopAnchorRight?.constant = 0
    reactionTopAnchorLeft?.constant = 0
    reactionTopAnchorRight?.constant = 0
    updateReadViewPosition(isOutgoing: false,
                           usesReactionBackdrop: false,
                           bottomOffset: 0)
    reactionBackdropLeft.isHidden = true
    reactionBackdropRight.isHidden = true
    reactionBackdropLeft.alpha = 0
    reactionBackdropRight.alpha = 0
  }

  private func updateReactionSurface(_ reactionView: NEMessageReactionView,
                                     backdrop: UIImageView,
                                     bubble: UIImageView) {
    if usesInlineReactionSurface {
      backdrop.isHidden = true
      backdrop.alpha = 0
      backdrop.image = nil
      backdrop.backgroundColor = .clear
      return
    }
    // Revoke rows are rendered as a system notification and never own a
    // Reaction surface. Short-circuit before any reused backdrop artwork or
    // dimensions can be restored during the final layout pass.
    if contentModel?.type == .revoke {
      backdrop.isHidden = true
      backdrop.alpha = 0
      backdrop.image = nil
      backdrop.backgroundColor = .clear
      if bubble === bubbleImageRight {
        reactionWidthRight?.constant = 0
        reactionHeightRight?.constant = 0
        reactionBackdropWidthRight?.constant = 0
        reactionBackdropHeightRight?.constant = 0
      } else {
        reactionWidthLeft?.constant = 0
        reactionHeightLeft?.constant = 0
        reactionBackdropWidthLeft?.constant = 0
        reactionBackdropHeightLeft?.constant = 0
      }
      return
    }
    guard reactionView.isEnabledForDisplay else {
      backdrop.isHidden = true
      backdrop.alpha = 0
      backdrop.image = nil
      backdrop.backgroundColor = .clear
      return
    }
    // Cell subclasses can change the message surface during their own layout
    // pass (media cells restore the skin after installing the thumbnail). Keep
    // the direction-aware inset authoritative on every pass so a reused
    // WeChat media row cannot fall back to the base zero-edge position.
    if let model = contentModel {
      let outgoing = bubble === bubbleImageRight
      let leading = reactionLeadingInset(for: model, isOutgoing: outgoing)
      let trailing = reactionTrailingInset(for: model, isOutgoing: outgoing)
      if outgoing {
        reactionLeadingRight?.constant = leading
        reactionTrailingRight?.constant = -trailing
      } else {
        reactionLeadingLeft?.constant = leading
        reactionTrailingLeft?.constant = -trailing
      }
    }
    backdrop.alpha = 1
    // Keep the directional surface visible only for the side currently bound
    // to this cell. This prevents a stale hidden-side backdrop from becoming
    // visible after a direction change during reuse.
    backdrop.isHidden = bubble.isHidden
    applyReactionBackdropAppearance(backdrop, bubble: bubble)
    // Keep the original bubble as the foreground surface. The backdrop is a
    // sibling used only to extend the skin behind the Reaction row; clearing
    // the foreground image makes reacted messages appear to use a different
    // bubble resource (and breaks custom/Fun skins).

    if let model = contentModel {
      // Subclasses can resolve their final body width after the base model
      // pass. Reconcile the combined surface without stretching that body.
      let messageWidth = resolvedFixedFormatBubbleWidth(for: bubble)
      let outgoing = bubble === bubbleImageRight
      let leadingInset = reactionLeadingInset(for: model,
                                              isOutgoing: outgoing)
      let trailingInset = reactionTrailingInset(for: model,
                                                isOutgoing: outgoing)
      let locksSurfaceWidth = locksReactionSurfaceToMessageWidth(for: model)
      let tailInset = reactionBackdropTailInset(for: model,
                                                isOutgoing: outgoing)
      let bodyPadding = reactionView.isEnabledForDisplay
        ? reactionBodyPadding(for: model)
        : 0
      let maxWidth = locksSurfaceWidth
        ? max(26, messageWidth + tailInset - leadingInset - trailingInset)
        : max(26, chat_content_maxW - leadingInset - trailingInset)
      let resolvedWidth = min(maxWidth,
                              max(reactionView.layoutWidth(forMaxWidth: maxWidth), 26))
      let resolvedHeight = reactionView.height(forWidth: resolvedWidth)
      let topSpacing = reactionTopSpacing(for: model)
      let bottomSpacing = reactionBottomSpacing(for: model)
      if outgoing {
        reactionTopAnchorRight?.constant = topSpacing
      } else {
        reactionTopAnchorLeft?.constant = topSpacing
      }
      let width = locksSurfaceWidth
        ? messageWidth + tailInset + bodyPadding * 2
        : max(messageWidth + tailInset + bodyPadding * 2,
              resolvedWidth + leadingInset + trailingInset)
      let resolvedReactionHeight = resolvedHeight + topSpacing + bottomSpacing
      let height = max(0, resolvedBubbleHeight(for: bubble) + resolvedReactionHeight + bodyPadding * 2)
      if bubble === bubbleImageRight {
        reactionWidthRight?.constant = resolvedWidth
        reactionHeightRight?.constant = resolvedHeight
        reactionBackdropWidthRight?.constant = width
        reactionBackdropHeightRight?.constant = height
      } else {
        reactionWidthLeft?.constant = resolvedWidth
        reactionHeightLeft?.constant = resolvedHeight
        reactionBackdropWidthLeft?.constant = width
        reactionBackdropHeightLeft?.constant = height
      }
      if abs(model.reactionHeight - resolvedReactionHeight) > 0.5 {
        model.reactionHeight = resolvedReactionHeight
      }
      updateReactionSurfacePosition(messageWidth: messageWidth,
                                    backdropWidth: width,
                                    tailInset: tailInset,
                                    bodyPadding: bodyPadding,
                                    isOutgoing: outgoing)
      updateReadViewPosition(isOutgoing: outgoing,
                             usesReactionBackdrop: true,
                             bottomOffset: resolvedReactionHeight + bodyPadding)
    }
  }

  private func updateReadViewPosition(isOutgoing: Bool,
                                      usesReactionBackdrop: Bool,
                                      bottomOffset: CGFloat) {
    let anchorsToBackdrop = isOutgoing && usesReactionBackdrop
    if anchorsToBackdrop {
      readViewRightToBubbleAnchor?.isActive = false
      readViewRightToReactionBackdropAnchor?.isActive = true
    } else {
      readViewRightToReactionBackdropAnchor?.isActive = false
      readViewRightToBubbleAnchor?.isActive = true
    }
    readViewBottomAnchor?.constant = isOutgoing ? bottomOffset : 0
  }

  private func updateReactionSurfacePosition(messageWidth: CGFloat,
                                             backdropWidth: CGFloat,
                                             tailInset: CGFloat,
                                             bodyPadding: CGFloat,
                                             isOutgoing: Bool) {
    if isOutgoing {
      let totalExtension = max(0, backdropWidth - messageWidth)
      // Anchor the expanded surface at the original outgoing edge, then keep
      // the message body on its leading side. Media retains its 4pt body gap;
      // a Fun tail and any extra Reaction width remain on the trailing side.
      let bodyOffset = max(0, totalExtension - bodyPadding)
      bubbleTrailingRight?.constant = -(chat_content_margin + bodyOffset)
      reactionBackdropTrailingRight?.constant = bodyOffset
    } else {
      bubbleLeadingLeft?.constant = chat_content_margin + tailInset
      reactionBackdropLeadingLeft?.constant = -(tailInset + bodyPadding)
    }
    reactionBackdropTopAnchorLeft?.constant = -bodyPadding
    reactionBackdropTopAnchorRight?.constant = -bodyPadding
  }

  private func applyReactionBackdropAppearance(_ backdrop: UIImageView,
                                               bubble: UIImageView) {
    // Full-bleed media/card cells intentionally clear the foreground bubble
    // image. Preserve an installed surface, then fall back to the skin asset.
    if let image = bubble.image {
      backdrop.image = image
    } else if backdrop.image == nil,
              let image = reactionBackdropImage(isOutgoing: bubble === bubbleImageRight) {
      backdrop.image = image
    }
    if let model = contentModel {
      let shouldCopyBackground = shouldCopyBubbleBackgroundToReactionBackdrop(for: model)
      if shouldCopyBackground, bubble.backgroundColor != .clear {
        backdrop.backgroundColor = bubble.backgroundColor
      } else if !shouldCopyBackground {
        backdrop.backgroundColor = .clear
      }
    }
    backdrop.contentMode = bubble.contentMode
  }

  private func resolvedFixedFormatBubbleWidth(for bubble: UIImageView) -> CGFloat {
    let constraint = bubble === bubbleImageRight ? bubbleWRight : bubbleWLeft
    // The width constraint is the model's authoritative media/card size. A
    // reused cell can still expose the previous frame during the first layout
    // pass, so prefer the constraint and only fall back to the frame when the
    // model has not supplied a size yet.
    let constrained = max(0, constraint?.constant ?? 0)
    if constrained > 0 {
      return constrained
    }
    return max(0, bubble.bounds.width)
  }

  private func resolvedBubbleHeight(for bubble: UIImageView) -> CGFloat {
    let constraint = bubble === bubbleImageRight ? bubbleHRight : bubbleHLeft
    let constrained = max(0, constraint?.constant ?? 0)
    return constrained > 0 ? constrained : max(0, bubble.bounds.height)
  }

  open func reactionHorizontalInset(for model: MessageContentModel) -> CGFloat {
    usesFixedReactionSurface(for: model)
      ? Self.reactionMediaHorizontalPadding
      : Self.reactionHorizontalPadding
  }

  /// Extra outer spacing used only when a fixed-format body owns a Reaction
  /// surface. The media body keeps its measured size.
  open func reactionBodyPadding(for model: MessageContentModel) -> CGFloat {
    [.image, .video, .file].contains(model.type) ? Self.reactionMediaBodyPadding : 0
  }

  /// Vertical space between the primary message body and its Reaction row.
  open func reactionTopSpacing(for model: MessageContentModel) -> CGFloat {
    Self.reactionBottomPadding
  }

  /// Vertical space between the Reaction row and the combined bubble bottom.
  open func reactionBottomSpacing(for model: MessageContentModel) -> CGFloat {
    0
  }

  /// Direction-aware insets let Fun/WeChat keep the Reaction capsules aligned
  /// with the actual text column (the tail adds margin on only one side).
  open func reactionLeadingInset(for model: MessageContentModel,
                                isOutgoing: Bool) -> CGFloat {
    reactionHorizontalInset(for: model) + reactionBodyPadding(for: model)
  }

  open func reactionTrailingInset(for model: MessageContentModel,
                                 isOutgoing: Bool) -> CGFloat {
    reactionHorizontalInset(for: model) + reactionBodyPadding(for: model)
  }

  /// Extra width occupied by a directional bubble tail outside the fixed
  /// message body. Skins without a separate tail keep this at zero.
  open func reactionBackdropTailInset(for model: MessageContentModel,
                                      isOutgoing: Bool) -> CGFloat {
    0
  }

  /// Optional fallback for cells whose foreground surface is a full-bleed
  /// media/card view and therefore has no bubble image of its own.
  open func reactionBackdropImage(isOutgoing: Bool) -> UIImage? {
    nil
  }

  /// File/card subclasses can keep an opaque body color without painting that
  /// color through the directional Reaction extension behind it.
  open func shouldCopyBubbleBackgroundToReactionBackdrop(for model: MessageContentModel) -> Bool {
    true
  }

  public func usesFixedReactionSurface(for model: MessageContentModel) -> Bool {
    [.image, .video, .file, .location, .multiForward].contains(model.type)
  }

  /// Fixed-format Reaction rows normally fit the measured message surface.
  /// Skins can opt in for media types whose directional bubble must remain
  /// aligned with the message body while reactions wrap inside it.
  open func locksReactionSurfaceToMessageWidth(for model: MessageContentModel) -> Bool {
    usesFixedReactionSurface(for: model) && ![.image, .video].contains(model.type)
  }

  /// 根据消息发送方向决定元素的显隐
  /// @param showRight    是否右侧显示（是否是发送的消息）
  open func showLeftOrRight(showRight: Bool) {
    userHeaderViewLeft.isHidden = showRight
    bubbleImageLeft.isHidden = showRight
    reactionViewLeft.isHidden = showRight || !reactionViewLeft.isEnabledForDisplay
    reactionBackdropLeft.isHidden = usesInlineReactionSurface || showRight || !reactionViewLeft.isEnabledForDisplay
    pinImageLeft.isHidden = showRight
    pinLabelLeft.isHidden = showRight
    fullNameLabel.isHidden = showRight

    userHeaderViewRight.isHidden = !showRight
    bubbleImageRight.isHidden = !showRight
    reactionViewRight.isHidden = !showRight || !reactionViewRight.isEnabledForDisplay
    reactionBackdropRight.isHidden = usesInlineReactionSurface || !showRight || !reactionViewRight.isEnabledForDisplay
    pinImageRight.isHidden = !showRight
    pinLabelRight.isHidden = !showRight
    activityView.isHidden = !showRight
    readView.isHidden = !showRight
  }

  /// 重置文本选中状态
  open func resetSelectRange() {}

  /// 选中所有文本
  open func selectAllRange() {}

  /// 更新标记状态
  open func updatePinStatus(_ model: MessageContentModel, _ isSend: Bool) {
    let pinLabel = isSend ? pinLabelRight : pinLabelLeft
    let pinImage = isSend ? pinImageRight : pinImageLeft
    let pinLabelH = isSend ? pinLabelHRight : pinLabelHLeft
    let pinLabelW = isSend ? pinLabelWRight : pinLabelWLeft

    pinLabel.isHidden = !model.isPined
    pinImage.isHidden = !model.isPined
    contentView.backgroundColor = model.isPined ? ChatUIConfig.shared.messageProperties.signalBgColor : .clear
    if model.isPined {
      let pinText = String(format: chatLocalizable("pin_text"), chatLocalizable("You"))
      if model.pinAccount == nil {
        pinLabel.text = pinText
      } else if let account = model.pinAccount, account == IMKitClient.instance.account() {
        pinLabel.text = pinText
      } else if let text = model.pinShowName {
        pinLabel.text = String(format: chatLocalizable("pin_text"), text)
      }

      pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
      let showText = pinLabel.text ?? pinText
      let size = String.getRealSize(showText, .systemFont(ofSize: 12), CGSize(width: pinLabelMaxWidth, height: CGFloat.greatestFiniteMagnitude))
      pinLabelH?.constant = CGFloat(chat_pin_height)
      pinLabelW?.constant = min(size.width + 1, pinLabelMaxWidth)
    } else {
      pinImage.image = nil
      pinLabelH?.constant = 0
      pinLabelW?.constant = 0
    }
  }

  func sizeWidthFromString(_ text: NSAttributedString, _ font: UIFont) -> Double {
    // 根据内容计算size
    let maxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let labelSize = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    return ceil(labelSize.width) + chat_content_margin * 2
  }

  func sizeHeightFromString(_ text: NSAttributedString, _ font: UIFont) -> Double {
    // 根据内容计算size
    let maxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let labelSize = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

    return ceil(labelSize.height) + chat_content_margin * 2
  }
}

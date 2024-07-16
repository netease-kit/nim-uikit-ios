
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class ForwardItem: NSObject {
  var conversationId: String?
  var name: String?
  var avatar: String?
  override public init() {}
}

@objcMembers
open class NEBaseForwardSessionCell: UICollectionViewCell {
  public lazy var sessionHeaderView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.titleLabel.font = NEConstant.defaultTextFont(11.0)
    headerView.clipsToBounds = true
    headerView.accessibilityIdentifier = "id.forwardHeaderView"
    return headerView
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(sessionHeaderView)
    NSLayoutConstraint.activate([
      sessionHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      sessionHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      sessionHeaderView.widthAnchor.constraint(equalToConstant: 32.0),
      sessionHeaderView.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}

@objcMembers
open class NEBaseForwardAlertViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {
  let settingRepo = SettingRepo.shared
  typealias ForwardCallBack = (String?) -> Void
  var cancelBlock: ForwardCallBack?
  var sureBlock: ForwardCallBack?

  /// 转发会话列表
  var forwardSessions = [ForwardItem]()

  /// 转发方式，合并转发 / 逐条转发 / 转发
  var forwardType = chatLocalizable("operation_forward")

  /// 会话名称
  var sessionName = ""

  /// 消息发送者名称
  var senderName = ""

  /// 确定按钮
  lazy var sureButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(sureClick), for: .touchUpInside)
    button.setTitle(chatLocalizable("send"), for: .normal)
    button.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    button.accessibilityIdentifier = "id.forwardSendBtn"
    return button
  }()

  /// 【发送给】 标签
  lazy var tipLabel: UILabel = {
    let tipLabel = UILabel()
    tipLabel.translatesAutoresizingMaskIntoConstraints = false
    tipLabel.font = NEConstant.defaultTextFont(16.0)
    tipLabel.textColor = .ne_darkText
    tipLabel.text = chatLocalizable("send_to")
    tipLabel.accessibilityIdentifier = "id.forwardTitle"
    return tipLabel
  }()

  public var contentViewCenterYAnchor: NSLayoutConstraint?

  /// 多个转发的 CollectionView
  public lazy var sessionCollectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 9.5
    flowLayout.minimumInteritemSpacing = 9.5
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    return collectionView
  }()

  /// 背景容器
  public lazy var contentView: UIView = {
    let backView = UIView()
    backView.backgroundColor = .white
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    return backView
  }()

  /// 单个转发对象时的 头像
  public lazy var oneSessionHeadView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.clipsToBounds = true
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.accessibilityIdentifier = "id.forwardHeaderView"
    return headerView
  }()

  /// 单个转发对象时的 名称
  public lazy var oneSessionNameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textColor = .ne_darkText
    nameLabel.font = NEConstant.defaultTextFont(14.0)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    return nameLabel
  }()

  /// 转发描述
  public lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(14.0)
    label.textColor = .ne_darkText
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingMiddle
    label.accessibilityIdentifier = "id.forwardContentText"
    return label
  }()

  /// 留言
  public lazy var commentTextFeild: UITextField = {
    let textFeild = UITextField()
    textFeild.translatesAutoresizingMaskIntoConstraints = false
    textFeild.placeholder = chatLocalizable("leave_message")
    textFeild.layer.cornerRadius = 4
    textFeild.layer.borderWidth = 1
    textFeild.layer.borderColor = forwardLineColor.cgColor
    textFeild.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
    textFeild.leftViewMode = .always
    textFeild.font = .systemFont(ofSize: 14)
    return textFeild
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let parent = parent as? ChatViewController {
      parent.isCurrentPage = false
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillShow(_:)),
                                           name: UIResponder.keyboardWillShowNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillHide(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.viewControllers.last?.view.endEditing(false)
  }

  open func setupUI() {
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.4)

    // 添加背景容器
    view.addSubview(contentView)
    contentViewCenterYAnchor = contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    contentViewCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.widthAnchor.constraint(equalToConstant: 276),
      contentView.heightAnchor.constraint(equalToConstant: 250),
    ])

    // 【发送给】
    contentView.addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      tipLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      tipLabel.heightAnchor.constraint(equalToConstant: 18.0),
    ])

    // 单个转发的头像
    contentView.addSubview(oneSessionHeadView)
    NSLayoutConstraint.activate([
      oneSessionHeadView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      oneSessionHeadView.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 16),
      oneSessionHeadView.widthAnchor.constraint(equalToConstant: 32.0),
      oneSessionHeadView.heightAnchor.constraint(equalToConstant: 32.0),
    ])

    // 单个转发的名称
    contentView.addSubview(oneSessionNameLabel)
    NSLayoutConstraint.activate([
      oneSessionNameLabel.leftAnchor.constraint(equalTo: oneSessionHeadView.rightAnchor, constant: 8.0),
      oneSessionNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      oneSessionNameLabel.centerYAnchor.constraint(equalTo: oneSessionHeadView.centerYAnchor),
    ])

    // 多个转发的 CollectionView
    contentView.addSubview(sessionCollectionView)
    NSLayoutConstraint.activate([
      sessionCollectionView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      sessionCollectionView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -16.0
      ),
      sessionCollectionView.heightAnchor.constraint(equalToConstant: 32.0),
      sessionCollectionView.topAnchor.constraint(equalTo: oneSessionHeadView.topAnchor),
    ])

    // 转发描述的背景
    let textBackView = UIView()
    textBackView.translatesAutoresizingMaskIntoConstraints = false
    textBackView.backgroundColor = NEConstant.hexRGB(0xF2F4F5)
    textBackView.clipsToBounds = true
    textBackView.layer.cornerRadius = 4.0
    contentView.addSubview(textBackView)
    NSLayoutConstraint.activate([
      textBackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      textBackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      textBackView.topAnchor.constraint(equalTo: oneSessionHeadView.bottomAnchor, constant: 12.0),
    ])

    // 转发描述
    textBackView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: textBackView.leftAnchor, constant: 12),
      contentLabel.rightAnchor.constraint(equalTo: textBackView.rightAnchor, constant: -12),
      contentLabel.topAnchor.constraint(equalTo: textBackView.topAnchor, constant: 7),
      contentLabel.bottomAnchor.constraint(equalTo: textBackView.bottomAnchor, constant: -7),
    ])
    if sessionName.count > 0 {
      contentLabel.text = "[\(forwardType)]\(sessionName)\(chatLocalizable("session_record"))"
    } else if senderName.count > 0 {
      contentLabel.text = "[\(forwardType)]\(senderName)\(chatLocalizable("collection_message"))"
    }

    // 留言
    contentView.addSubview(commentTextFeild)
    NSLayoutConstraint.activate([
      commentTextFeild.leftAnchor.constraint(equalTo: textBackView.leftAnchor),
      commentTextFeild.rightAnchor.constraint(equalTo: textBackView.rightAnchor),
      commentTextFeild.topAnchor.constraint(equalTo: textBackView.bottomAnchor, constant: 16),
      commentTextFeild.heightAnchor.constraint(equalToConstant: 32),
    ])

    // 水平分隔线
    let verticalLine = UIView()
    verticalLine.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(verticalLine)
    verticalLine.backgroundColor = forwardLineColor
    NSLayoutConstraint.activate([
      verticalLine.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      verticalLine.widthAnchor.constraint(equalToConstant: 1.0),
      verticalLine.heightAnchor.constraint(equalToConstant: 51),
      verticalLine.topAnchor.constraint(equalTo: commentTextFeild.bottomAnchor, constant: 24.0),
    ])

    // 竖直分隔线
    let horizontalLine = UIView()
    horizontalLine.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(horizontalLine)
    horizontalLine.backgroundColor = forwardLineColor
    NSLayoutConstraint.activate([
      horizontalLine.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      horizontalLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      horizontalLine.heightAnchor.constraint(equalToConstant: 1),
      horizontalLine.bottomAnchor.constraint(equalTo: verticalLine.topAnchor),
    ])

    // 取消按钮
    let canceButton = UIButton()
    canceButton.translatesAutoresizingMaskIntoConstraints = false
    canceButton.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    canceButton.setTitle(chatLocalizable("cancel"), for: .normal)
    canceButton.setTitleColor(.ne_greyText, for: .normal)
    canceButton.accessibilityIdentifier = "id.forwardCancelBtn"

    contentView.addSubview(canceButton)
    NSLayoutConstraint.activate([
      canceButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      canceButton.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      canceButton.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      canceButton.rightAnchor.constraint(equalTo: verticalLine.leftAnchor),
    ])

    // 确定按钮
    contentView.addSubview(sureButton)
    NSLayoutConstraint.activate([
      sureButton.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      sureButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      sureButton.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      sureButton.leftAnchor.constraint(equalTo: verticalLine.rightAnchor),
    ])
  }

  //    MARK: 键盘通知相关操作

  open func keyBoardWillShow(_ notification: Notification) {
    contentViewCenterYAnchor?.constant = -60

    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
  }

  open func keyBoardWillHide(_ notification: Notification) {
    contentViewCenterYAnchor?.constant = 0

    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
  }

  open func setItems(_ items: [ForwardItem]) {
    forwardSessions.append(contentsOf: items)
    if forwardSessions.count == 1 {
      let item = forwardSessions[0]
      oneSessionHeadView.configHeadData(headUrl: item.avatar,
                                        name: item.name ?? "",
                                        uid: item.conversationId ?? "")
      oneSessionNameLabel.text = item.name ?? item.conversationId
      sessionCollectionView.isHidden = true
    } else {
      oneSessionHeadView.isHidden = true
      oneSessionNameLabel.isHidden = true
    }
  }

  func sureClick() {
    // 更新最近转发列表
    let recentForwardIdList = forwardSessions.map { $0.conversationId ?? "" }
    settingRepo.updateRecentForward(recentForwardIdList)

    if let block = sureBlock {
      block(commentTextFeild.text)
    }
    removeSelf()
  }

  func cancelClick() {
    if let block = cancelBlock {
      block(commentTextFeild.text)
    }
    removeSelf()
  }

  override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }

  func removeSelf() {
    if let parent = parent as? ChatViewController {
      parent.isCurrentPage = true
    }
    view.removeFromSuperview()
    removeFromParent()
  }

  // MARK: - UICollectionViewDelegate

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    forwardSessions.count
  }

  open func setCellModel(cell: NEBaseForwardSessionCell, indexPath: IndexPath) -> UICollectionViewCell {
    let item = forwardSessions[indexPath.row]
    cell.sessionHeaderView.configHeadData(headUrl: item.avatar, name: item.name ?? "", uid: item.conversationId ?? "")
    return cell
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 32.0, height: 32)
  }
}

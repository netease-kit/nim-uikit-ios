
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class ForwardItem: NSObject {
  var name: String?
  var uid: String?
  var avatar: String?
  override public init() {}
}

@objcMembers
open class NEBaseForwardUserCell: UICollectionViewCell {
  public lazy var userHeaderView: NEUserHeaderView = {
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
    contentView.addSubview(userHeaderView)
    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeaderView.widthAnchor.constraint(equalToConstant: 32.0),
      userHeaderView.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}

@objcMembers
open class NEBaseForwardAlertViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {
  var datas = [ForwardItem]()

  typealias ForwardCallBack = (String?) -> Void
  var cancelBlock: ForwardCallBack?
  var sureBlock: ForwardCallBack?
  var type = chatLocalizable("operation_forward") // 合并转发/逐条转发/转发
  var context = ""

  public let sureButton = UIButton()
  public let tipLabel = UILabel()
  public var contentViewCenterYAnchor: NSLayoutConstraint?

  public lazy var userCollectionView: UICollectionView = {
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

  public lazy var contentView: UIView = {
    let backView = UIView()
    backView.backgroundColor = .white
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    return backView
  }()

  public lazy var oneUserHeadView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.clipsToBounds = true
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.accessibilityIdentifier = "id.forwardHeaderView"
    return headerView
  }()

  public lazy var oneUserNameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textColor = .ne_darkText
    nameLabel.font = NEConstant.defaultTextFont(14.0)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    return nameLabel
  }()

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

  // 留言
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
    view.addSubview(contentView)
    contentViewCenterYAnchor = contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    contentViewCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.widthAnchor.constraint(equalToConstant: 276),
      contentView.heightAnchor.constraint(equalToConstant: 250),
    ])

    tipLabel.translatesAutoresizingMaskIntoConstraints = false
    tipLabel.font = NEConstant.defaultTextFont(16.0)
    tipLabel.textColor = .ne_darkText
    tipLabel.text = chatLocalizable("send_to")
    tipLabel.accessibilityIdentifier = "id.forwardTitle"
    contentView.addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      tipLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      tipLabel.heightAnchor.constraint(equalToConstant: 18.0),
    ])

    contentView.addSubview(oneUserHeadView)
    NSLayoutConstraint.activate([
      oneUserHeadView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      oneUserHeadView.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 16),
      oneUserHeadView.widthAnchor.constraint(equalToConstant: 32.0),
      oneUserHeadView.heightAnchor.constraint(equalToConstant: 32.0),
    ])

    contentView.addSubview(oneUserNameLabel)
    NSLayoutConstraint.activate([
      oneUserNameLabel.leftAnchor.constraint(equalTo: oneUserHeadView.rightAnchor, constant: 8.0),
      oneUserNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      oneUserNameLabel.centerYAnchor.constraint(equalTo: oneUserHeadView.centerYAnchor),
    ])

    contentView.addSubview(userCollectionView)
    NSLayoutConstraint.activate([
      userCollectionView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      userCollectionView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -16.0
      ),
      userCollectionView.heightAnchor.constraint(equalToConstant: 32.0),
      userCollectionView.topAnchor.constraint(equalTo: oneUserHeadView.topAnchor),
    ])

    let textBackView = UIView()
    textBackView.translatesAutoresizingMaskIntoConstraints = false
    textBackView.backgroundColor = NEConstant.hexRGB(0xF2F4F5)
    textBackView.clipsToBounds = true
    textBackView.layer.cornerRadius = 4.0
    contentView.addSubview(textBackView)
    NSLayoutConstraint.activate([
      textBackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      textBackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      textBackView.topAnchor.constraint(equalTo: oneUserHeadView.bottomAnchor, constant: 12.0),
    ])

    textBackView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: textBackView.leftAnchor, constant: 12),
      contentLabel.rightAnchor.constraint(equalTo: textBackView.rightAnchor, constant: -12),
      contentLabel.topAnchor.constraint(equalTo: textBackView.topAnchor, constant: 7),
      contentLabel.bottomAnchor.constraint(equalTo: textBackView.bottomAnchor, constant: -7),
    ])
    contentLabel.text = "[\(type)]\(context)的会话记录"

    // 留言
    contentView.addSubview(commentTextFeild)
    NSLayoutConstraint.activate([
      commentTextFeild.leftAnchor.constraint(equalTo: textBackView.leftAnchor),
      commentTextFeild.rightAnchor.constraint(equalTo: textBackView.rightAnchor),
      commentTextFeild.topAnchor.constraint(equalTo: textBackView.bottomAnchor, constant: 16),
      commentTextFeild.heightAnchor.constraint(equalToConstant: 32),
    ])

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

    let canceButton = UIButton()
    canceButton.translatesAutoresizingMaskIntoConstraints = false
    canceButton.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    canceButton.setTitle(chatLocalizable("cancel"), for: .normal)
    canceButton.setTitleColor(.ne_greyText, for: .normal)
    canceButton.accessibilityIdentifier = "id.forwardCancelBtn"

    sureButton.translatesAutoresizingMaskIntoConstraints = false
    sureButton.addTarget(self, action: #selector(sureClick), for: .touchUpInside)
    sureButton.setTitle(chatLocalizable("send"), for: .normal)
    sureButton.setTitleColor(.ne_blueText, for: .normal)
    sureButton.accessibilityIdentifier = "id.forwardSendBtn"

    contentView.addSubview(canceButton)
    NSLayoutConstraint.activate([
      canceButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      canceButton.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      canceButton.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      canceButton.rightAnchor.constraint(equalTo: verticalLine.leftAnchor),
    ])

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
    datas.append(contentsOf: items)
    if datas.count == 1 {
      let item = datas[0]
      if let name = item.name {
        oneUserHeadView.setTitle(name)
        oneUserNameLabel.text = name
      } else if let uid = item.uid {
        oneUserHeadView.setTitle(uid)
        oneUserNameLabel.text = uid
      }
      if let url = item.avatar, !url.isEmpty {
        oneUserHeadView.sd_setImage(with: URL(string: url), completed: nil)
        oneUserHeadView.titleLabel.text = ""
        oneUserHeadView.backgroundColor = .clear
      } else {
        oneUserHeadView.backgroundColor = UIColor.colorWithString(string: item.uid)
        oneUserHeadView.image = nil
      }
      userCollectionView.isHidden = true
    } else {
      oneUserHeadView.isHidden = true
      oneUserNameLabel.isHidden = true
    }
  }

  func sureClick() {
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

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    datas.count
  }

  open func setCellModel(cell: NEBaseForwardUserCell, indexPath: IndexPath) -> UICollectionViewCell {
    let item = datas[indexPath.row]
    if let url = item.avatar, !url.isEmpty {
      cell.userHeaderView.sd_setImage(with: URL(string: url), completed: nil)
      cell.userHeaderView.titleLabel.text = ""
      cell.userHeaderView.backgroundColor = .clear
    } else {
      cell.userHeaderView.backgroundColor = UIColor.colorWithString(string: item.uid)
      cell.userHeaderView.image = nil
      if let name = item.name {
        cell.userHeaderView.setTitle(name)
      } else if let uid = item.uid {
        cell.userHeaderView.setTitle(uid)
      }
    }
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

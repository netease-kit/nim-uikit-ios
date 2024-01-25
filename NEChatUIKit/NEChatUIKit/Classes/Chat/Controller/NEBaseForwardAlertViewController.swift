
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
  lazy var userHeader: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.titleLabel.font = NEConstant.defaultTextFont(11.0)
    header.clipsToBounds = true
    header.accessibilityIdentifier = "id.forwardHeaderView"
    return header
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(userHeader)
    NSLayoutConstraint.activate([
      userHeader.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeader.widthAnchor.constraint(equalToConstant: 32.0),
      userHeader.heightAnchor.constraint(equalToConstant: 32.0),
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

  public let sureBtn = UIButton()
  public let tip = UILabel()
  public var contentViewCenterYAnchor: NSLayoutConstraint?

  lazy var userCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .horizontal
    flow.minimumLineSpacing = 9.5
    flow.minimumInteritemSpacing = 9.5
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    return collection
  }()

  lazy var contentView: UIView = {
    let back = UIView()
    back.backgroundColor = .white
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 8.0
    return back
  }()

  lazy var oneUserHead: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    header.accessibilityIdentifier = "id.forwardHeaderView"
    return header
  }()

  lazy var oneUserName: UILabel = {
    let name = UILabel()
    name.textColor = .ne_darkText
    name.font = NEConstant.defaultTextFont(14.0)
    name.translatesAutoresizingMaskIntoConstraints = false
    return name
  }()

  lazy var contentText: UILabel = {
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
  lazy var commentTextFeild: UITextField = {
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
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentViewCenterYAnchor!,
      contentView.widthAnchor.constraint(equalToConstant: 276),
      contentView.heightAnchor.constraint(equalToConstant: 250),
    ])

    tip.translatesAutoresizingMaskIntoConstraints = false
    tip.font = NEConstant.defaultTextFont(16.0)
    tip.textColor = .ne_darkText
    tip.text = chatLocalizable("send_to")
    tip.accessibilityIdentifier = "id.forwardTitle"
    contentView.addSubview(tip)
    NSLayoutConstraint.activate([
      tip.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      tip.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      tip.heightAnchor.constraint(equalToConstant: 18.0),
    ])

    contentView.addSubview(oneUserHead)
    NSLayoutConstraint.activate([
      oneUserHead.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      oneUserHead.topAnchor.constraint(equalTo: tip.bottomAnchor, constant: 16),
      oneUserHead.widthAnchor.constraint(equalToConstant: 32.0),
      oneUserHead.heightAnchor.constraint(equalToConstant: 32.0),
    ])

    contentView.addSubview(oneUserName)
    NSLayoutConstraint.activate([
      oneUserName.leftAnchor.constraint(equalTo: oneUserHead.rightAnchor, constant: 8.0),
      oneUserName.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      oneUserName.centerYAnchor.constraint(equalTo: oneUserHead.centerYAnchor),
    ])

    contentView.addSubview(userCollection)
    NSLayoutConstraint.activate([
      userCollection.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      userCollection.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -16.0
      ),
      userCollection.heightAnchor.constraint(equalToConstant: 32.0),
      userCollection.topAnchor.constraint(equalTo: oneUserHead.topAnchor),
    ])

    let textBack = UIView()
    textBack.translatesAutoresizingMaskIntoConstraints = false
    textBack.backgroundColor = NEConstant.hexRGB(0xF2F4F5)
    textBack.clipsToBounds = true
    textBack.layer.cornerRadius = 4.0
    contentView.addSubview(textBack)
    NSLayoutConstraint.activate([
      textBack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      textBack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      textBack.topAnchor.constraint(equalTo: oneUserHead.bottomAnchor, constant: 12.0),
    ])

    textBack.addSubview(contentText)
    NSLayoutConstraint.activate([
      contentText.leftAnchor.constraint(equalTo: textBack.leftAnchor, constant: 12),
      contentText.rightAnchor.constraint(equalTo: textBack.rightAnchor, constant: -12),
      contentText.topAnchor.constraint(equalTo: textBack.topAnchor, constant: 7),
      contentText.bottomAnchor.constraint(equalTo: textBack.bottomAnchor, constant: -7),
    ])
    contentText.text = "[\(type)]\(context)的会话记录"

    // 留言
    contentView.addSubview(commentTextFeild)
    NSLayoutConstraint.activate([
      commentTextFeild.leftAnchor.constraint(equalTo: textBack.leftAnchor),
      commentTextFeild.rightAnchor.constraint(equalTo: textBack.rightAnchor),
      commentTextFeild.topAnchor.constraint(equalTo: textBack.bottomAnchor, constant: 16),
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

    let canceBtn = UIButton()
    canceBtn.translatesAutoresizingMaskIntoConstraints = false
    canceBtn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    canceBtn.setTitle(chatLocalizable("cancel"), for: .normal)
    canceBtn.setTitleColor(.ne_greyText, for: .normal)
    canceBtn.accessibilityIdentifier = "id.forwardCancelBtn"

    sureBtn.translatesAutoresizingMaskIntoConstraints = false
    sureBtn.addTarget(self, action: #selector(sureClick), for: .touchUpInside)
    sureBtn.setTitle(chatLocalizable("send"), for: .normal)
    sureBtn.setTitleColor(.ne_blueText, for: .normal)
    sureBtn.accessibilityIdentifier = "id.forwardSendBtn"

    contentView.addSubview(canceBtn)
    NSLayoutConstraint.activate([
      canceBtn.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      canceBtn.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      canceBtn.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      canceBtn.rightAnchor.constraint(equalTo: verticalLine.leftAnchor),
    ])

    contentView.addSubview(sureBtn)
    NSLayoutConstraint.activate([
      sureBtn.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      sureBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      sureBtn.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      sureBtn.leftAnchor.constraint(equalTo: verticalLine.rightAnchor),
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
        oneUserHead.setTitle(name)
        oneUserName.text = name
      } else if let uid = item.uid {
        oneUserHead.setTitle(uid)
        oneUserName.text = uid
      }
      if let url = item.avatar, !url.isEmpty {
        oneUserHead.sd_setImage(with: URL(string: url), completed: nil)
        oneUserHead.titleLabel.text = ""
        oneUserHead.backgroundColor = .clear
      } else {
        oneUserHead.backgroundColor = UIColor.colorWithString(string: item.uid)
        oneUserHead.image = nil
      }
      userCollection.isHidden = true
    } else {
      oneUserHead.isHidden = true
      oneUserName.isHidden = true
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
      cell.userHeader.sd_setImage(with: URL(string: url), completed: nil)
      cell.userHeader.titleLabel.text = ""
      cell.userHeader.backgroundColor = .clear
    } else {
      cell.userHeader.backgroundColor = UIColor.colorWithString(string: item.uid)
      cell.userHeader.image = nil
      if let name = item.name {
        cell.userHeader.setTitle(name)
      } else if let uid = item.uid {
        cell.userHeader.setTitle(uid)
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

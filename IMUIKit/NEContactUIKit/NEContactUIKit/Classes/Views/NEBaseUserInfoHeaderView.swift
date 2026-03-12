
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseUserInfoHeaderView: UIView {
  public var labelConstraints = [NSLayoutConstraint]()

  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(14.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  public lazy var titleLabel: CopyableLabel = {
    let titleLabel = CopyableLabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
    titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    titleLabel.accessibilityIdentifier = "id.name"
    return titleLabel
  }()

  public lazy var detailLabel: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.account"
    return detailLabel
  }()

  public lazy var detailLabel2: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.commentName"
    return detailLabel
  }()

  lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .ne_greyLine
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    backgroundColor = .white
    addSubview(userHeaderView)
    addSubview(titleLabel)
    addSubview(detailLabel)
    addSubview(lineView)

    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      userHeaderView.widthAnchor.constraint(equalToConstant: 60),
      userHeaderView.heightAnchor.constraint(equalToConstant: 60),
      userHeaderView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
    ])

    commonUI(showDetail: false)
  }

  open func commonUI(showDetail: Bool) {
    NSLayoutConstraint.deactivate(labelConstraints)
    var titleConstraint = [NSLayoutConstraint]()
    var detailConstraint = [NSLayoutConstraint]()
    var detail2Constraint = [NSLayoutConstraint]()
    if showDetail {
      titleConstraint = [
        titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 20),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -35),
        titleLabel.topAnchor.constraint(equalTo: userHeaderView.topAnchor, constant: -2),
        titleLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      addSubview(detailLabel2)
      detail2Constraint = [
        detailLabel2.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel2.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel2.topAnchor.constraint(equalTo: detailLabel.bottomAnchor),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]
    } else {
      titleConstraint = [
        titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
        titleLabel.topAnchor.constraint(equalTo: userHeaderView.topAnchor, constant: 7),
        titleLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      detailLabel2.removeFromSuperview()
      detail2Constraint = []
    }
    labelConstraints = titleConstraint + detailConstraint + detail2Constraint
    NSLayoutConstraint.activate(labelConstraints)
    updateConstraintsIfNeeded()
  }

  open func setData(user: NEUserWithFriend?) {
    guard let userFriend = user else {
      return
    }

    // avatar
    let url = userFriend.user?.avatar
    let name = userFriend.shortName() ?? ""
    let accountId = userFriend.user?.accountId ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)

    // title
    let uid = userFriend.user?.accountId ?? ""
    if let alias = userFriend.friend?.alias, !alias.isEmpty {
      commonUI(showDetail: true)
      titleLabel.text = alias
      detailLabel.text = "\(localizable("nick")):\(userFriend.user?.name ?? uid)"
      detailLabel.copyString = userFriend.user?.name ?? uid
      detailLabel2.text = "\(localizable("account")):\(uid)"
      detailLabel2.copyString = uid
    } else {
      commonUI(showDetail: false)
      titleLabel.text = userFriend.showName()
      detailLabel.text = "\(localizable("account")):\(uid)"
      detailLabel.copyString = uid
    }
  }
}

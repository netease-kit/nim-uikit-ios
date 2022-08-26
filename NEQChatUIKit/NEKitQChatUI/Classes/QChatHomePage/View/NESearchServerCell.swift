
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import SDWebImage

class NESearchServerCell: UITableViewCell {
  typealias callBack = (() -> Void)?
  @objc var joinServerCallBack: callBack = nil
  public var serverViewModel = CreateServerViewModel()

  public var serverModel: QChatServer? {
    didSet {
      if let imageUrl = serverModel?.icon {
        headImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
        headImageView.setTitle("")
      } else {
        if let name = serverModel?.name {
          headImageView.setTitle(name)
        }
        headImageView.sd_setImage(with: URL(string: ""), completed: nil)
        headImageView.backgroundColor = .colorWithNumber(number: serverModel?.serverId)
      }

      self.content.text = serverModel?.name

      guard let serverId = serverModel?.serverId else {
        return
      }
      self.subContent.text = "\(serverId)"

      let item = QChatGetServerMemberItem(
        serverId: serverId,
        accid: IMKitLoginManager.instance.imAccid
      )
      let param = QChatGetServerMembersParam(serverAccIds: [item])

      serverViewModel.getServerMemberList(parameter: param) { error, membersResult in
        if error == nil {
          guard let dataArray = membersResult?.memberArray else { return }
          if dataArray.isEmpty {
            self.rightContent.isHidden = true
            self.joinBtn.isHidden = false
          } else {
            self.rightContent.isHidden = false
            self.joinBtn.isHidden = true
          }
        } else {
          print("getServerMemberList failed,error = \(error!)")
        }
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    serviceBgView.addCorner(conrners: .allCorners, radius: 8)
    headImageView.addCorner(conrners: .allCorners, radius: 18)
  }

  func setupSubviews() {
    contentView.addSubview(serviceBgView)
    serviceBgView.addSubview(headImageView)
    serviceBgView.addSubview(content)
    serviceBgView.addSubview(subContent)
    serviceBgView.addSubview(rightContent)
    serviceBgView.addSubview(rightContentImageView)
    serviceBgView.addSubview(joinBtn)

    NSLayoutConstraint.activate([
      serviceBgView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: kScreenInterval
      ),
      serviceBgView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -kScreenInterval
      ),
      serviceBgView.topAnchor.constraint(equalTo: contentView.topAnchor),
      serviceBgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
    ])

    NSLayoutConstraint.activate([
      headImageView.leftAnchor.constraint(equalTo: serviceBgView.leftAnchor, constant: 16),
      headImageView.centerYAnchor.constraint(equalTo: serviceBgView.centerYAnchor),
      headImageView.widthAnchor.constraint(equalToConstant: 36),
      headImageView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      subContent.leftAnchor.constraint(equalTo: content.leftAnchor),
      subContent.bottomAnchor.constraint(equalTo: headImageView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      rightContent.centerYAnchor.constraint(equalTo: serviceBgView.centerYAnchor),
      rightContent.rightAnchor.constraint(equalTo: serviceBgView.rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      rightContentImageView.centerYAnchor.constraint(equalTo: rightContent.centerYAnchor),
      rightContentImageView.rightAnchor.constraint(
        equalTo: serviceBgView.rightAnchor,
        constant: 16
      ),
    ])

    NSLayoutConstraint.activate([
      joinBtn.centerYAnchor.constraint(equalTo: serviceBgView.centerYAnchor),
      joinBtn.widthAnchor.constraint(equalToConstant: 56),
      joinBtn.heightAnchor.constraint(equalToConstant: 24),
      joinBtn.rightAnchor.constraint(equalTo: serviceBgView.rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: headImageView.topAnchor),
      content.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 12),
      content.rightAnchor.constraint(equalTo: joinBtn.leftAnchor),
    ])
  }

  // MARK: lazyMethod

  private lazy var serviceBgView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = HexRGB(0xEFF1F4)
    return view
  }()

  lazy var headImageView: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.textColor = .white
    view.titleLabel.font = DefaultTextFont(14)
    view.translatesAutoresizingMaskIntoConstraints = false
//        view.clipsToBounds = true
    return view
  }()

  private lazy var content: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(14)
    label.textColor = TextNormalColor
    return label
  }()

  private lazy var subContent: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(12)
    label.textColor = .ne_blueText
    return label
  }()

  private lazy var rightContent: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("已申请")
    label.font = DefaultTextFont(12)
    label.textColor = UIColor.ne_emptyTitleColor
    label.isHidden = true
    return label
  }()

  private lazy var rightContentImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "addOther_icon"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isHidden = true
    return imageView
  }()

  private lazy var joinBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("加入"), for: .normal)
    button.setTitleColor(UIColor.white, for: .normal)
    button.titleLabel?.font = DefaultTextFont(12)
    button.backgroundColor = HexRGB(0x337EFF)
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(bottomBtnClick), for: .touchUpInside)
    button.isHidden = true
    return button
  }()
}

extension NESearchServerCell {
  @objc func bottomBtnClick(sender: UIButton) {
    guard let serverId = serverModel?.serverId else {
      return
    }
    let param = QChatApplyServerJoinParam(serverId: serverId)

    serverViewModel.applyServerJoin(parameter: param) { [self] error in
      if error == nil {
        self.joinBtn.isHidden = true
        self.rightContent.isHidden = false
        if self.joinServerCallBack != nil {
          joinServerCallBack!()
        }
      } else {
        print("applyServerJoin failed,error = \(error!)")
      }
    }
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore
class NEHomeServerCell: UITableViewCell {
  lazy var redDot: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .ne_redColor
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.layer.borderColor = UIColor.white.cgColor
    view.layer.borderWidth = 1
    view.isHidden = true
    return view
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  public var serverModel: QChatServer? {
    didSet {
      if let imageUrl = serverModel?.icon {
        headView.sd_setImage(with: URL(string: imageUrl), completed: nil)
        headView.setTitle("")
      } else {
        if let name = serverModel?.name {
          headView.setTitle(name)
        }
        headView.sd_setImage(with: URL(string: ""), completed: nil)
        headView.backgroundColor = .colorWithNumber(number: serverModel?.serverId)
      }

      if let hasUnread = serverModel?.hasUnread {
        redDot.isHidden = !hasUnread
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.backgroundColor = HexRGB(0xE9EFF5)
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    contentView.addSubview(leftSelectView)
    contentView.addSubview(headView)

    NSLayoutConstraint.activate([
      headView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      headView.topAnchor.constraint(equalTo: contentView.topAnchor),
      headView.widthAnchor.constraint(equalToConstant: 42),
      headView.heightAnchor.constraint(equalToConstant: 42),
    ])

    NSLayoutConstraint.activate([
      leftSelectView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -4),
      leftSelectView.topAnchor.constraint(equalTo: contentView.topAnchor),
      leftSelectView.widthAnchor.constraint(equalToConstant: 8),
      leftSelectView.heightAnchor.constraint(equalToConstant: 36),
    ])

    contentView.addSubview(redDot)
    let factor = cos(45 * Double.pi / 180)
    let x = 12 + 21 * factor + 21
    let y = 21 - 21 * factor
    NSLayoutConstraint.activate([
      redDot.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: x),
      redDot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: y),
      redDot.widthAnchor.constraint(equalToConstant: 8),
      redDot.heightAnchor.constraint(equalToConstant: 8),
    ])
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    headView.addCorner(conrners: .allCorners, radius: 21)
  }

  // MARK: lazy method

  private lazy var leftSelectView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = HexRGB(0x337EFF)
    view.layer.cornerRadius = 4
    view.isHidden = true
    return view
  }()

  lazy var headView: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.textColor = .white
    view.titleLabel.font = DefaultTextFont(14)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public func showSelectState(isShow: Bool) {
    leftSelectView.isHidden = isShow ? false : true
  }
}

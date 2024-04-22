
import NIMSDK

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class NEBaseHistoryMessageCell: UITableViewCell {
  /// 搜索文案(用户匹配高亮)
  public var searchText: String?
  /// 高亮颜色
  public var rangeTextColor = UIColor.ne_blueText

  /// 用户头像视图
  public lazy var headView: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 18
    headView.clipsToBounds = true
    return headView
  }()

  /// 用户昵称
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  /// 消息内容
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  /// 分割线
  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  /// 消息时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xCCCCCC)
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(bottomLine)
    contentView.addSubview(timeLabel)
  }

  func configData(message: HistoryMessageModel?) {
    guard let resultText = message?.content else { return }

    guard let searchStr = searchText else { return }

    let attributedStr = NSMutableAttributedString(string: resultText)
    // range 表示从索引几开始取几个字符
    let range = attributedStr.mutableString.range(of: searchStr)
    attributedStr.addAttribute(
      .foregroundColor,
      value: rangeTextColor,
      range: range
    )
    subTitleLabel.attributedText = attributedStr

    if message?.fullName?.count ?? 0 <= 0 {
      message?.fullName = message?.imMessage?.senderId
    }
    titleLabel.text = message?.fullName
    timeLabel.text = message?.time

    if let imageName = message?.avatar, !imageName.isEmpty {
      headView.setTitle("")
      headView.sd_setImage(with: URL(string: imageName), completed: nil)
    } else {
      headView.setTitle(message?.shortName ?? "")
      headView.sd_setImage(with: nil, completed: nil)
      headView.backgroundColor = UIColor.colorWithString(string: message?.imMessage?.senderId)
    }
  }
}

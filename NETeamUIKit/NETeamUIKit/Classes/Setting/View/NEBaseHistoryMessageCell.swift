
import NIMSDK
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit

@objcMembers
open class NEBaseHistoryMessageCell: UITableViewCell {
  public var searchText: String?
  public var rangeTextColor = UIColor.ne_blueText

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headImge)
    contentView.addSubview(title)
    contentView.addSubview(subTitle)
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
    subTitle.attributedText = attributedStr

    title.text = message?.name
    timeLabel.text = message?.time

    if let imageName = message?.avatar, !imageName.isEmpty {
      headImge.setTitle("")
      headImge.sd_setImage(with: URL(string: imageName), completed: nil)
    } else {
      headImge.setTitle(message?.name ?? "")
      headImge.sd_setImage(with: nil, completed: nil)
      headImge.backgroundColor = UIColor.colorWithString(string: message?.imMessage?.from)
    }
  }

  // MARK: lazy Method

  public lazy var headImge: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 18
    headView.clipsToBounds = true
    return headView
  }()

  public lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14)
    label.textAlignment = .left
    return label
  }()

  public lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .left
    return label
  }()

  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xCCCCCC)
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .right
    return label
  }()
}

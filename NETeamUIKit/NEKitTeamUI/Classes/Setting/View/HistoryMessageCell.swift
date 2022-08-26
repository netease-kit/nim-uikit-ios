
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
import UIKit
import NIMSDK

class HistoryMessageCell: UITableViewCell {
  public var searchText: String?

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
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headImge)
    contentView.addSubview(title)
    contentView.addSubview(subTitle)
    contentView.addSubview(bottomLine)
    contentView.addSubview(timeLabel)

    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -5),
      headImge.widthAnchor.constraint(equalToConstant: 36),
      headImge.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      title.topAnchor.constraint(equalTo: headImge.topAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitle.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      subTitle.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.leftAnchor.constraint(equalTo: headImge.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  func configData(message: HistoryMessageModel?) {
    guard let resultText = message?.content else { return }

    guard let searchStr = searchText else { return }

    if let range = resultText.findAllIndex(searchStr).first {
      let attributedStr = NSMutableAttributedString(string: resultText)
      // range必须要加，参数分别表示从索引几开始取几个字符
      attributedStr.addAttribute(
        .foregroundColor,
        value: UIColor.ne_blueText,
        range: range
      )
      subTitle.attributedText = attributedStr
    }

    title.text = message?.name
    timeLabel.text = message?.time

    if let imageName = message?.avatar {
      headImge.setTitle("")
      headImge.sd_setImage(with: URL(string: imageName), completed: nil)
    } else {
      headImge.setTitle(message?.name ?? "")
      headImge.sd_setImage(with: nil, completed: nil)
      headImge.backgroundColor = UIColor.colorWithString(string: message?.imMessage?.from)
    }
  }

  // MARK: lazy Method

  lazy var headImge: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 18
    headView.clipsToBounds = true
    return headView
  }()

  private lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14)
    return label
  }()

  private lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = NEConstant.defaultTextFont(12)
    return label
  }()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xCCCCCC)
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .right
    return label
  }()
}

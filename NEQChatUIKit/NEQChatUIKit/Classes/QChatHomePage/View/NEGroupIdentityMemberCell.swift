
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import MapKit
import NECoreIMKit
class NEGroupIdentityMemberCell: UITableViewCell {
  var dataArray = [String]()

  var maxWidth: CGFloat = kScreenWidth - 2 * kScreenInterval
  var labelMargin: CGFloat = 6
  var labelHeight: CGFloat = 25
  var isFirstRow = true
  var titleTopConstraint: NSLayoutConstraint?

  public var memberModel: ServerMemeber? {
    didSet {
      guard let model = memberModel else { return }

      if let imageName = model.avatar,!imageName.isEmpty {
        avatarImage.sd_setImage(with: URL(string: imageName), completed: nil)
        avatarImage.setTitle("")
      } else {
        if let name = model.nick,!name.isEmpty {
          avatarImage.setTitle(name)
        } else {
          avatarImage.setTitle(model.accid ?? "")
        }
        avatarImage.backgroundColor = .colorWithString(string: memberModel?.accid)
      }
      var labelContentArray = [String]()
      memberModel?.roles?.forEach { roleModel in
        labelContentArray.append(roleModel.name ?? "")
      }
      self.dataArray = labelContentArray
      setupSubviews()

      if let nick = model.nick,!nick.isEmpty {
        titleLable.text = nick
        subTitleLable.text = model.accid
        titleTopConstraint?.constant = 14
      } else {
        titleLable.text = model.accid
        subTitleLable.text = ""
        titleTopConstraint?.constant = 22
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    avatarImage.addCorner(conrners: .allCorners, radius: 18)
  }

  func setupSubviews() {
    contentView.addSubview(avatarImage)
    contentView.addSubview(titleLable)
    contentView.addSubview(subTitleLable)
    contentView.addSubview(arrowImageView)
    contentView.addSubview(labelContainerView)
    contentView.addSubview(lineView)

    NSLayoutConstraint.activate([
      avatarImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      avatarImage.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: kScreenInterval
      ),
      avatarImage.widthAnchor.constraint(equalToConstant: 36),
      avatarImage.heightAnchor.constraint(equalToConstant: 36),
    ])

    titleTopConstraint = titleLable.topAnchor.constraint(
      equalTo: contentView.topAnchor,
      constant: 14
    )
    titleTopConstraint?.isActive = true
    NSLayoutConstraint.activate([
      titleLable.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 12),
    ])

    NSLayoutConstraint.activate([
      subTitleLable.topAnchor.constraint(equalTo: titleLable.bottomAnchor),
      subTitleLable.leftAnchor.constraint(equalTo: titleLable.leftAnchor),
    ])

    NSLayoutConstraint.activate([
      arrowImageView.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
      arrowImageView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -labelHeight
      ),
    ])

    NSLayoutConstraint.activate([
      labelContainerView.topAnchor.constraint(equalTo: avatarImage.bottomAnchor, constant: 8),
      labelContainerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      labelContainerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      labelContainerView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -10
      ),
    ])

    // 移除contentview上复用的lable
    labelContainerView.subviews.forEach { label in
      label.removeFromSuperview()
    }
    var labelsWidth: CGFloat = 0
    for i in 0 ..< dataArray.count {
      let label = IDGroupLable(content: dataArray[i])
      label.textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
      label.translatesAutoresizingMaskIntoConstraints = false
      labelContainerView.addSubview(label)
      let labelSize = label.sizeThatFits(CGSize(width: maxWidth, height: labelHeight))

      // 剩余宽度是否满足，下一个lable的宽度，如不满足则换行
      if (maxWidth - labelsWidth) >= labelSize.width, isFirstRow {
        NSLayoutConstraint.activate([
          i == 0 ? label.leftAnchor.constraint(
            equalTo: labelContainerView.leftAnchor,
            constant: kScreenInterval
          ) : label.leftAnchor.constraint(
            equalTo: labelContainerView.leftAnchor,
            constant: kScreenInterval + labelsWidth
          ),
          label.topAnchor.constraint(equalTo: labelContainerView.topAnchor, constant: 8),
          label.widthAnchor.constraint(equalToConstant: labelSize.width),
          label.heightAnchor.constraint(equalToConstant: labelSize.height),
        ])
      } else {
        // 换行重置，labels总宽度
        if isFirstRow {
          labelsWidth = kScreenInterval
        }
        isFirstRow = false
        NSLayoutConstraint.activate([
          label.leftAnchor.constraint(
            equalTo: labelContainerView.leftAnchor,
            constant: labelsWidth
          ),
          label.topAnchor.constraint(
            equalTo: labelContainerView.topAnchor,
            constant: 8 + labelHeight + labelMargin
          ),
          label.widthAnchor.constraint(equalToConstant: labelSize.width),
          label.heightAnchor.constraint(equalToConstant: labelSize.height),
        ])
      }

      if i == dataArray.count - 1 {
        NSLayoutConstraint.activate([
          label.bottomAnchor.constraint(equalTo: labelContainerView.bottomAnchor),
        ])
      }
      labelsWidth += (labelSize.width + labelMargin)
    }

    NSLayoutConstraint.activate([
      lineView.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: 12),
      lineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      lineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 1),
      lineView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: kScreenInterval
      ),
    ])
  }

  lazy var avatarImage: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.textColor = .white
    view.titleLabel.font = DefaultTextFont(14)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var titleLable: UILabel = {
    let name = UILabel()
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textColor = .ne_darkText
    name.font = DefaultTextFont(14)
    return name
  }()

  private lazy var subTitleLable: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(12)
    label.textColor = UIColor.ne_emptyTitleColor
    return label
  }()

  private lazy var labelContainerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .ne_greyLine
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var arrowImageView: UIImageView = {
    let arrow = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))
    arrow.translatesAutoresizingMaskIntoConstraints = false
    return arrow
  }()
}

class IDGroupLable: UILabel {
  private var content: String?

  init(content: String) {
    super.init(frame: CGRect.zero)
    self.content = content
    setupStyle()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    addCorner(conrners: .allCorners, radius: 4)
  }

  func setupStyle() {
    font = DefaultTextFont(12)
    textColor = HexRGB(0x656A72)
    backgroundColor = HexRGB(0xF2F4F5)
    text = content
  }

  // 定义一个接受间距的属性
  var textInsets = UIEdgeInsets.zero

  // 返回 label 重新计算过 text 的 rectangle
  override func textRect(forBounds bounds: CGRect,
                         limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    guard text != nil else {
      return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
    }

    let insetRect = bounds.inset(by: textInsets)
    let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
    let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                      left: -textInsets.left,
                                      bottom: -textInsets.bottom,
                                      right: -textInsets.right)
    return textRect.inset(by: invertedInsets)
  }

  // 3. 绘制文本时，对当前 rectangle 添加间距
  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: textInsets))
  }
}

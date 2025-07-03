
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
open class NEAIWordSearchTextCell: UITableViewCell {
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonUI()
  }

  /// UI 布局方法
  func commonUI() {
    isUserInteractionEnabled = false
    contentView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])

    contentView.addSubview(bottomLineView)
    NSLayoutConstraint.activate([
      bottomLineView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      bottomLineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLineView.heightAnchor.constraint(equalToConstant: 4),
    ])
  }

  /// 是否显示 cell 底部分隔线
  /// - Parameter show: 是否显示
  func showBottomLine(_ show: Bool) {
    bottomLineView.isHidden = !show
  }

  /// 数据绑定
  /// - Parameter model: 数据模型
  func setModel(_ model: NEAIWordSearchModel) {
    contentLabel.attributedText = model.content
  }

  /// 文本内容
  lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = textFont
    label.textColor = .ne_darkText
    label.numberOfLines = 0
    label.textAlignment = .justified
    label.accessibilityIdentifier = "id.content"

    return label
  }()

  /// 分隔线
  lazy var bottomLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#EDEDED")
    return view
  }()
}

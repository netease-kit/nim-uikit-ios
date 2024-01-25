// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBasePinMessageTextCell: NEBasePinMessageCell {
  lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = true
    label.numberOfLines = 3
    return label
  }()

  public let replyLabel = UILabel()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    commonUI()
  }

  open func commonUI() {
    replyLabel.font = UIFont.systemFont(ofSize: 12)
    replyLabel.textColor = UIColor(hexString: "#929299")
    replyLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(replyLabel)
    NSLayoutConstraint.activate([
      replyLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
      replyLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      replyLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
    ])

    backView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      contentLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      contentLabel.topAnchor.constraint(equalTo: replyLabel.bottomAnchor, constant: 1),
    ])
    if let gesture = contentGesture {
      contentLabel.addGestureRecognizer(gesture)
    }
  }

  override open func configure(_ item: PinMessageModel) {
    super.configure(item)
    if let model = item.chatmodel as? MessageTextModel {
      contentLabel.attributedText = model.attributeStr
      if model.replyedModel?.isReplay == true {
        replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: model.replyText ?? "",
                                                                font: replyLabel.font,
                                                                color: replyLabel.textColor)
      } else {
        replyLabel.attributedText = nil
      }
    }
  }
}

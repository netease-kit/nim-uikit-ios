//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open
class NEBaseCollectionMessageRichTextCell: NEBaseCollectionMessageTextCell {
  /// 换行文本
  public lazy var collectionTitleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = true
    label.numberOfLines = 1
    return label
  }()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// 初始化的生命周期
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  /// 反序列化支持回调
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func setupCustomUI() {
    collectionContentLabel.numberOfLines = 2
    backView.addSubview(collectionContentLabel)
    NSLayoutConstraint.activate([
      collectionContentLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      collectionContentLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      collectionContentLabel.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -12),
    ])

    backView.addSubview(collectionTitleLabel)
    NSLayoutConstraint.activate([
      collectionTitleLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      collectionTitleLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      collectionTitleLabel.bottomAnchor.constraint(equalTo: collectionContentLabel.topAnchor, constant: -1),
    ])

    if let gesture = contentGesture {
      collectionContentLabel.addGestureRecognizer(gesture)
    }

    let titleGesture = UITapGestureRecognizer(target: self, action: #selector(contentClick))
    collectionTitleLabel.addGestureRecognizer(titleGesture)
  }

  override open func setupCommonUI() {
    super.setupCommonUI()
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let m = model.chatmodel as? MessageRichTextModel {
      collectionTitleLabel.attributedText = m.titleAttributeStr
    }
  }
}

//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open
class NEBaseCollectionMessageTextCell: NEBaseCollectionMessageCell, LinkableLabelProtocol {
  /// 内容文本
  public lazy var collectionContentLabel: NELinkableLabel = {
    let label = NELinkableLabel()
    label.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.pinMessageTextSize)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = true
    label.numberOfLines = 3
    label.delegate = self
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  /// 回复文本
  public let replyLabel = UILabel()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// 初始化的生命周期
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  /// 反序列化支持回调
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupCustomUI() {
    backView.addSubview(collectionContentLabel)
    NSLayoutConstraint.activate([
      collectionContentLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      collectionContentLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      collectionContentLabel.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -12),
    ])
  }

  override open func setupCommonUI() {
    super.setupCommonUI()
    setupCustomUI()
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let model = model.chatmodel as? MessageTextModel {
      collectionContentLabel.attributedText = model.attributeStr
      collectionContentLabel.updateLinkDetection()
    }
  }

  // MARK: LinkableLabelProtocol

  public func didTapLink(url: URL?) {
    delegate?.didTapDetectedLink?(collectionModel, self, url)
  }
}

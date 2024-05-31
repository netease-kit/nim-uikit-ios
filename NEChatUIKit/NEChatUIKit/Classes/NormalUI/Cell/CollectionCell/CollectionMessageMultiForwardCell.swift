//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open
class CollectionMessageMultiForwardCell: NEBaseCollectionMessageMultiForwardCell {
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

  override open func setupCommonUI() {
    super.setupCommonUI()
    backImageViewLeft.addSubview(titleLabelLeft1)
    NSLayoutConstraint.activate([
      titleLabelLeft1.leftAnchor.constraint(equalTo: backImageViewLeft.leftAnchor, constant: 16),
      titleLabelLeft1.rightAnchor.constraint(lessThanOrEqualTo: backImageViewLeft.rightAnchor, constant: -84),
      titleLabelLeft1.topAnchor.constraint(equalTo: backImageViewLeft.topAnchor, constant: 10),
      titleLabelLeft1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backImageViewLeft.addSubview(titleLabelLeft2)
    NSLayoutConstraint.activate([
      titleLabelLeft2.leftAnchor.constraint(equalTo: titleLabelLeft1.rightAnchor),
      titleLabelLeft2.centerYAnchor.constraint(equalTo: titleLabelLeft1.centerYAnchor),
      titleLabelLeft2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelLeft2.widthAnchor.constraint(equalToConstant: 74),
    ])

    backImageViewLeft.addSubview(contentLabelLeft1)
    NSLayoutConstraint.activate([
      contentLabelLeft1.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
      contentLabelLeft1.topAnchor.constraint(equalTo: titleLabelLeft1.bottomAnchor, constant: 2),
      contentLabelLeft1.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft1.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backImageViewLeft.addSubview(contentLabelLeft2)
    NSLayoutConstraint.activate([
      contentLabelLeft2.leftAnchor.constraint(equalTo: contentLabelLeft1.leftAnchor),
      contentLabelLeft2.topAnchor.constraint(equalTo: contentLabelLeft1.bottomAnchor),
      contentLabelLeft2.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft2.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backImageViewLeft.addSubview(contentLabelLeft3)
    NSLayoutConstraint.activate([
      contentLabelLeft3.leftAnchor.constraint(equalTo: contentLabelLeft2.leftAnchor),
      contentLabelLeft3.topAnchor.constraint(equalTo: contentLabelLeft2.bottomAnchor),
      contentLabelLeft3.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft3.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])
  }
}

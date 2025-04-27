// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import UIKit

class CustomChatCell: NEChatBaseCell {
  public var testLabel = UILabel()

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .lightGray
    testLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(testLabel)
    NSLayoutConstraint.activate([
      testLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      testLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
    testLabel.font = UIFont.systemFont(ofSize: 14)
    testLabel.textColor = UIColor.black
  }

  override func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    if let model = model as? MessageCustomModel {
      print("this is custom message, customType: \(model.customType)")
      testLabel.text = model.message?.text
    }
  }
}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatRevokeLeftCell: ChatBaseLeftCell {
    public var label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.ne_greyText
        label.font = UIFont.systemFont(ofSize: 16.0)
        self.bubbleImage.addSubview(label)
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: self.bubbleImage.leftAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: self.bubbleImage.topAnchor, constant: 0),
            label.heightAnchor.constraint(equalToConstant: qChat_min_h),
            label.rightAnchor.constraint(equalTo: self.bubbleImage.rightAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 0),
        ])
    }
    
    override func setModel(_ model: MessageContentModel) {
        super.setModel(model)
        label.text = localizable("message_has_be_withdrawn")
    }
}

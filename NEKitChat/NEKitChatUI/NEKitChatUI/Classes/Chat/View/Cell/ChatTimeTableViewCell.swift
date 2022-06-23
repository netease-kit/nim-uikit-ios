
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatTimeTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(timeLable)
        NSLayoutConstraint.activate([
            timeLable.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            timeLable.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            timeLable.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            timeLable.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setModel(_ model: MessageTipsModel) {
        timeLable.text = model.text
    }

    private lazy var timeLable:UILabel = {
        let label = UILabel()
        label.font = DefaultTextFont(12)
        label.textColor = NEKitChatConfig.shared.ui.timeColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
}

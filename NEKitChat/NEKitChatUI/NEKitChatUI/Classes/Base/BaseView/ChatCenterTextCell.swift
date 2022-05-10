
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatCenterTextCell: ChatCornerCell {

    public var titleLabel: UILabel = UILabel()
    public var line = UIView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textColor = .ne_redText
        self.titleLabel.textAlignment = .center
        self.contentView.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 36),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -36),
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
        self.titleLabel.text = "title"
        self.line.backgroundColor = .ne_greyLine
        self.line.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.line)
        NSLayoutConstraint.activate([
            self.line.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.line.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.line.heightAnchor.constraint(equalToConstant: 1.0),
            self.line.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

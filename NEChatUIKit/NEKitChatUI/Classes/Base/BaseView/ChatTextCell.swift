
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatTextCell: ChatStateCell {
    public var titleLabel: UILabel = UILabel()
    public var detailLabel: UILabel = UILabel()
    public var line = UIView()
    
    var titleLeftMargin: NSLayoutConstraint?
    
    var detailRightMargin: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textColor = .ne_darkText
        self.contentView.addSubview(self.titleLabel)
        titleLeftMargin = titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 36)
        titleLeftMargin?.isActive = true
        NSLayoutConstraint.activate([
//            self.titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
        self.titleLabel.text = "删除"
        
        self.detailLabel.font = UIFont.systemFont(ofSize: 16)
        self.detailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.detailLabel.textColor = .ne_lightText
        self.contentView.addSubview(self.detailLabel)
        
        detailRightMargin = detailLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -60)
        detailRightMargin?.isActive = true
        NSLayoutConstraint.activate([
            self.detailLabel.leftAnchor.constraint(equalTo: self.titleLabel.rightAnchor, constant: 0),
            self.detailLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 40),
            self.detailLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
        self.detailLabel.textAlignment = .right
        
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

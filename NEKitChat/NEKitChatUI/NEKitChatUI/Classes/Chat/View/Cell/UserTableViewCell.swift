
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM

class UserTableViewCell: UITableViewCell {
    public var avatarImage = UIImageView()
    public var nameLabel = UILabel()
    public var titleLabel = UILabel()
    public var model: User?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        baseCommonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func baseCommonUI() {
        
        // avatar
        self.selectionStyle = .none
        self.backgroundColor = .white
        self.avatarImage.layer.cornerRadius = 21
        self.avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
        self.avatarImage.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImage.clipsToBounds = true
        self.avatarImage.isUserInteractionEnabled = true
        self.contentView.addSubview(self.avatarImage)
        NSLayoutConstraint.activate([
            self.avatarImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.avatarImage.widthAnchor.constraint(equalToConstant: 42),
            self.avatarImage.heightAnchor.constraint(equalToConstant: 42),
            self.avatarImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 10)
        ])
        
        // name
        self.nameLabel.textAlignment = .center
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = UIFont.systemFont(ofSize: 12)
        self.nameLabel.textColor = .white
        self.nameLabel.text = "placeholder"
        self.contentView.addSubview(self.nameLabel)
        NSLayoutConstraint.activate([
            self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImage.leftAnchor),
            self.nameLabel.rightAnchor.constraint(equalTo: self.avatarImage.rightAnchor),
            self.nameLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            self.nameLabel.bottomAnchor.constraint(equalTo: self.avatarImage.bottomAnchor),
        ])
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.text = "placeholder"
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        self.contentView.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 12),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -35),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
    
    public func setModel(_ model: User) {
        self.model = model
        self.avatarImage.backgroundColor = UIColor.colorWithString(string:model.userId)
        self.nameLabel.text = model.shortName(count: 2)
        self.titleLabel.text = model.showName()
        
        if let avatarURL = model.userInfo?.avatarUrl {
            self.avatarImage.sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
                if image != nil {
                    self?.avatarImage.image = image
                    self?.nameLabel.isHidden = true
                }else {
                    self?.avatarImage.image = nil
                    self?.nameLabel.isHidden = false
                }
            }
        }else {
            self.avatarImage.image = nil
            self.nameLabel.isHidden = false
        }
    }
}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCoreIM
import SDWebImage


class UserInfoHeaderView: UIView {
    public var avatarImage = UIImageView()
    public var nameLabel = UILabel()
    public var titleLabel = UILabel()
    public var detailLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.avatarImage.layer.cornerRadius = 30
        self.avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
        self.avatarImage.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImage.contentMode = .scaleAspectFill
        self.avatarImage.clipsToBounds = true
        self.addSubview(self.avatarImage)
        NSLayoutConstraint.activate([
            self.avatarImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
            self.avatarImage.widthAnchor.constraint(equalToConstant: 60),
            self.avatarImage.heightAnchor.constraint(equalToConstant: 60),
            self.avatarImage.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0)
        ])
        
        self.nameLabel.textAlignment = .center
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = UIFont.systemFont(ofSize: 22)
        self.nameLabel.textColor = .white
        self.addSubview(self.nameLabel)
        NSLayoutConstraint.activate([
            self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImage.leftAnchor),
            self.nameLabel.rightAnchor.constraint(equalTo: self.avatarImage.rightAnchor),
            self.nameLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            self.nameLabel.bottomAnchor.constraint(equalTo: self.avatarImage.bottomAnchor),
        ])
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        self.titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        self.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 20),
            self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -35),
            self.titleLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            self.titleLabel.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        self.detailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.detailLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.detailLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        self.addSubview(self.detailLabel)
        NSLayoutConstraint.activate([
            self.detailLabel.leftAnchor.constraint(equalTo: self.titleLabel.leftAnchor),
            self.detailLabel.rightAnchor.constraint(equalTo: self.titleLabel.rightAnchor),
            self.detailLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor,constant: 8),
            self.detailLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setData(user: User?) {
        guard let user = user else {
            return
        }
        self.avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
        // avatar
        if let imageUrl = user.userInfo?.thumbAvatarUrl {
            self.avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
            self.nameLabel.isHidden = true
        }
        self.detailLabel.text = user.userId
        // title
        var showName = user.alias?.count ?? 0 > 0 ? user.alias : user.userInfo?.nickName
        if showName == nil || showName?.count == 0 {
            showName = user.userId
        }
        if let name = showName {
            self.titleLabel.text = name
            if self.avatarImage.image == nil {
                self.nameLabel.text = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
            }
        }
    }
}

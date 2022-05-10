
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCoreIM

class TeamTableViewCell: UITableViewCell {
    public var avatarImage = UIImageView()
    public var nameLabel = UILabel()
    public var titleLabel = UILabel()
//    public var arrow = UIImageView(image:UIImage.ne_imageNamed(name: "arrowRight"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        self.selectionStyle = .none
        self.avatarImage.backgroundColor = UIColor.colorWithNumber(number: 0)
        self.avatarImage.layer.cornerRadius = 21
        self.avatarImage.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImage.clipsToBounds = true
        self.contentView.addSubview(self.avatarImage)
        NSLayoutConstraint.activate([
            self.avatarImage.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.avatarImage.widthAnchor.constraint(equalToConstant: 42),
            self.avatarImage.heightAnchor.constraint(equalToConstant: 42),
            self.avatarImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0)
        ])
        
        self.nameLabel.textAlignment = .center
        self.nameLabel.font = UIFont.systemFont(ofSize: 16)
        self.nameLabel.textColor = .white
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.nameLabel)
        NSLayoutConstraint.activate([
            self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImage.leftAnchor),
            self.nameLabel.rightAnchor.constraint(equalTo: self.avatarImage.rightAnchor),
            self.nameLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            self.nameLabel.bottomAnchor.constraint(equalTo: self.avatarImage.bottomAnchor),
        ])
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        self.contentView.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 12),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -35),
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        
//        self.arrow.translatesAutoresizingMaskIntoConstraints = false
//        self.arrow.isHidden = true
//        self.arrow.contentMode = .center
//        self.contentView.addSubview(self.arrow)
//        NSLayoutConstraint.activate([
//            self.arrow.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
//            self.arrow.widthAnchor.constraint(equalToConstant: 15),
//            self.arrow.topAnchor.constraint(equalTo: self.contentView.topAnchor),
//            self.arrow.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
//        ])
        
    }
    public func setModel(_ model: Any) {
        guard let team = model as? Team else {
            return
        }
        guard let name = team.teamName else {
            return
        }
        self.titleLabel.text = name
//        self.nameLabel.text = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
        if let url = team.thumbAvatarUrl {
            self.avatarImage.sd_setImage(with:  URL(string: url), completed: nil)
        }else {
            // random avatar
            self.avatarImage.image = randomAvatar(teamId: team.teamId)
        }
    }
    
    private func randomAvatar(teamId: String?) -> UIImage? {
        guard let tid = teamId else {
            return nil
        }
        // mod: 0 1 2 3 4
        let mod = Int(tid) ?? 0 % 5
        let name = "icon_" + String(mod)
        return UIImage.ne_imageNamed(name: name)
    }
    
}

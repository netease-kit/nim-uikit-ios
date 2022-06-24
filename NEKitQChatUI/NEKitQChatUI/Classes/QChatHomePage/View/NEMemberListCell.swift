
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class NEMemberListCell: UITableViewCell{

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        self.contentView.addSubview(avatarImage)
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(arrowImage)
        self.contentView.addSubview(lineView)


        NSLayoutConstraint.activate([
            avatarImage.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: kScreenInterval),
            avatarImage.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -12),
            avatarImage.widthAnchor.constraint(equalToConstant: 36),
            avatarImage.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        
        NSLayoutConstraint.activate([
            self.lineView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.lineView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.lineView.heightAnchor.constraint(equalToConstant: 1.0),
            self.lineView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])


        NSLayoutConstraint.activate([
            self.arrowImage.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -32),
            self.arrowImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        ])
    }
    
    private lazy var avatarImage: UIImageView = {
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.backgroundColor = .ne_defautAvatarColor
        return avatar
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = TextNormalColor
        label.font = DefaultTextFont(14)
        return label
    }()
    
    private lazy var lineView: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = .ne_greyLine
        return line
    }()
    
    private lazy var arrowImage: UIImageView = {
        let arrow = UIImageView()
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.image = UIImage.ne_imageNamed(name: "")
        return arrow
    }()
}

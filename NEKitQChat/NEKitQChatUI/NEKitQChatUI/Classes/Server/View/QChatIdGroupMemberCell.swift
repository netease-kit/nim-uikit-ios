
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class QChatIdGroupMemberCell: QChatCornerCell {
    
    lazy var headView: NEUserHeaderView = {
        let view = NEUserHeaderView(frame: .zero)
        view.titleLabel.textColor = .white
        view.titleLabel.font = DefaultTextFont(11)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 16.0
        return view
    }()
    
    lazy var tailorImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage.ne_imageNamed(name: "delete")
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .ne_darkText
        label.font = DefaultTextFont(14)
        return label
    }()
    
    var user: UserInfo? {
        didSet {
            if let name = user?.nickName {
                headView.setTitle(name)
            }
            headView.backgroundColor = user?.color
            nameLabel.text = user?.nickName
        }
    }
    
    var leftSpace: NSLayoutConstraint?
    
    var rightSpace: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        contentView.addSubview(headView)
        
        leftSpace = headView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36)
        leftSpace?.isActive = true
        NSLayoutConstraint.activate([
            headView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            headView.widthAnchor.constraint(equalToConstant: 32),
            headView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        contentView.addSubview(tailorImage)
        rightSpace = tailorImage.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36)
        rightSpace?.isActive = true
        NSLayoutConstraint.activate([
            tailorImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tailorImage.widthAnchor.constraint(equalToConstant: 16.0),
            tailorImage.heightAnchor.constraint(equalToConstant: 16.0)
        ])
        
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
            nameLabel.rightAnchor.constraint(equalTo: tailorImage.leftAnchor, constant: -10),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

}

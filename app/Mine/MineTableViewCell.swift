
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit


public class MineTableViewCell: UITableViewCell {

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpSubViews()
    }
    
    func setUpSubViews(){

        self.selectionStyle = .none
        self.contentView.addSubview(avatarImage)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(bottomLine)
        self.contentView.addSubview(arrow)

        NSLayoutConstraint.activate([
            avatarImage.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            avatarImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            avatarImage.widthAnchor.constraint(equalToConstant: 20),
            avatarImage.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
        ])
        
        NSLayoutConstraint.activate([
            bottomLine.leftAnchor.constraint(equalTo: self.contentView.leftAnchor,constant: 20),
            bottomLine.rightAnchor.constraint(equalTo: self.rightAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        NSLayoutConstraint.activate([
            arrow.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -25),
//            arrow.widthAnchor.constraint(equalToConstant: 15),
            arrow.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        ])
    }

    func configCell(data:[String:String]) {
        titleLabel.text = data.keys.first
        if let imageName = data.values.first {
            avatarImage.image = UIImage.init(named: imageName)
        }
    }
    
    //MARK: lazy Method
    public lazy var avatarImage: UIImageView = {
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()
    
    public lazy var titleLabel: UILabel = {
        let name = UILabel()
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textColor = UIColor.ne_darkText
        name.font = UIFont.systemFont(ofSize: 16.0)
        name.text = "设置"
        return name
    }()
    
    private lazy var bottomLine:UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.init(hexString: "0xDBE0E8")
        return view
    }()
    
    public lazy var arrow: UIImageView = {
        let imageView = UIImageView(image:UIImage.init(named: "arrow_right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
}

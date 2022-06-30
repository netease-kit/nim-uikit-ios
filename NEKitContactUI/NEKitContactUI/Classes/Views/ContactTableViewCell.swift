
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCoreIM
import Foundation
import NEKitCore


public class ContactTableViewCell: ContactBaseViewCell, ContactCellDataProtrol {
    
    
    
    public lazy var arrow: UIImageView = {
        let imageView = UIImageView(image:UIImage.ne_imageNamed(name: "arrowRight"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        return imageView
    }()
    
    lazy var redAngleView: RedAngleLabel = {
        let label = RedAngleLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = .white
        label.text = "1"
        label.backgroundColor = UIColor(hexString: "F24957")
        label.textInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonUI()
        initSubviewsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        
        //circle avatar head image with name suffix string
        setupCommonCircleHeader()
        
        self.contentView.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 12),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -35),
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        
        self.contentView.addSubview(self.arrow)
        NSLayoutConstraint.activate([
            self.arrow.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.arrow.widthAnchor.constraint(equalToConstant: 15),
            self.arrow.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.arrow.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        
        contentView.addSubview(redAngleView)
        NSLayoutConstraint.activate([
            redAngleView.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
            redAngleView.rightAnchor.constraint(equalTo: arrow.leftAnchor, constant: -10)
        ])
    }
    
    func initSubviewsLayout(){
        if NEKitContactConfig.shared.ui.avatarType == .rectangle {
            avatarImage.layer.cornerRadius = NEKitContactConfig.shared.ui.avatarCornerRadius
        }else if NEKitContactConfig.shared.ui.avatarType == .cycle {
            avatarImage.layer.cornerRadius = 18.0
        }
    }
    
    
    
    func setConfig(){
        self.titleLabel.font = NEKitContactConfig.shared.ui.titleFont
        self.titleLabel.textColor = NEKitContactConfig.shared.ui.titleColor
        self.nameLabel.font =  UIFont.systemFont(ofSize: 14.0)
        self.nameLabel.textColor = UIColor.white
    }
    
    public func setModel(_ model: ContactInfo) {
        guard let user = model.user else {
            return
        }
        setConfig()
        
        if model.contactCellType == 2 {
            // person
            self.titleLabel.text = user.showName()
            self.nameLabel.text = user.shortName(count: 2)

//            self.nameLabel.backgroundColor = UIColor(hexString: user.userId!)
            if let imageUrl = user.userInfo?.avatarUrl  {
                self.nameLabel.isHidden = true
                self.avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
            }else {
                self.nameLabel.isHidden =  false
                self.avatarImage.image = nil
            }
            self.arrow.isHidden = true
            
        }else {
            self.nameLabel.text = ""
            self.titleLabel.text = user.alias
            self.avatarImage.image = UIImage.ne_imageNamed(name: user.imageName)
            self.avatarImage.backgroundColor = model.headerBackColor
            self.arrow.isHidden = false
        }
    }
}

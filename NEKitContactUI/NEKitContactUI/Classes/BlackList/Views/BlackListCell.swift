
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCoreIM

protocol TeamTableViewCellDelegate: AnyObject {
    
    func removeUser(account: String?, index: Int)
}

class BlackListCell: TeamTableViewCell {
    weak var delegate: TeamTableViewCellDelegate?
    var index = 0
    private var model: User?
    var button = UIButton()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonUI() {
        super.commonUI()
        
        self.button.layer.borderWidth = 1
        self.button.layer.borderColor = UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1).cgColor
        self.button.layer.cornerRadius = 4
        self.button.setTitleColor(UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1), for: .normal)
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.contentMode = .center
        self.button.clipsToBounds = true
        self.button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
        self.button.setTitle(localizable("remove_black"), for: .normal)
        self.contentView.addSubview(self.button)
        NSLayoutConstraint.activate([
            self.button.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.button.widthAnchor.constraint(equalToConstant: 60),
            self.button.heightAnchor.constraint(equalToConstant: 32),
            self.button.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0)
        ])
        
        contentView.addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    @objc func buttonEvent(sender: UIButton) {
        delegate?.removeUser(account: self.model?.userId, index: self.index)
    }
    
    public override func setModel(_ model: Any) {
        guard let user = model as? User else {
            return
        }
        self.model = user
        self.avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
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
        // avatar
        if let imageUrl = user.userInfo?.thumbAvatarUrl {
            self.nameLabel.text = ""
            self.avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
        }
        
    }
    
    
    private lazy var bottomLine:UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.ne_greyLine
        return view
    }()

}

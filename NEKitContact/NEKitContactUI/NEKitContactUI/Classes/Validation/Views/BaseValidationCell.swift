
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM

class BaseValidationCell: ContactBaseViewCell {
    
    public var titleLabelRightMargin: NSLayoutConstraint?



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
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        setupCommonCircleHeader()
        
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo:avatarImage.rightAnchor , constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
        ])
        titleLabelRightMargin = titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10)
        titleLabelRightMargin?.isActive = true
        
        
        let line = UIView()
        addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            line.heightAnchor.constraint(equalToConstant: 1),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        line.backgroundColor = UIColor(hexString: "#F5F8FC")
        
    }
    
   public func confige(_ model: XNotification){
        
        if let id = model.sourceID {
            showNameOnCircleHeader(id)
        }
        
        if let name = model.sourceName {
            showNameOnCircleHeader(name)
        }
        
        var titleLabelContent = ""
        var nickName = ""
        var teamName = ""
        if let nick = model.sourceName {
            nickName = nick
        }
        if let t = model.targetName {
            teamName = t
        }
        if let type = model.type {
            switch type {
            case .teamApply:
                titleLabelContent = "\(nickName) 申请入群"
                break
            case .teamApplyReject:
                titleLabelContent = "\(nickName) 拒绝入群"
                break
            case .teamInvite:
                titleLabelContent = "\(nickName) 邀请你加入 \(teamName)"
                break
            case .teamInviteReject:
                titleLabelContent = "\(nickName) 拒绝入群邀请"
              
                break
            case .superTeamApply:
                titleLabelContent = "\(nickName) 申请加入超大群"
                break
            case .superTeamApplyReject:
                titleLabelContent = "\(nickName) 拒绝加入超大群"
              
                break
            case .superTeamInvite:
                titleLabelContent = "\(nickName) 邀请加入 \(teamName) 群"
                break
            case .superTeamInviteReject:
                titleLabelContent = "\(nickName) 拒绝加入 \(teamName) 群"
                break
            case .addFriendDirectly:
                titleLabelContent = "\(nickName) 添加你为好友"
                break
            case .addFriendRequest:
                titleLabelContent = "\(nickName) 好友申请"
                break
            case .addFriendVerify:
                titleLabelContent = "\(nickName) 通过好友申请"
                break
            case .addFriendReject:
                titleLabelContent = "\(nickName) 拒绝好友申请"
                break
            }
        }
        
        titleLabel.text = titleLabelContent
        
    }

}

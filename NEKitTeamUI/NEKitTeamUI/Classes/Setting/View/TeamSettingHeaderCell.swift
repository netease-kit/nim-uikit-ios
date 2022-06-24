
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCommonUI

public class TeamSettingHeaderCell: BaseTeamSettingCell {
    
    lazy var headerView: NEUserHeaderView = {
        let header = NEUserHeaderView(frame: .zero)
        header.translatesAutoresizingMaskIntoConstraints = false
        header.clipsToBounds = true
        header.layer.cornerRadius = 21.0
        return header
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    public override func configure(_ anyModel: Any) {
        super.configure(anyModel)
        if let url = model?.headerUrl {
            headerView.sd_setImage(with: URL(string: url), completed: nil)
            headerView.setTitle("")
        }else {
            headerView.setTitle(model?.defaultHeadData ?? "")
            headerView.backgroundColor = UIColor.colorWithString(string: model?.defaultHeadData)
        }
    }
    
    func setupUI(){
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84)
        ])
        
        contentView.addSubview(arrow)
        NSLayoutConstraint.activate([
            arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36)
        ])
        
        contentView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
            headerView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -64.0),
            headerView.widthAnchor.constraint(equalToConstant: 42.0),
            headerView.heightAnchor.constraint(equalToConstant: 42.0)
        ])
    }
}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit

public class ContactSectionView: UITableViewHeaderFooterView {
    public var titleLabel = UILabel()
    var line = UIView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        self.contentView.backgroundColor = .white
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.titleLabel.textColor = NEKitContactConfig.shared.ui.indexTitleColor
        self.titleLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20)
        ])
        
        self.line.translatesAutoresizingMaskIntoConstraints = false
        self.line.backgroundColor = NEKitContactConfig.shared.ui.divideLineColor
        self.addSubview(self.line)
        NSLayoutConstraint.activate([
            self.line.leftAnchor.constraint(equalTo: self.titleLabel.leftAnchor),
            self.line.heightAnchor.constraint(equalToConstant: 1.0),
            self.line.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1.0),
            self.line.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
}

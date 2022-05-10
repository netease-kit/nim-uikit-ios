
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
typealias ValueChangeBlock = (_ title: String?, _ value: Bool) -> Void
class TextWithSwitchCell: TextBaseCell {
    public var block: ValueChangeBlock?;
    public var switchButton = UISwitch()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.switchButton.translatesAutoresizingMaskIntoConstraints = false
        self.switchButton.onTintColor = UIColor(hexString: "#337EFF")
        self.switchButton.addTarget(self, action: #selector(valueChanged), for: .touchUpInside)
        
        self.contentView.addSubview(self.switchButton)
        NSLayoutConstraint.activate([
            self.switchButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.switchButton.widthAnchor.constraint(equalToConstant: 46),
            self.switchButton.heightAnchor.constraint(equalToConstant: 28),
            self.switchButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func valueChanged(switchBtn: UISwitch) {
        print("switchBtn:\(switchBtn.isOn)")
        if let block = self.block {
            block(self.titleLabel.text, switchBtn.isOn)
        }
        
    }
}

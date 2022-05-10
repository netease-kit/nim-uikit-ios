
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

public class NEBrokenNetworkView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI(){

        self.backgroundColor = UIColor.init(red: 254/255, green: 227/255, blue: 230/255, alpha: 1)
        self.addSubview(content)
        NSLayoutConstraint.activate([
            content.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15),
            content.centerYAnchor.constraint(equalTo:  self.centerYAnchor),
            content.rightAnchor.constraint(equalTo:  self.rightAnchor, constant: -15),
        ])
    }
    
    private lazy var content:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.init(red: 252/255, green: 89/255, blue: 106/255, alpha: 1)
        label.textAlignment = .center
        label.text = "当前网络不可用，请检查你当网络设置。"
        return label
    }()
    

}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit

open class TextBaseCell: UITableViewCell {

    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    func setupSubviews(){
        self.selectionStyle = .none
        self.contentView.addSubview(headImge)
        self.contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headImge.leftAnchor.constraint(equalTo: self.contentView.leftAnchor,constant: 20),
            headImge.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            headImge.widthAnchor.constraint(equalToConstant: 36),
            headImge.heightAnchor.constraint(equalToConstant: 36)
        ])

        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: headImge.rightAnchor,constant: 12),
            titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor,constant: -20),
            titleLabel.centerYAnchor.constraint(equalTo: headImge.centerYAnchor)
        ])
        
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var headImge: NEUserHeaderView = {
        let headView = NEUserHeaderView(frame: .zero)
        headView.titleLabel.textColor = .white
        headView.titleLabel.font = UIFont.systemFont(ofSize: 14)
        headView.translatesAutoresizingMaskIntoConstraints = false
        headView.layer.cornerRadius = 18
        headView.clipsToBounds = true
        return headView
    }()
    
    
    public lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.ne_darkText
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

enum RightStyle {
    case none
    case indicate
    case delete
}

class ChatStateCell: ChatCornerCell {
    private var style: RightStyle = .none;
    public var rightImage = UIImageView()
    var rightImageMargin: NSLayoutConstraint?
    public var rightStyle: RightStyle  {
        get {
            return style
        }
        set {
            style = newValue;
            switch style {
            case .none:
                rightImage.image = nil
            case .indicate:
                rightImage.image = UIImage.ne_imageNamed(name: "arrowRight")
            case .delete:
                rightImage.image = UIImage.ne_imageNamed(name: "delete")
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.rightImage.contentMode = .center
        self.rightImage.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.rightImage)
        rightImageMargin = rightImage.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -36)
        rightImageMargin?.isActive = true
        NSLayoutConstraint.activate([
            self.rightImage.widthAnchor.constraint(equalToConstant: 20),
            self.rightImage.heightAnchor.constraint(equalToConstant: 20),
            self.rightImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit

class ContactSelectedCell: ContactTableViewCell {
    
    let sImage = UIImageView()
    
    var sModel: ContactInfo?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func commonUI() {
        super.commonUI()
        leftConstraint?.constant = 50
        contentView.addSubview(sImage)
        sImage.image = UIImage.ne_imageNamed(name: "unselect")
        sImage.highlightedImage = UIImage.ne_imageNamed(name: "select")
        sImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20)
        ])
    }
    
    override func setModel(_ model: ContactInfo) {
        super.setModel(model)
        if model.isSelected == false {
            sImage.isHighlighted = false
        }else {
            sImage.isHighlighted = true
        }
    }
    
    func setSelect(){
        sModel?.isSelected = true
        sImage.isHighlighted = true
    }
    
    func setUnselect(){
        sModel?.isSelected = false
        sImage.isHighlighted = false
    }

}

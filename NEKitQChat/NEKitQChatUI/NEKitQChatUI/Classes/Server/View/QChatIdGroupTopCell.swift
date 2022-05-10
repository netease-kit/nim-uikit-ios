
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class QChatIdGroupTopCell: QChatIdGroupCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setupUI() {
        super.setupUI()
        leftSpace?.constant = 20.0
        headImage.image = UIImage.ne_imageNamed(name: "member_header")
        titleLeftSpace?.constant = 12.0
        countHeadWidth?.constant = 0
        countHeadImage.isHidden = true
        headWidth?.constant = 36.0
        headHeight?.constant = 36.0
    }

}

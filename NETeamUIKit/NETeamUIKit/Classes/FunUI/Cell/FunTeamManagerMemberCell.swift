//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class FunTeamManagerMemberCell: FunTeamMemberCell {
//    lazy var removeLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = localizable("team_member_remove")
//        label.textColor = .funTeamRemoveLabelColor
//        label.font = UIFont.systemFont(ofSize: 14.0)
//        return label
//    }()

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
    ownerLabel.isHidden = true
  }
}

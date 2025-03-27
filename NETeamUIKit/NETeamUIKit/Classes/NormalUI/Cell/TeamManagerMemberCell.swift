//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class TeamManagerMemberCell: TeamMemberCell {
  override open func setupUI() {
    super.setupUI()
    ownerLabel.isHidden = true
    nameLabelRightMargin?.constant = NEAppLanguageUtil.getCurrentLanguage() == .english ? -100 : -65
  }
}

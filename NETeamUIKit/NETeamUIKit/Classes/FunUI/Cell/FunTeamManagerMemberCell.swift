//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class FunTeamManagerMemberCell: FunTeamMemberCell {
  override open func setupUI() {
    super.setupUI()
    ownerLabel.isHidden = true
  }
}

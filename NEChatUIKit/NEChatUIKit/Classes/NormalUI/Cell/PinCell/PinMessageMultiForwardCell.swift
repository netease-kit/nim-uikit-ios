// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class PinMessageMultiForwardCell: NEBasePinMessageMultiForwardCell {
  override open func setupUI() {
    super.setupUI()
    backViewLeft.addSubview(titleLabelLeft1)
    NSLayoutConstraint.activate([
      titleLabelLeft1.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: 16),
      titleLabelLeft1.rightAnchor.constraint(lessThanOrEqualTo: backViewLeft.rightAnchor, constant: -84),
      titleLabelLeft1.topAnchor.constraint(equalTo: backViewLeft.topAnchor, constant: 10),
      titleLabelLeft1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backViewLeft.addSubview(titleLabelLeft2)
    NSLayoutConstraint.activate([
      titleLabelLeft2.leftAnchor.constraint(equalTo: titleLabelLeft1.rightAnchor),
      titleLabelLeft2.centerYAnchor.constraint(equalTo: titleLabelLeft1.centerYAnchor),
      titleLabelLeft2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelLeft2.widthAnchor.constraint(equalToConstant: 74),
    ])

    backViewLeft.addSubview(contentLabelLeft1)
    NSLayoutConstraint.activate([
      contentLabelLeft1.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
      contentLabelLeft1.topAnchor.constraint(equalTo: titleLabelLeft1.bottomAnchor, constant: 2),
      contentLabelLeft1.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft1.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewLeft.addSubview(contentLabelLeft2)
    NSLayoutConstraint.activate([
      contentLabelLeft2.leftAnchor.constraint(equalTo: contentLabelLeft1.leftAnchor),
      contentLabelLeft2.topAnchor.constraint(equalTo: contentLabelLeft1.bottomAnchor),
      contentLabelLeft2.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft2.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewLeft.addSubview(contentLabelLeft3)
    NSLayoutConstraint.activate([
      contentLabelLeft3.leftAnchor.constraint(equalTo: contentLabelLeft2.leftAnchor),
      contentLabelLeft3.topAnchor.constraint(equalTo: contentLabelLeft2.bottomAnchor),
      contentLabelLeft3.widthAnchor.constraint(equalToConstant: contentW),
      contentLabelLeft3.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

//    backViewLeft.addSubview(contentHistoryLeft)
//    NSLayoutConstraint.activate([
//      contentHistoryLeft.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
//      contentHistoryLeft.bottomAnchor.constraint(equalTo: backViewLeft.bottomAnchor, constant: -12),
//      contentHistoryLeft.widthAnchor.constraint(equalToConstant: 60),
//      contentHistoryLeft.heightAnchor.constraint(equalToConstant: 14),
//    ])
//
//    backViewLeft.addSubview(dividerLineLeft)
//    NSLayoutConstraint.activate([
//      dividerLineLeft.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: 6),
//      dividerLineLeft.rightAnchor.constraint(equalTo: backViewLeft.rightAnchor, constant: -6),
//      dividerLineLeft.topAnchor.constraint(equalTo: contentHistoryLeft.topAnchor, constant: -6),
//      dividerLineLeft.heightAnchor.constraint(equalToConstant: 1),
//    ])
  }
}

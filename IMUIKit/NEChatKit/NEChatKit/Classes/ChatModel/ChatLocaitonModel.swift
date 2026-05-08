// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatLocaitonModel: NSObject {
  public var title: String = ""
  public var address: String = ""
  public var city: String = ""
  public var lat: CGFloat = 0.0
  public var lng: CGFloat = 0.0
  public var distance: Int = 0
  public var attribute: NSMutableAttributedString?
}


// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import UIKit
public class ContactsConfig {
    
    
    public init() {}
    
    //ContactSectionView
    public var dividerLineColor = UIColor(red: 219/255.0, green: 224/255.0, blue: 232/255.0, alpha: 1.0)
    public var sectionHeaderTitleColor = UIColor(red: 179/255.0, green: 183/255.0, blue: 188/255.0, alpha: 1.0)
    public var sectionHeaderTitleFont = UIFont.systemFont(ofSize: 14.0)
    
    // ContactTableViewCell
    public var cellTitleFont = UIFont.systemFont(ofSize: 14.0)
    public var cellTitleColor = UIColor(hexString: "333333")
    public var cellNameFont = UIFont.systemFont(ofSize: 14.0)
    public var cellNameColor = UIColor.white
    
    // global
    public var rowHeight: CGFloat = 52.0
    public var sectionHeaderHeight: CGFloat = 40.0
    public var sectionFooterHeight: CGFloat = 0.0
    
}

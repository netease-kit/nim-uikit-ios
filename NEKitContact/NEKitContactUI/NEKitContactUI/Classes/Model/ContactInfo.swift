
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitCoreIM
import UIKit

public class ContactInfo {
    func getRowHeight() -> CGFloat? {
        return nil
    }
    public var user: User?
    public var contactCellType = ContactCellType.ContactPerson.rawValue
    public var router = ContactPersonRouter
    public var isSelected = false
    public var headerBackColor: UIColor?
}

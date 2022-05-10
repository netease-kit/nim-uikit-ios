
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitCommon


let coreLoader = CommonLoader<PopListViewController>()
public func commonLocalizable(_ key: String) -> String{
    return coreLoader.localizable(key)
}

let kScreenWidth:CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight:CGFloat = UIScreen.main.bounds.size.height

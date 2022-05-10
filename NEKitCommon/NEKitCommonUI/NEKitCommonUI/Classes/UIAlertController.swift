
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation

public extension UIAlertController {
    func fixIpadAction(){
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            self.popoverPresentationController?.sourceView = view
            self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            self.popoverPresentationController?.permittedArrowDirections = []
        }
    }
}

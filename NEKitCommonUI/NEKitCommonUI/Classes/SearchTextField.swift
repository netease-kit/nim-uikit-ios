
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit

public class SearchTextField:UITextField {
   
    public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
       var rect = super.leftViewRect(forBounds: bounds)
       rect.origin.x += 10
       return rect
   }
   
    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
       var rect = super.placeholderRect(forBounds: bounds)
       rect.origin.x += 1
       return rect
   }
   
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
       
       var rect = super.editingRect(forBounds: bounds)
       rect.origin.x += 5
       return rect

   }
   
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
       var rect = super.textRect(forBounds: bounds)
       rect.origin.x += 5
       return rect
   }
}

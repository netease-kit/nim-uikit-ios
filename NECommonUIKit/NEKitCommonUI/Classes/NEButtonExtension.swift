
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation

public enum ButtonStyle {
    case top /// image在上，label在下
    case left /// image在左，label在右
    case bottom /// image在下，label在上
    case right /// image在右，label在左
}
public extension UIButton {

    func layoutButtonImage(style:ButtonStyle = ButtonStyle.left,space:CGFloat = 5){
        
        let imageWith = self.imageView?.bounds.width ?? 0
        let imageHeight = self.imageView?.bounds.height ?? 0
        
        let labelWidth = self.titleLabel?.intrinsicContentSize.width ?? 0
        let labelHeight = self.titleLabel?.intrinsicContentSize.height ?? 0
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        var contentEdgeInsets = UIEdgeInsets.zero
        
        let bWidth = self.bounds.width
        
        let min_height = min(imageHeight, labelHeight)
        
        switch style {
        case .left:
            self.contentVerticalAlignment = .center
            imageEdgeInsets = UIEdgeInsets(top: 0,
                                           left: 0,
                                           bottom: 0,
                                           right: 0)
            labelEdgeInsets = UIEdgeInsets(top: 0,
                                           left: space,
                                           bottom: 0,
                                           right: -space)
            contentEdgeInsets = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: space)
        case .right:
            self.contentVerticalAlignment = .center
            var w_di = labelWidth + space/2
            if (labelWidth+imageWith+space) > bWidth{
                let labelWidth_f = self.titleLabel?.frame.width ?? 0
                w_di = labelWidth_f + space/2
            }
            imageEdgeInsets = UIEdgeInsets(top: 0,
                                           left: w_di,
                                           bottom: 0,
                                           right: -w_di)
            labelEdgeInsets = UIEdgeInsets(top: 0,
                                           left: -(imageWith+space/2),
                                           bottom: 0,
                                           right: imageWith+space/2)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: space/2, bottom: 0, right: space/2.0)
        case .top:
            
            self.contentHorizontalAlignment = .center
            self.contentVerticalAlignment = .center
            
            var w_di = labelWidth/2.0
            
            if (labelWidth+imageWith+space) > bWidth{
                w_di = (bWidth - imageWith)/2
            }
           
            let labelWidth_f = self.titleLabel?.frame.width ?? 0
            if (imageWith+labelWidth_f+space)>bWidth{
                w_di = (bWidth - imageWith)/2
            }
            imageEdgeInsets = UIEdgeInsets(top: -(labelHeight+space),
                                           left: w_di,
                                           bottom: 0,
                                           right: -w_di)
            labelEdgeInsets = UIEdgeInsets(top: 0,
                                           left: -imageWith,
                                           bottom:-(space+imageHeight),
                                           right: 0)
            let h_di = (min_height+space)/2.0
            contentEdgeInsets = UIEdgeInsets(top:h_di,left: 0,bottom:h_di,right: 0)
        case .bottom:
           
            self.contentHorizontalAlignment = .center
            self.contentVerticalAlignment = .center
            var w_di = labelWidth/2
           
            if (labelWidth+imageWith+space) > bWidth{
                w_di = (bWidth - imageWith)/2
            }
           
            let labelWidth_f = self.titleLabel?.frame.width ?? 0
            if (imageWith+labelWidth_f+space)>bWidth{
                w_di = (bWidth - imageWith)/2
            }
            imageEdgeInsets = UIEdgeInsets(top: 0,
                                           left: w_di,
                                           bottom: -(labelHeight+space),
                                           right: -w_di)
            labelEdgeInsets = UIEdgeInsets(top: -(space+imageHeight),
                                           left: -imageWith,
                                           bottom: 0,
                                           right: 0)
            let h_di = (min_height+space)/2.0
            contentEdgeInsets = UIEdgeInsets(top:h_di, left: 0,bottom:h_di,right: 0)
        }
        self.contentEdgeInsets = contentEdgeInsets
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}

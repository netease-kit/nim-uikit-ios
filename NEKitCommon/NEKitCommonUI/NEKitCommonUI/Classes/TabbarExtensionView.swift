
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation

fileprivate let NEFlag: Int = 666

public extension UITabBar {
    // MARK:- 显示小红点
    func showBadgOn(index itemIndex: Int, tabbarItemNums: CGFloat = 4.0) {
        // 移除之前的小红点
        self.removeBadgeOn(index: itemIndex)
        
        // 创建小红点
        let bageView = UIView()
        bageView.tag = itemIndex + NEFlag
        bageView.layer.cornerRadius = 3
        bageView.backgroundColor = UIColor.red
        let tabFrame = self.frame
        
        // 确定小红点的位置
        let percentX: CGFloat = (CGFloat(itemIndex) + 0.59) / tabbarItemNums
        let x: CGFloat = CGFloat(ceilf(Float(percentX * tabFrame.size.width)))
        let y: CGFloat = CGFloat(ceilf(Float(0.015 * tabFrame.size.height)))
        bageView.frame = CGRect(x: x, y: y, width: 6, height: 6)
        self.addSubview(bageView)
    }
    
    // MARK:- 隐藏小红点
    func hideBadg(on itemIndex: Int) {
        // 移除小红点
        self.removeBadgeOn(index: itemIndex)
    }
    
    // MARK:- 移除小红点
    fileprivate func removeBadgeOn(index itemIndex: Int) {
        // 按照tag值进行移除
        _ = subviews.map {
            if $0.tag == itemIndex + NEFlag {
                $0.removeFromSuperview()
            }
        }
    }
}

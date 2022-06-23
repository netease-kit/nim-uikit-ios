//
//  ContactUIConfig.swift
//  NEKitContactUI
//
//  Created by vvj on 2022/6/13.
//

import UIKit
/// 头像枚举类型
public enum NEContactAvatarType {
    case rectangle  //矩形
    case cycle      //圆形
}


public class ContactUIConfig: NSObject {

    /// 头像圆角大小
    public var avatarCornerRadius = 4.0
    
    /// 头像类型
    public var avatarType:NEContactAvatarType = .cycle
    
    //通讯录标题大小
    public var titleFont = UIFont.systemFont(ofSize: 14)
    
    /// 通讯录标题颜色
    public var titleColor = UIColor.ne_darkText

    /// 是否隐藏通讯录搜索按钮
    public var hiddenSearchBtn = false
    
    /// 是否把顶部添加好友和搜索按钮都隐藏
    public var hiddenRightBtns = false
    
    /// 通讯录间隔线颜色
    public var divideLineColor = UIColor.ne_borderColor
    
    /// 检索标题字体颜色
    public var indexTitleColor = UIColor.ne_emptyTitleColor
}

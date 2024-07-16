
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit
import NIMSDK

protocol PersonInfoViewModelDelegate: AnyObject {
  func didClickHeadImage()
  func didClickNickName(name: String)
  func didClickGender()
  func didClickBirthday(birth: String)
  func didClickMobile(mobile: String)
  func didClickEmail(email: String)
  func didClickSign(sign: String)
  func didCopyAccount(account: String)
}

@objcMembers
public class PersonInfoViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  let contactRepo = ContactRepo.shared

  var userInfo: NEUserWithFriend?
  weak var delegate: PersonInfoViewModelDelegate?

  func getData(_ completion: @escaping () -> Void) {
    sectionData.removeAll()

    if let userFriend = NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) {
      userInfo = userFriend
      sectionData.append(getFirstSection())
      sectionData.append(getSecondSection())
      completion()
    } else {
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { [weak self] userFriend, error in
        guard let self = self else { return }
        self.userInfo = userFriend?.first
        self.sectionData.append(self.getFirstSection())
        self.sectionData.append(self.getSecondSection())
        completion()
      }
    }
  }

  func refreshData() {
    sectionData.removeAll()
    sectionData.append(getFirstSection())
    sectionData.append(getSecondSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()

    guard let mineInfo = userInfo else {
      return model
    }

    weak var weakSelf = self
    let headImageItem = SettingCellModel()
    headImageItem.type = SettingCellType.SettingHeaderCell.rawValue
    headImageItem.cellName = NSLocalizedString("headImage", comment: "")
    headImageItem.headerUrl = userInfo?.user?.avatar
    headImageItem.defaultHeadData = userInfo?.showName()
    headImageItem.subTitle = userInfo?.user?.accountId
    headImageItem.rowHeight = 64.0
    headImageItem.cellClick = {
      weakSelf?.delegate?.didClickHeadImage()
    }

    // 昵称
    let nickNameItem = SettingCellModel()
    nickNameItem.type = SettingCellType.SettingSubtitleCell.rawValue
    nickNameItem.cellName = NSLocalizedString("nickname", comment: "")
    nickNameItem.subTitle = mineInfo.showName()
    nickNameItem.rowHeight = 46.0
    nickNameItem.cellClick = {
      weakSelf?.delegate?.didClickNickName(name: nickNameItem.subTitle ?? "")
    }

    // 账号
    let accountItem = SettingCellModel()
    accountItem.type = SettingCellType.SettingSubtitleCustomCell.rawValue
    accountItem.cellName = NSLocalizedString("account", comment: "")
    accountItem.subTitle = mineInfo.user?.accountId
    accountItem.rowHeight = 46.0
    accountItem.rightCustomViewIcon = "copy_icon"
    accountItem.customViewClick = {
      weakSelf?.delegate?.didCopyAccount(account: mineInfo.user?.accountId ?? "")
    }

    // 性别
    let sexItem = SettingCellModel()
    sexItem.type = SettingCellType.SettingSubtitleCell.rawValue
    sexItem.cellName = NSLocalizedString("gender", comment: "")
    var sex = NSLocalizedString("unknown", comment: "")
    switch mineInfo.user?.gender {
    case 1:
      sex = NSLocalizedString("male", comment: "")
    case 2:
      sex = NSLocalizedString("female", comment: "")
    default:
      sex = NSLocalizedString("unknown", comment: "")
    }
    sexItem.subTitle = sex
    sexItem.rowHeight = 46.0
    sexItem.cellClick = {
      weakSelf?.delegate?.didClickGender()
    }

    // 生日
    let birthdayItem = SettingCellModel()
    birthdayItem.type = SettingCellType.SettingSubtitleCell.rawValue
    birthdayItem.cellName = NSLocalizedString("birthday", comment: "")
    birthdayItem.subTitle = mineInfo.user?.birthday
    birthdayItem.rowHeight = 46.0
    birthdayItem.cellClick = {
      weakSelf?.delegate?.didClickBirthday(birth: mineInfo.user?.birthday ?? "")
    }

    // 手机
    let telephoneItem = SettingCellModel()
    telephoneItem.type = SettingCellType.SettingSubtitleCell.rawValue
    telephoneItem.cellName = NSLocalizedString("phone", comment: "")
    telephoneItem.subTitle = mineInfo.user?.mobile
    telephoneItem.rowHeight = 46.0
    telephoneItem.cellClick = {
      weakSelf?.delegate?.didClickMobile(mobile: telephoneItem.subTitle ?? "")
    }

    // 邮箱
    let emailItem = SettingCellModel()
    emailItem.type = SettingCellType.SettingSubtitleCell.rawValue
    emailItem.cellName = NSLocalizedString("email", comment: "")
    emailItem.subTitle = mineInfo.user?.email
    emailItem.rowHeight = 46.0
    emailItem.cellClick = {
      weakSelf?.delegate?.didClickEmail(email: emailItem.subTitle ?? "")
    }

    model.cellModels.append(contentsOf: [
      headImageItem,
      nickNameItem,
      accountItem,
      sexItem,
      birthdayItem,
      telephoneItem,
      emailItem,
    ])
    model.setCornerType()
    return model
  }

  private func getSecondSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    guard let mineInfo = userInfo else {
      return model
    }

    let signItem = SettingCellModel()
    signItem.type = SettingCellType.SettingSubtitleCell.rawValue
    signItem.cellName = NSLocalizedString("individuality_sign", comment: "")
    signItem.subTitle = mineInfo.user?.sign
    signItem.rowHeight = 46.0
    signItem.titleWidth = 64
    weak var weakSelf = self
    signItem.cellClick = {
      weakSelf?.delegate?.didClickSign(sign: signItem.subTitle ?? "")
    }
    model.cellModels.append(contentsOf: [signItem])
    model.setCornerType()
    return model
  }

  /// 更新当前用户头像
  /// - Parameter avatar: 头像地址
  /// - Parameter completion: 更新结果回调
  func updateSelfAvatar(_ avatar: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.avatar = avatar
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户性别
  /// - Parameter gender: 用户性别
  /// - Parameter completion: 更新结果回调
  func updateSelfSex(_ gender: V2NIMGender, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.gender = gender
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户生日
  /// - Parameter birthDay: 生日
  /// - Parameter completion: 更新结果回调
  func updateSelfBirthday(_ birthDay: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.birthday = birthDay
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户昵称
  /// - Parameter nickName: 昵称
  /// - Parameter completion: 更新结果回调
  func updateSelfNickName(_ nickName: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.name = nickName

    // 如果昵称为空(不设置昵称)，则使用账号作为昵称
    if nickName.isEmpty {
      parameter.name = IMKitClient.instance.account()
    }

    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户电话号码
  /// - Parameter mobile: 电话号码
  /// - Parameter completion: 更新结果回调
  func updateSelfMobile(_ mobile: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.mobile = mobile
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户的邮箱
  /// - Parameter email: 邮箱
  /// - Parameter completion: 完成回调
  func updateSelfEmail(_ email: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.email = email
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }

  /// 更新当前用户的签名
  /// - Parameter sign: 签名
  /// - Parameter completion: 完成回调
  func updateSelfSign(_ sign: String, _ completion: @escaping (NSError?) -> Void) {
    let parameter = V2NIMUserUpdateParams()
    parameter.sign = sign
    contactRepo.updateSelfUserProfile(parameter) { error in
      completion(error)
    }
  }
}

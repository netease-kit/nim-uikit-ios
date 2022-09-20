
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitTeamUI
import NIMSDK

protocol PersonInfoViewModelDelegate: AnyObject {
  func didClickHeadImage()
  func didClickNickName(name: String)
  func didClickGender()
  func didClickBirthday()
  func didClickMobile(mobile: String)
  func didClickEmail(email: String)
  func didClickSign(sign: String)
  func didCopyAccount(account: String)
}

public class PersonInfoViewModel {
  var sectionData = [SettingSectionModel]()
  public let friendProvider = FriendProvider.shared
  public let userProvider = UserInfoProvider.shared

  private var userInfo: User?
  weak var delegate: PersonInfoViewModelDelegate?

  func getData() {
    sectionData.removeAll()
    userInfo = userProvider.getUserInfo(userId: IMKitEngine.instance.imAccid)
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
    headImageItem.cornerType = .topLeft.union(.topRight)
    headImageItem.type = SettingCellType.SettingHeaderCell.rawValue
    headImageItem.cellName = NSLocalizedString("headImage", comment: "")
    headImageItem.headerUrl = userInfo?.userInfo?.avatarUrl
    headImageItem.defaultHeadData = userInfo?.showName()
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
    accountItem.subTitle = mineInfo.userId
    accountItem.rowHeight = 46.0
    accountItem.rightCustomViewIcon = "copy_icon"
    accountItem.customViewClick = {
      weakSelf?.delegate?.didCopyAccount(account: mineInfo.userId ?? "")
    }

    // 性别
    let sexItem = SettingCellModel()
    sexItem.type = SettingCellType.SettingSubtitleCell.rawValue
    sexItem.cellName = NSLocalizedString("gender", comment: "")
    var sex = NSLocalizedString("unknown", comment: "")
    switch mineInfo.userInfo?.gender {
    case .male:
      sex = NSLocalizedString("male", comment: "")
    case .female:
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
    birthdayItem.cellName = NSLocalizedString("birehday", comment: "")
    birthdayItem.subTitle = mineInfo.userInfo?.birth
    birthdayItem.rowHeight = 46.0
    birthdayItem.cellClick = {
      weakSelf?.delegate?.didClickBirthday()
    }
    // 手机
    let telephoneItem = SettingCellModel()
    telephoneItem.type = SettingCellType.SettingSubtitleCell.rawValue
    telephoneItem.cellName = NSLocalizedString("phone", comment: "")
    telephoneItem.subTitle = mineInfo.userInfo?.mobile
    telephoneItem.rowHeight = 46.0
    telephoneItem.cellClick = {
      weakSelf?.delegate?.didClickMobile(mobile: telephoneItem.subTitle ?? "")
    }

    // 邮箱
    let emailItem = SettingCellModel()
    emailItem.type = SettingCellType.SettingSubtitleCell.rawValue
    emailItem.cellName = NSLocalizedString("email", comment: "")
    emailItem.subTitle = mineInfo.userInfo?.email
    emailItem.cornerType = .bottomLeft.union(.bottomRight)
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
    signItem.subTitle = mineInfo.userInfo?.sign
    signItem.rowHeight = 46.0
    signItem.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
    weak var weakSelf = self
    signItem.cellClick = {
      weakSelf?.delegate?.didClickSign(sign: signItem.subTitle ?? "")
    }
    model.cellModels.append(contentsOf: [signItem])
    return model
  }

  func updateAvatar(avatar: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.avatar.rawValue): avatar]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateSex(sex: NIMUserGender, _ completion: @escaping (NSError?) -> Void) {
    let changeValue =
      [NSNumber(value: NIMUserInfoUpdateTag.gender.rawValue): NSNumber(value: sex.rawValue)]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateBirthday(birthDay: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.birth.rawValue): birthDay]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateNickName(name: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.nick.rawValue): name]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateMobile(mobile: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.mobile.rawValue): mobile]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateEmail(email: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.email.rawValue): email]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  func updateSign(sign: String, _ completion: @escaping (NSError?) -> Void) {
    let changeValue = [NSNumber(value: NIMUserInfoUpdateTag.sign.rawValue): sign]
    userProvider.updateMyUserInfo(values: changeValue) { error in
      if error == nil {
        completion(nil)
      } else {
        completion(error)
      }
    }
  }
}

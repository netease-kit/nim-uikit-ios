
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamNameViewController: NEBaseViewController, UITextViewDelegate {
  /// 群对象
  public var team: V2NIMTeam?
  /// 修改类型
  public var type = ChangeType.TeamName
  /// 群成员
  public var teamMember: V2NIMTeamMember?
  /// 数据单例
  public var repo = TeamRepo.shared
  /// 输入长度限制
  public var textLimit = 30
  /// 背景视图
  public let backView = UIView()

  let viewModel = TeamNameViewModel()

  /// 计数文本显示标签
  public lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xB3B7BC)
    label.font = NEConstant.defaultTextFont(12.0)
    label.isUserInteractionEnabled = false
    label.accessibilityIdentifier = "id.flag"
    return label
  }()

  /// 名称输入框
  public lazy var textInputView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textColor = NEConstant.hexRGB(0x333333)
    textView.font = NEConstant.defaultTextFont(14.0)
    textView.delegate = self
    textView.accessibilityIdentifier = "id.nickname"
    return textView
  }()

  /// 清除按钮
  public lazy var clearButton: UIButton = {
    let text = UIButton()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.setImage(coreLoader.loadImage("clear_btn"), for: .normal)
    text.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    text.accessibilityIdentifier = "id.clear"
    return text
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self
    viewModel.getCurrentUserTeamMember(team?.teamId) { error in
      if let err = error {
        weakSelf?.view.makeToast(err.localizedDescription)
      }
      DispatchQueue.main.async {
        weakSelf?.configData()
      }
    }
    setupUI()
  }

  /// UI 控件初始化
  open func setupUI() {
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    view.addSubview(backView)
    backView.addSubview(textInputView)
    backView.addSubview(clearButton)
    backView.addSubview(countLabel)

    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])
  }

  /// 绑定数据
  func configData() {
    var name = ""
    if type == .TeamName, let n = team?.name {
      name = n
      if getEditablePermission() == false {
        rightNavButton.isHidden = true
        navigationView.moreButton.isHidden = true
        textInputView.isEditable = false
      }
    } else if type == .NickName {
      title = localizable("team_nick")
      if let n = teamMember?.teamNick {
        name = n
      }
    }
    figureTextCount(name)

    if name.count <= 0, type != .NickName {
      disableSubmit()
    }
  }

  /// 查看是否有编辑权限
  func getEditablePermission() -> Bool {
    if type == .NickName {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .TEAM_UPDATE_INFO_MODE_ALL {
      return true
    }
    if let ownerId = team?.ownerAccountId, IMKitClient.instance.isMe(ownerId) {
      return true
    }

    if let member = viewModel.currentTeamMember, member.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
      return true
    }
    return false
  }

  /// 提交按钮显示不可提交状态
  open func disableSubmit() {
    rightNavButton.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    rightNavButton.isEnabled = false
    navigationView.moreButton.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    navigationView.moreButton.isEnabled = false
  }

  /// 提交按钮显示可提交状态
  open func enableSubmit() {
    rightNavButton.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    rightNavButton.isEnabled = true
    navigationView.moreButton.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    navigationView.moreButton.isEnabled = true
  }

  /// 保存群名称
  open func saveName() {
    guard let tid = team?.teamId else {
      showToast(localizable("failed_operation"))
      return
    }

    weak var weakSelf = self

    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    if let text = textInputView.text,
       !text.isEmpty {
      let trimText = text.trimmingCharacters(in: .whitespaces)
      if trimText.isEmpty {
        view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
        figureTextCount(trimText)
        return
      }
    }

    textInputView.resignFirstResponder()

    if type == .TeamName {
      let n = textInputView.text ?? ""
      view.makeToastActivity(.center)
      repo.updateTeamName(tid, .TEAM_TYPE_NORMAL, n) { error in
        weakSelf?.view.hideToastActivity()
        if error != nil {
          if error?.code == noPermissionOperationCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
            return
          }
          weakSelf?.showToast(localizable("failed_operation"))
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    } else if type == .NickName, let uid = teamMember?.accountId {
      let n = textInputView.text ?? ""
      view.makeToastActivity(.center)
      repo.updateMemberNick(tid, .TEAM_TYPE_NORMAL, uid, n) { error in

        weakSelf?.view.hideToastActivity()
        if error != nil {
          weakSelf?.showToast(localizable("failed_operation"))
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  /// 清除文本
  func clearText() {
    figureTextCount("")
  }

  /// 计算显示数量
  /// - Parameter text: 文本内容
  func figureTextCount(_ text: String) {
    textInputView.text = text
    countLabel.text = "\(text.utf16.count)/\(textLimit)"
    clearButton.isHidden = !getEditablePermission() || text.utf16.count <= 0
    if type == .NickName {
      return
    }
    if text.count > 0 {
      enableSubmit()
    } else {
      disableSubmit()
    }
  }

  /// 文本变更回调
  /// - Parameter textView: 文本控件对象
  open func textViewDidChange(_ textView: UITextView) {
    if let _ = textView.markedTextRange {
      return
    }
    if let text = textView.text {
      figureTextCount(text)
    }
  }

  /// 文本变更回调
  /// - Parameter textView: 文本控件对象
  /// - Parameter range: 变更范围
  /// - Parameter text:  变更内容
  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if !text.isEmpty {
      let finalStr = (textView.text as NSString).replacingCharacters(in: range, with: text)
      if finalStr.utf16.count > textLimit {
        return false
      }
    }
    return true
  }
}

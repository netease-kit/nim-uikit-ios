
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamIntroduceViewController: NEBaseViewController, UITextViewDelegate {
  public var team: V2NIMTeam?
  public let textLimit = 100
  public let backView = UIView()

  public let viewModel = TeamIntroduceViewModel()

  /// 介绍输入框
  public lazy var textView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textColor = NEConstant.hexRGB(0x333333)
    textView.font = NEConstant.defaultTextFont(14.0)
    textView.delegate = self
    textView.textContainerInset = UIEdgeInsets.zero
    textView.layoutManager.allowsNonContiguousLayout = false
    textView.accessibilityIdentifier = "id.introduce"
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

  /// 字数计数显示
  public lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xB3B7BC)
    label.font = NEConstant.defaultTextFont(12.0)
    label.accessibilityIdentifier = "id.flag"
    return label
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self
    viewModel.getCurrentUserTeamMember(team?.teamId) { error in
      if let err = error {
        weakSelf?.view.makeToast(err.localizedDescription)
      }
      weakSelf?.setupUI()
    }
  }

  /// 布局初始化
  open func setupUI() {
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveIntr))
    if let serverExtension = team?.serverExtension, serverExtension.contains(discussTeamKey) {
      title = localizable("discuss_introduce")
    } else {
      title = localizable("team_intr")
    }

    backView.backgroundColor = .white
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.clipsToBounds = false

    view.addSubview(backView)
    backView.addSubview(textView)
    backView.addSubview(clearButton)
    backView.addSubview(countLabel)

    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])

    figureTextCount(team?.intro ?? "")

    if getPermission() == false {
      textView.isEditable = false
      rightNavButton.isHidden = true
      navigationView.moreButton.isHidden = true
    }
  }

  /// 权限改变
  func getPermission() -> Bool {
    if let ownerId = team?.ownerAccountId, IMKitClient.instance.isMe(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .TEAM_UPDATE_INFO_MODE_ALL {
      return true
    }
    if let member = viewModel.currentTeamMember, member.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
      return true
    }
    return false
  }

  /// 保存简介
  func saveIntr() {
    textView.resignFirstResponder()
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    // 上传请求
    if let teamid = team?.teamId {
      let text = textView.text ?? ""
      view.makeToastActivity(.center)
      viewModel.updateTeamIntroduce(teamid, text) { error in
        NEALog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamIntroduce " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if error?.code == noPermissionOperationCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  /// 计算当前输入字数
  func figureTextCount(_ text: String) {
    textView.text = text
    countLabel.text = "\(text.utf16.count)/\(textLimit)"
    clearButton.isHidden = !getPermission() || text.utf16.count <= 0
  }

  /// 清空输入
  func clearText() {
    figureTextCount("")
  }

  /// 输入文本变更回调
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

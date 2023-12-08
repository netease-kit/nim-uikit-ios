
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamNameViewController: NEBaseViewController, UITextViewDelegate {
  public var team: NIMTeam?
//    var user: NIMUser?
  public var type = ChangeType.TeamName
  public var teamMember: NIMTeamMember?
  public var repo = TeamRepo.shared
  public let textLimit = 30

  public let backView = UIView()

  public lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xB3B7BC)
    label.font = NEConstant.defaultTextFont(12.0)
    label.isUserInteractionEnabled = false
    label.accessibilityIdentifier = "id.flag"
    return label
  }()

  public lazy var textView: UITextView = {
    let text = UITextView()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = NEConstant.hexRGB(0x333333)
    text.font = NEConstant.defaultTextFont(14.0)
    text.delegate = self
    text.accessibilityIdentifier = "id.nickname"
    return text
  }()

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
    setupUI()
  }

  open func setupUI() {
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    view.addSubview(backView)
    backView.addSubview(textView)
    backView.addSubview(clearButton)
    backView.addSubview(countLabel)

    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])

    var name = ""
    if type == .TeamName, let n = team?.teamName {
      name = n
      if changePermission() == false {
        rightNavBtn.isHidden = true
        navigationView.moreButton.isHidden = true
        textView.isEditable = false
      }
    } else if type == .NickName {
      title = localizable("team_nick")
      if let n = teamMember?.nickname {
        name = n
      }
    }

    figureTextCount(name)

    if name.count <= 0, type != .NickName {
      disableSubmit()
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  func changePermission() -> Bool {
    if type == .NickName {
      return true
    }

    if let type = team?.type, type == .normal {
      return true
    }

    if let ownerId = team?.owner, IMKitClient.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    return false
  }

  open func disableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    rightNavBtn.isEnabled = false
    navigationView.moreButton.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    navigationView.moreButton.isEnabled = false
  }

  open func enableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    rightNavBtn.isEnabled = true
    navigationView.moreButton.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    navigationView.moreButton.isEnabled = true
  }

  open func saveName() {
    guard let tid = team?.teamId else {
      showToast(localizable("team_not_exist"))
      return
    }

    if let text = textView.text,
       !text.isEmpty {
      let trimText = text.trimmingCharacters(in: .whitespaces)
      if trimText.isEmpty {
        view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
        figureTextCount(trimText)
        return
      }
    }

    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    textView.resignFirstResponder()
    if type == .TeamName {
      let n = textView.text ?? ""
      view.makeToastActivity(.center)
      repo.updateTeamName(tid, n) { error in
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.team?.teamName = n
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    } else if type == .NickName, let uid = teamMember?.userId {
      let n = textView.text ?? ""
      view.makeToastActivity(.center)
      repo.updateMemberNick(tid, uid, n) { error in

        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  func clearText() {
    figureTextCount("")
  }

  func figureTextCount(_ text: String) {
    textView.text = text
    countLabel.text = "\(text.count)/\(textLimit)"
    clearButton.isHidden = !changePermission() || text.count <= 0
    if type == .NickName {
      return
    }
    if text.count > 0 {
      enableSubmit()
    } else {
      disableSubmit()
    }
  }

  // MARK: UITextViewDelegate

  public func textViewDidChange(_ textView: UITextView) {
    if let _ = textView.markedTextRange {
      return
    }
    if var text = textView.text {
      if text.count > textLimit {
        text = String(text.prefix(textLimit))
      }
      figureTextCount(text)
    }
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamIntroduceViewController: NEBaseViewController, UITextViewDelegate {
//    typealias SaveCompletion = () -> Void
//
//    var block: SaveCompletion?

  public var team: NIMTeam?
  public let textLimit = 100
  public let repo = TeamRepo.shared
  public let backView = UIView()

  public lazy var textView: UITextView = {
    let text = UITextView()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = NEConstant.hexRGB(0x333333)
    text.font = NEConstant.defaultTextFont(14.0)
    text.delegate = self
    text.textContainerInset = UIEdgeInsets.zero
    text.layoutManager.allowsNonContiguousLayout = false
    text.accessibilityIdentifier = "id.introduce"
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
    setupUI()
  }

  open func setupUI() {
    customNavigationView.setMoreButtonTitle(localizable("save"))
    customNavigationView.addMoreButtonTarget(target: self, selector: #selector(saveIntr))

    if let type = team?.type, type == .advanced {
      title = localizable("team_intr")
    } else {
      title = localizable("discuss_introduce")
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

    if changePermission() == false {
      textView.isEditable = false
      rightNavBtn.isHidden = true
      customNavigationView.moreButton.isHidden = true
    }
  }

  func changePermission() -> Bool {
    if let ownerId = team?.owner, IMKitClient.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    return false
  }

  func saveIntr() {
    textView.resignFirstResponder()
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    if let teamid = team?.teamId {
      let text = textView.text ?? ""
      view.makeToastActivity(.center)
      repo.updateTeamIntroduce(text, teamid) { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamIntroduce " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.team?.intro = text
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  func figureTextCount(_ text: String) {
    textView.text = text
    countLabel.text = "\(text.count)/\(textLimit)"
    clearButton.isHidden = !changePermission() || text.count <= 0
  }

  func clearText() {
    figureTextCount("")
  }

  // MARK: UITextViewDelegate

  open func textViewDidChange(_ textView: UITextView) {
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

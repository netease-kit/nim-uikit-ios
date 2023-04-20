
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECommonKit
import NETeamKit

@objc public enum ChangeType: Int {
  case TeamName = 0
  case NickName
}

@objcMembers
public class TeamNameViewController: NEBaseViewController, UITextFieldDelegate {
  var team: NIMTeam?
//    var user: NIMUser?
  var type = ChangeType.TeamName
  var teamMember: NIMTeamMember?
  var repo = TeamRepo()
  let textLimit = 30

  lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xB3B7BC)
    label.font = NEConstant.defaultTextFont(12.0)
    return label
  }()

  lazy var textField: UITextField = {
    let text = UITextField()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = NEConstant.hexRGB(0x333333)
    text.font = NEConstant.defaultTextFont(14.0)
    text.delegate = self
    text.clearButtonMode = .always

    return text
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    view.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    let backView = UIView()
    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    backView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
        backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        backView.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 12
        ),
        backView.heightAnchor.constraint(equalToConstant: 60),
      ])
    } else {
      NSLayoutConstraint.activate([
        backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
        backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
        backView.heightAnchor.constraint(equalToConstant: 60),
      ])
    }

    backView.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -12),
      textField.topAnchor.constraint(equalTo: backView.topAnchor, constant: 0),
      textField.heightAnchor.constraint(equalToConstant: 44),
//            textField.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: 0)
    ])

    backView.addSubview(countLabel)
    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])

    var name = ""
    if type == .TeamName, let n = team?.teamName {
      name = n

      if changePermission() == false {
//                disableSubmit()
        rightNavBtn.isHidden = true
        textField.clearButtonMode = .never
        textField.isEnabled = false
      }
      if let teamType = team?.type, teamType == .normal {
        title = localizable("discuss_name")
      } else {
        title = localizable("team_name")
      }

    } else if type == .NickName, let n = teamMember?.nickname {
      title = localizable("team_nick")
      name = n
    }

    countLabel.text = "\(name.count)/\(textLimit)"
    textField.text = name

    if name.count <= 0, type != .NickName {
      disableSubmit()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textFieldChange),
      name: UITextField.textDidChangeNotification,
      object: textField
    )

    addRightAction(localizable("save"), #selector(saveName), self)
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
    if let type = team?.type, type == .normal {
      return true
    }

    if let ownerId = team?.owner, IMKitEngine.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    return false
  }

  func disableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    rightNavBtn.isEnabled = false
  }

  func enableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    rightNavBtn.isEnabled = true
  }

  // MARK: objc 方法

  func textFieldChange() {
    if let _ = textField.markedTextRange {
      return
    }
    if var text = textField.text {
      if let lang = textField.textInputMode?.primaryLanguage, lang == "zh-Hans" {
        if text.count > textLimit {
          text = String(text.prefix(textLimit))
          textField.text = String(text)
        }
        figureTextCount(text)
      }
    }
  }

  func saveName() {
    guard let tid = team?.teamId else {
      showToast(localizable("team_not_exist"))
      return
    }

    if let text = textField.text,
       !text.isEmpty {
      let trimText = text.trimmingCharacters(in: .whitespaces)
      if trimText.isEmpty {
        view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
        textField.text = trimText
        figureTextCount(trimText)
        return
      }
    }

    weak var weakSelf = self
    textField.resignFirstResponder()
    if type == .TeamName {
      let n = textField.text ?? ""
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
      let n = textField.text ?? ""
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
}

extension TeamNameViewController {
  func figureTextCount(_ text: String) {
    countLabel.text = "\(text.count)/\(textLimit)"
    if type == .NickName {
      return
    }
    if text.count > 0 {
      enableSubmit()
    } else {
      disableSubmit()
    }
  }
}

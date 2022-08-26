
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCommon
import NIMSDK
import NEKitTeam

public class TeamIntroduceViewController: NEBaseViewController,UITextViewDelegate {
//    typealias SaveCompletion = () -> Void
//
//    var block: SaveCompletion?

  var team: NIMTeam?

  let repo = TeamRepo()

  lazy var textView: UITextView = {
    let text = UITextView()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = NEConstant.hexRGB(0x333333)
    text.font = NEConstant.defaultTextFont(14.0)
    text.delegate = self
    text.textContainerInset = UIEdgeInsets.zero
    text.layoutManager.allowsNonContiguousLayout = false
    return text
  }()

  lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xB3B7BC)
    label.font = NEConstant.defaultTextFont(12.0)
    return label
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupUI()
  }

  func setupUI() {
    addRightAction("保存", #selector(saveIntr), self)

    if let type = team?.type, type == .advanced {
      title = "群介绍"
    } else {
      title = "讨论组介绍"
    }

    view.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    let backView = UIView()
    backView.backgroundColor = .white
    backView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backView)
    backView.clipsToBounds = false
    backView.layer.cornerRadius = 8.0
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        backView.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 12.0
        ),
        backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        backView.heightAnchor.constraint(equalToConstant: 170),
      ])
    } else {
      NSLayoutConstraint.activate([
        backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.0),
        backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        backView.heightAnchor.constraint(equalToConstant: 170),
      ])
    }

    backView.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
      textView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16.0),
      textView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16.0),
      textView.heightAnchor.constraint(equalToConstant: 120),
    ])

    textView.text = team?.intro

    backView.addSubview(countLabel)
    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])

    if let intr = team?.intro {
      countLabel.text = "\(intr.count)/100"
    } else {
      countLabel.text = "0/100"
    }

    if changePermission() == false {
      textView.isEditable = false
      rightNavBtn.isHidden = true
    }
  }

  func disableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGBAlpha(0x337EFF, 0.5), for: .normal)
    rightNavBtn.isEnabled = false
  }

  func enableSubmit() {
    rightNavBtn.setTitleColor(NEConstant.hexRGB(0x337EFF), for: .normal)
    rightNavBtn.isEnabled = true
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
    if let ownerId = team?.owner, IMKitLoginManager.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    return false
  }
    
    @objc func saveIntr() {
      textView.resignFirstResponder()
      if let teamid = team?.teamId {
        let text = textView.text ?? ""
        weak var weakSelf = self
        view.makeToastActivity(.center)
        repo.updateTeamIntroduce(text, teamid) { error in
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
    //MARK: UITextViewDelegate
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
      let currentText = textView.text ?? ""
      guard let stringRange = Range(range, in: currentText) else { return false }
      let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
      return updatedText.count <= 100
    }

    public func textViewDidChange(_ textView: UITextView) {
      if var text = textView.text {
        if let lang = textView.textInputMode?.primaryLanguage, lang == "zh-Hans",
           let selectRange = textView.markedTextRange {
          let position = textView.position(from: selectRange.start, offset: 0)
          if position == nil {
            if text.count > 30 {
              text = String(text.prefix(30))
              textView.text = String(text.prefix(30))
            }
            countLabel.text = "\(text.count)/100"
          }
        } else {
          countLabel.text = "\(text.count)/100"
        }
      }
    }
}


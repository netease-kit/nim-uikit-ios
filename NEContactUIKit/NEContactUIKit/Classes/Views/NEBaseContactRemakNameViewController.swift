
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseContactRemakNameViewController: NEBaseContactViewController, UITextFieldDelegate {
  typealias ModifyBlock = (_ user: NEKitUser) -> Void

  var completion: ModifyBlock?
  var user: NEKitUser?
  let viewmodel = ContactUserViewModel()
  let textLimit = 15
  lazy var aliasInput: UITextField = {
    let textField = UITextField()
    textField.backgroundColor = .white
    textField.clipsToBounds = true
    textField.font = UIFont.systemFont(ofSize: 16.0)
    textField.translatesAutoresizingMaskIntoConstraints = false
    let leftSpace = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
    textField.leftView = leftSpace
    textField.leftViewMode = .always
    textField.delegate = self
    textField.clearButtonMode = .always
    textField.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.editText"
    return textField
  }()

//    lazy var rightBtn: ExpandButton = {
//        let btn = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
//        btn.setTitleColor(UIColor(hexString: "#337EFF"), for: .normal)
//        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
//        btn.addTarget(self, action: #selector(saveAlias), for: .touchUpInside)
//        return btn
//    }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    title = localizable("noteName")
    navigationView.navTitle.text = title
    view.backgroundColor = .ne_lightBackgroundColor

    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveAlias))
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(aliasInput)
    aliasInput.placeholder = localizable("input_noteName")
    if let alias = user?.alias, !alias.isEmpty {
      aliasInput.text = alias
    }
  }

  func saveAlias() {
//        guard let alais = aliasInput.text, alais.count > 0 else {
//            view.makeToast("请填写备注名", duration: 2, position: .center)
//            return
//        }
    if let text = aliasInput.text,
       text.count > 0,
       text.trimmingCharacters(in: .whitespaces).isEmpty {
      view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
      aliasInput.text = ""
      return
    }

    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    if user?.alias != aliasInput.text {
      user?.alias = aliasInput.text
      NotificationCenter.default.post(name: NENotificationName.updateFriendInfo, object: user)
    }

    if let u = user {
      view.makeToastActivity(.center)
      viewmodel.update(u) { error in
        NELog.infoLog(
          "ContactRemakNameViewController",
          desc: "CALLBACK update " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.view.makeToast(
            err.localizedDescription,
            duration: 2,
            position: .center
          )
        } else {
          if let block = weakSelf?.completion {
            block(u)
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
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

  open func textFieldChange() {
    guard let _ = aliasInput.markedTextRange else {
      if let text = aliasInput.text,
         text.count > textLimit {
        aliasInput.text = String(text.prefix(textLimit))
      }
      return
    }
  }
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseContactAliasViewController: NEContactBaseViewController, UITextFieldDelegate {
  typealias ModifyBlock = (_ user: NEUserWithFriend) -> Void

  var completion: ModifyBlock?
  var user: NEUserWithFriend?
  let viewmodel = ContactUserViewModel()
  let textLimit = 15
  public var aliasInputTopAnchor: NSLayoutConstraint?
  public lazy var aliasInput: UITextField = {
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

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    aliasInputTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    title = localizable("noteName")
    view.backgroundColor = .ne_lightBackgroundColor

    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveAlias))
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(aliasInput)
    aliasInput.placeholder = localizable("input_noteName")
    if let alias = user?.friend?.alias, !alias.isEmpty {
      aliasInput.text = alias
    }
  }

  func saveAlias() {
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

    user?.friend?.alias = aliasInput.text

    if let uid = user?.user?.accountId, let alias = aliasInput.text {
      view.makeToastActivity(.center)
      viewmodel.updateAlias(accountId: uid, alias: alias) { error in
        NEALog.infoLog(
          "ContactAliasViewController",
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
          if let block = weakSelf?.completion, let u = weakSelf?.user {
            block(u)
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

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

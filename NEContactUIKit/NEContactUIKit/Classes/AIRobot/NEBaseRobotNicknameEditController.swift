// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import UIKit

/// 机器人昵称编辑页
/// 顶部白色 TextField 卡片 + 导航右侧「完成」按钮 + 字数计数提示
open class NEBaseRobotNicknameEditController: NEContactBaseViewController, UITextFieldDelegate {
  /// 当前昵称（进入时预填充）
  public var currentName: String = ""

  /// 保存成功回调，参数为新昵称
  public var onSaved: ((String) -> Void)?

  /// 昵称最大字符数
  public let nameLimit = 15

  // MARK: - Views

  /// 字数提示：「当前字符数/上限」，显示在清除按钮左侧
  public lazy var countLabel: UILabel = {
    let l = UILabel()
    l.font = .systemFont(ofSize: 13)
    l.textColor = UIColor(hexString: "999999")
    l.textAlignment = .right
    l.text = "0/\(nameLimit)"
    return l
  }()

  /// 自定义清除按钮（替换系统 clearButton，配合 rightView 布局使用）
  public lazy var clearButton: UIButton = {
    let btn = UIButton(type: .custom)
    if #available(iOS 13.0, *) {
      let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
      btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
      btn.tintColor = UIColor(hexString: "CCCCCC")
    } else {
      btn.setTitle("✕", for: .normal)
      btn.setTitleColor(UIColor(hexString: "CCCCCC"), for: .normal)
      btn.titleLabel?.font = .systemFont(ofSize: 14)
    }
    btn.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
    return btn
  }()

  public lazy var textField: UITextField = {
    let tf = UITextField()
    tf.translatesAutoresizingMaskIntoConstraints = false
    tf.font = .systemFont(ofSize: 16)
    tf.textColor = .ne_darkText
    // 不使用系统 clearButton，改用自定义 rightView 内的清除按钮
    tf.clearButtonMode = .never
    tf.returnKeyType = .done
    tf.delegate = self
    tf.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    tf.accessibilityIdentifier = "id.editText"
    // 左侧内边距
    let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
    tf.leftView = leftPad
    tf.leftViewMode = .always
    return tf
  }()

  public lazy var textFieldContainer: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  // MARK: - 生命周期

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("ai_robot_name")
    view.backgroundColor = .ne_lightBackgroundColor

    // 导航右侧「完成」按钮
    navigationView.setMoreButtonTitle(localizable("done"), saveButtonColor())
    navigationView.addMoreButtonTarget(target: self, selector: #selector(didTapSave))

    setupNicknameEditUI()

    textField.text = currentName
    updateCountLabel(text: currentName)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.textField.becomeFirstResponder()
    }))
  }

  // MARK: - UI

  open func setupNicknameEditUI() {
    view.addSubview(textFieldContainer)
    NSLayoutConstraint.activate([
      textFieldContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      textFieldContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
      textFieldContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
      textFieldContainer.heightAnchor.constraint(equalToConstant: 48),
    ])
    setupTextFieldContainerStyle()

    // 构建 rightView：[countLabel 8pt clearButton 8pt]
    let rightContainer = buildRightView()
    textField.rightView = rightContainer
    textField.rightViewMode = .always

    textFieldContainer.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: textFieldContainer.leftAnchor),
      textField.rightAnchor.constraint(equalTo: textFieldContainer.rightAnchor, constant: -8),
      textField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
      textField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
    ])
  }

  /// 构建 rightView 容器：字数标签 + 清除按钮
  /// UITextField 的 rightView 使用 frame 布局，这里计算固定宽度
  open func buildRightView() -> UIView {
    // countLabel 宽度固定为能容纳「15/15」的宽度
    let countLabelW: CGFloat = 40
    let clearBtnW: CGFloat = 20
    let spacing: CGFloat = 4
    let rightPadding: CGFloat = 8
    let containerW = countLabelW + spacing + clearBtnW + rightPadding
    let containerH: CGFloat = 44

    let container = UIView(frame: CGRect(x: 0, y: 0, width: containerW, height: containerH))
    container.backgroundColor = .clear

    countLabel.frame = CGRect(x: 0, y: (containerH - 18) / 2, width: countLabelW, height: 18)
    container.addSubview(countLabel)

    clearButton.frame = CGRect(
      x: countLabelW + spacing,
      y: (containerH - clearBtnW) / 2,
      width: clearBtnW,
      height: clearBtnW
    )
    container.addSubview(clearButton)

    return container
  }

  /// 容器卡片样式，子类可 override
  open func setupTextFieldContainerStyle() {}

  /// 保存/完成按钮颜色，子类 override
  open func saveButtonColor() -> UIColor { .normalContactThemeColor }

  // MARK: - 字数更新

  open func updateCountLabel(text: String) {
    let count = text.count
    countLabel.text = "\(count)/\(nameLimit)"
  }

  // MARK: - Actions

  @objc open func didTapSave() {
    let name = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      showToast(localizable("ai_robot_name_placeholder"))
      return
    }
    onSaved?(name)
    navigationController?.popViewController(animated: true)
  }

  @objc open func didTapClear() {
    textField.text = ""
    updateCountLabel(text: "")
  }

  @objc open func textFieldChanged() {
    var text = textField.text ?? ""
    if text.count > nameLimit {
      text = String(text.prefix(nameLimit))
      textField.text = text
    }
    updateCountLabel(text: text)
  }

  // MARK: - UITextFieldDelegate

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

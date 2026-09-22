// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEBaseUIKit

private let conversationGroupNameMaxLength = 20

final class NEConversationGroupNameSheetController: UIViewController, UITextFieldDelegate {
  private let complete: (String) -> Void
  private let sheetTitle: String
  private let initialName: String?
  private let style: NEConversationGroupUIStyle
  private let heightRatio: CGFloat
  private let container = UIView()
  private let textField = NESingleLineTextField()
  private let countLabel = UILabel()
  private let done = UIButton(type: .custom)

  init(title: String,
       initialName: String? = nil,
       style: NEConversationGroupUIStyle = .normal,
       heightRatio: CGFloat = 0.9,
       complete: @escaping (String) -> Void) {
    sheetTitle = title
    self.initialName = initialName
    self.style = style
    self.heightRatio = heightRatio
    self.complete = complete
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = style.sheetMaskColor
    let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapAction(_:)))
    backgroundTap.cancelsTouchesInView = false
    view.addGestureRecognizer(backgroundTap)
    setupContainer()
  }

  @objc private func backgroundTapAction(_ gesture: UITapGestureRecognizer) {
    let point = gesture.location(in: view)
    guard container.frame.contains(point) == false else {
      return
    }
    dismiss(animated: true)
  }

  private func setupContainer() {
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = style.pageBackgroundColor
    container.layer.cornerRadius = 16
    container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    view.addSubview(container)
    NSLayoutConstraint.activate([
      container.leftAnchor.constraint(equalTo: view.leftAnchor),
      container.rightAnchor.constraint(equalTo: view.rightAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: heightRatio),
    ])

    let cancel = UIButton(type: .custom)
    let titleLabel = UILabel()
    for item in [cancel, done, titleLabel, textField, countLabel] {
      item.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(item)
    }

    cancel.setTitle(localizable("cancel"), for: .normal)
    cancel.setTitleColor(style.tertiaryTextColor, for: .normal)
    cancel.titleLabel?.font = .systemFont(ofSize: 16)
    cancel.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
    done.setTitle(localizable("confirm"), for: .normal)
    done.setTitleColor(style.primaryColor, for: .normal)
    done.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    done.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    titleLabel.text = sheetTitle
    titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
    titleLabel.textColor = style.titleTextColor
    titleLabel.textAlignment = .center

    textField.text = initialName
    textField.placeholder = localizable("conversation_group_name_placeholder")
    textField.delegate = self
    textField.font = .systemFont(ofSize: 16)
    textField.tintColor = style.primaryColor
    textField.backgroundColor = style.cardBackgroundColor
    textField.layer.cornerRadius = 8
    textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
    textField.leftViewMode = .always
    textField.clearButtonMode = .whileEditing
    textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

    countLabel.textAlignment = .right
    countLabel.font = .systemFont(ofSize: 12)
    countLabel.textColor = style.tertiaryTextColor
    updateCount()
    updateDoneState()

    NSLayoutConstraint.activate([
      cancel.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16),
      cancel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
      cancel.widthAnchor.constraint(equalToConstant: 60),
      cancel.heightAnchor.constraint(equalToConstant: 32),
      done.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -16),
      done.centerYAnchor.constraint(equalTo: cancel.centerYAnchor),
      done.widthAnchor.constraint(equalToConstant: 60),
      done.heightAnchor.constraint(equalToConstant: 32),
      titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: cancel.centerYAnchor),
      textField.topAnchor.constraint(equalTo: cancel.bottomAnchor, constant: 28),
      textField.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -16),
      textField.heightAnchor.constraint(equalToConstant: 52),
      countLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
      countLabel.rightAnchor.constraint(equalTo: textField.rightAnchor),
    ])
  }

  @objc private func cancelAction() {
    dismiss(animated: true)
  }

  @objc private func doneAction() {
    let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard name.isEmpty == false else {
      showToast(localizable("conversation_group_name_empty"))
      return
    }
    complete(name)
  }

  @objc private func textChanged() {
    if let text = textField.text, text.count > conversationGroupNameMaxLength {
      textField.text = String(text.prefix(conversationGroupNameMaxLength))
    }
    updateCount()
    updateDoneState()
  }

  private func updateCount() {
    countLabel.text = "\(textField.text?.count ?? 0)/\(conversationGroupNameMaxLength)"
  }

  private func updateDoneState() {
    let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    done.isEnabled = name.isEmpty == false
    done.setTitleColor(done.isEnabled ? style.primaryColor : style.primaryDisabledColor, for: .normal)
  }
}

final class NEConversationGroupNameController: NEConversationBaseViewController, UITextFieldDelegate {
  private let style: NEConversationGroupUIStyle
  private let complete: (String, NEConversationGroupNameController) -> Void
  private let textField = NESingleLineTextField()
  private let clearButton = UIButton(type: .custom)
  private let countLabel = UILabel()
  private let maxLength = conversationGroupNameMaxLength

  init(style: NEConversationGroupUIStyle = .normal, complete: @escaping (String, NEConversationGroupNameController) -> Void) {
    self.style = style
    self.complete = complete
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("conversation_group_create")
    view.backgroundColor = style.pageBackgroundColor
    navigationView.backgroundColor = style.navigationBackgroundColor
    navigationView.setMoreButtonTitle(localizable("confirm"), style.primaryColor)
    navigationView.setMoreButtonWidth(60)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(doneAction))
    setupInput()
    updateState()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textField.becomeFirstResponder()
  }

  private func setupInput() {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = style.contentBackgroundColor
    view.addSubview(container)

    for item in [textField, clearButton, countLabel] {
      item.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(item)
    }

    textField.placeholder = localizable("conversation_group_name_placeholder")
    textField.font = .systemFont(ofSize: 20)
    textField.textColor = style.titleTextColor
    textField.tintColor = style.primaryColor
    textField.delegate = self
    textField.clearButtonMode = .never
    textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

    if #available(iOS 13.0, *) {
      clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    } else {
      clearButton.setTitle("x", for: .normal)
      clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    clearButton.tintColor = style.tertiaryTextColor
    clearButton.setTitleColor(style.tertiaryTextColor, for: .normal)
    clearButton.addTarget(self, action: #selector(clearAction), for: .touchUpInside)

    countLabel.textAlignment = .right
    countLabel.font = .systemFont(ofSize: 14)
    countLabel.textColor = style.tertiaryTextColor

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      container.leftAnchor.constraint(equalTo: view.leftAnchor),
      container.rightAnchor.constraint(equalTo: view.rightAnchor),
      container.heightAnchor.constraint(equalToConstant: 132),
      textField.topAnchor.constraint(equalTo: container.topAnchor),
      textField.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: clearButton.leftAnchor, constant: -8),
      textField.heightAnchor.constraint(equalToConstant: 82),
      clearButton.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -16),
      clearButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
      clearButton.widthAnchor.constraint(equalToConstant: 32),
      clearButton.heightAnchor.constraint(equalToConstant: 32),
      countLabel.topAnchor.constraint(equalTo: textField.bottomAnchor),
      countLabel.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16),
      countLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -16),
      countLabel.heightAnchor.constraint(equalToConstant: 24),
    ])
  }

  @objc private func doneAction() {
    let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard name.isEmpty == false else {
      showToast(localizable("conversation_group_name_empty"))
      return
    }
    complete(name, self)
  }

  @objc private func clearAction() {
    textField.text = ""
    updateState()
  }

  @objc private func textChanged() {
    if let text = textField.text, text.count > maxLength {
      textField.text = String(text.prefix(maxLength))
    }
    updateState()
  }

  private func updateState() {
    let length = textField.text?.count ?? 0
    countLabel.text = "\(length)/\(maxLength)"
    clearButton.isHidden = length == 0
    let enabled = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    navigationView.moreButton.isEnabled = enabled
    navigationView.moreButton.setTitleColor(enabled ? style.primaryColor : style.primaryDisabledColor, for: .normal)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text, let textRange = Range(range, in: text) else {
      return true
    }
    let updated = text.replacingCharacters(in: textRange, with: string)
    return updated.count <= maxLength
  }
}

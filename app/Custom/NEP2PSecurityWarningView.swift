//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit
import NECommonUIKit
import UIKit

public protocol NEP2PSecurityWarningViewDelegate: NSObjectProtocol {
  func didClickRemoveButton()
}

open class NEP2PSecurityWarningView: UIView {
  let reportAdd = "https://yunxin.163.com/survey/report"
  public weak var delegate: NEP2PSecurityWarningViewDelegate?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(backView)
    NSLayoutConstraint.activate([
      backView.topAnchor.constraint(equalTo: topAnchor),
      backView.bottomAnchor.constraint(equalTo: bottomAnchor),
      backView.leftAnchor.constraint(equalTo: leftAnchor),
      backView.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }

  public lazy var backView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#FFF5E1")

    let errorImageView = UIImageView(image: coreLoader.loadImage("error"))
    errorImageView.translatesAutoresizingMaskIntoConstraints = false
    errorImageView.contentMode = .scaleAspectFit
    view.addSubview(errorImageView)
    NSLayoutConstraint.activate([
      errorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      errorImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      errorImageView.widthAnchor.constraint(equalToConstant: 16),
      errorImageView.heightAnchor.constraint(equalToConstant: 16),
    ])

    let removeButton = ExpandButton()
    removeButton.setImage(coreLoader.loadImage("remove"), for: .normal)
    removeButton.translatesAutoresizingMaskIntoConstraints = false
    removeButton.contentMode = .scaleToFill
    removeButton.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
    view.addSubview(removeButton)
    NSLayoutConstraint.activate([
      removeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      removeButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      removeButton.widthAnchor.constraint(equalToConstant: 16),
      removeButton.heightAnchor.constraint(equalToConstant: 16),
    ])

    view.addSubview(warningTextView)
    NSLayoutConstraint.activate([
      warningTextView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      warningTextView.heightAnchor.constraint(equalToConstant: 40),
      warningTextView.leftAnchor.constraint(equalTo: errorImageView.rightAnchor, constant: 0),
      warningTextView.rightAnchor.constraint(equalTo: removeButton.leftAnchor, constant: 4),
    ])

    view.bringSubviewToFront(removeButton)

    return view
  }()

  public lazy var warningTextView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textColor = UIColor(hexString: "#EB9718")
    textView.font = .systemFont(ofSize: 16)
    textView.textAlignment = .justified
    textView.backgroundColor = .clear
    textView.contentMode = .center
    textView.isEditable = false
    textView.delegate = self
    textView.accessibilityIdentifier = "id.securityWarning"

    let strAtt = NSMutableAttributedString(string: localizable("security_warning"))
    let linkAtt = NSAttributedString(string: localizable("click_to_report"), attributes: [NSAttributedString.Key.link: reportAdd])
    strAtt.append(linkAtt)
    textView.attributedText = strAtt
    return textView
  }()

  @objc func removeButtonAction() {
    delegate?.didClickRemoveButton()
  }
}

extension NEP2PSecurityWarningView: UITextViewDelegate {
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    let vc = NEWKWebViewController(url: URL.absoluteString, title: URL.absoluteString)
    neParentContainerViewController()?.navigationController?.pushViewController(vc, animated: true)
    return false
  }
}

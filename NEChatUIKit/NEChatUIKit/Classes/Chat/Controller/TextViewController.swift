//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

class TextViewController: ChatBaseViewController {
  let leftRightMargin: CGFloat = 24
  let textFont = UIFont.systemFont(ofSize: 24, weight: .regular)
  lazy var textView: CopyableTextView = {
    let textView = CopyableTextView()
    textView.isEditable = false
    textView.isSelectable = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.font = .systemFont(ofSize: 24, weight: .regular)
    return textView
  }()

  init(content: String) {
    super.init(nibName: nil, bundle: nil)
    textView.copyString = content
    let att = NEEmotionTool.getAttWithStr(str: content, font: textFont)
    textView.attributedText = att
    let line = String.calculateMaxLines(width: kScreenWidth - 2 * leftRightMargin,
                                        string: att.string,
                                        font: textFont)
    textView.textAlignment = line > 1 ? .justified : .center
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.isNavigationBarHidden = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    textView.addGestureRecognizer(tap)
    setupUI()
    contentSizeToFit()
  }

  @objc func viewTap() {
    UIMenuController.shared.setMenuVisible(false, animated: true)
    dismiss(animated: false)
  }

  func setupUI() {
    view.addSubview(textView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: leftRightMargin),
        textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -leftRightMargin),
      ])
    } else {
      NSLayoutConstraint.activate([
        textView.topAnchor.constraint(equalTo: view.topAnchor),
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: leftRightMargin),
        textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -leftRightMargin),
      ])
    }
  }

  // textView 垂直居中
  func contentSizeToFit() {
    guard !textView.text.isEmpty else {
      return
    }
    let textSize = String.getTextRectSize(textView.text, font: textFont, size: CGSize(width: kScreenWidth - leftRightMargin * 2, height: CGFloat.greatestFiniteMagnitude))
    let textViewHeight = kScreenHeight - kNavigationHeight - KStatusBarHeight
    if textSize.height <= textViewHeight {
      let offsetY = (textViewHeight - textSize.height) / 2
      let offset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
      textView.contentInset = offset
    }
  }
}

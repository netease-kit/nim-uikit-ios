
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit
@objc public protocol InputEmoticonTabViewDelegate: NSObjectProtocol {
  @objc optional func tabView(_ tabView: InputEmoticonTabView?, didSelectTabIndex index: Int)
}

open class InputEmoticonTabView: UIControl {
  open weak var delegate: InputEmoticonTabViewDelegate?
  private var tabs = [UIButton]()
  private var seps = [UIView]()
  private var className = "InputEmoticonTabView"

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setUpSubViews()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setUpSubViews() {
    addSubview(sendButton)

    NSLayoutConstraint.activate([
      sendButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
      sendButton.rightAnchor.constraint(equalTo: rightAnchor),
      sendButton.widthAnchor.constraint(equalToConstant: 60),
      sendButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  open func selectTabIndex(_ index: Int) {
    for i in 0 ..< tabs.count {
      let btn = tabs[i]
      btn.isSelected = i == index
    }
  }

  open func loadCatalogs(_ emoticonCatalogs: [NIMInputEmoticonCatalog]?) {
    tabs.forEach { btn in
      btn.removeFromSuperview()
    }
    seps.forEach { view in
      view.removeFromSuperview()
    }
    tabs.removeAll()
    seps.removeAll()

    guard let catalogs = emoticonCatalogs else {
      NELog.errorLog(className, desc: "❌emoticonCatalogs is nil")
      return
    }
    catalogs.forEach { catelog in
      let button = UIButton()
      button.addTarget(self, action: #selector(onTouchTab), for: .touchUpInside)
      button.sizeToFit()
      self.addSubview(button)
      tabs.append(button)

      let sep = UIView(frame: CGRect(x: 0, y: 0, width: 0.5, height: 35))
      sep.backgroundColor = UIColor.ne_borderColor
      seps.append(sep)
      self.addSubview(sep)
    }
  }

  @objc func onTouchTab(sender: UIButton) {
    if let index = tabs.firstIndex(of: sender) {
      selectTabIndex(index)
      delegate?.tabView?(self, didSelectTabIndex: index)
    }
  }

  // MARK: lazy method

  public lazy var sendButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(coreLoader.localizable("send"), for: .normal)
    button.titleLabel?.textColor = .white
    button.backgroundColor = UIColor.ne_blueText
    button.titleLabel?.font = DefaultTextFont(14)
    button.accessibilityIdentifier = "id.emojiSend"
    return button
  }()
}


// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

struct InputEmoticonTabItem {
  let normalIcon: UIImage
  let selectedIcon: UIImage
  let accessibilityValue: String
  let showsSelectionBackground: Bool

  init(normalIcon: UIImage,
       selectedIcon: UIImage,
       accessibilityValue: String,
       showsSelectionBackground: Bool = false) {
    self.normalIcon = normalIcon
    self.selectedIcon = selectedIcon
    self.accessibilityValue = accessibilityValue
    self.showsSelectionBackground = showsSelectionBackground
  }
}

private final class InputEmoticonTabButton: UIButton {
  let selectionBackgroundView = UIView()
  var showsSelectionBackground = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    selectionBackgroundView.isUserInteractionEnabled = false
    selectionBackgroundView.layer.cornerRadius = 7
    selectionBackgroundView.accessibilityIdentifier = "id.emoticonTabSelectionBackground"
    insertSubview(selectionBackgroundView, at: 0)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    sendSubviewToBack(selectionBackgroundView)
    selectionBackgroundView.frame = CGRect(
      x: (bounds.width - 34) / 2,
      y: (bounds.height - 34) / 2,
      width: 34,
      height: 34
    )
  }

  func updateSelectionBackground(accentColor: UIColor) {
    selectionBackgroundView.backgroundColor = isSelected && showsSelectionBackground
      ? accentColor.withAlphaComponent(0.14)
      : .clear
  }
}

@objc
public protocol InputEmoticonTabViewDelegate: NSObjectProtocol {
  @objc optional func tabView(_ tabView: InputEmoticonTabView?, didSelectTabIndex index: Int)
}

@objcMembers
open class InputEmoticonTabView: UIControl {
  open weak var delegate: InputEmoticonTabViewDelegate?

  private let tabWidth: CGFloat = 52
  private var tabs = [InputEmoticonTabButton]()
  private var separators = [UIView]()
  private var selectedIndex = 0

  public var accentColor: UIColor = .ne_normalTheme {
    didSet {
      sendButton.backgroundColor = accentColor
      updateTabPresentations()
    }
  }

  private lazy var scrollView: UIScrollView = {
    let view = UIScrollView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.scrollsToTop = false
    return view
  }()

  public lazy var sendButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(chatUIKitLoader.localizable("send"), for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = accentColor
    button.titleLabel?.font = DefaultTextFont(14)
    button.accessibilityIdentifier = "id.emojiSend"
    return button
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setUpSubViews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setUpSubViews()
  }

  private func setUpSubViews() {
    addSubview(scrollView)
    addSubview(sendButton)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
      scrollView.leftAnchor.constraint(equalTo: leftAnchor),
      scrollView.rightAnchor.constraint(equalTo: sendButton.leftAnchor),
      sendButton.topAnchor.constraint(equalTo: topAnchor),
      sendButton.bottomAnchor.constraint(equalTo: bottomAnchor),
      sendButton.rightAnchor.constraint(equalTo: rightAnchor),
      sendButton.widthAnchor.constraint(equalToConstant: 60),
    ])
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    for index in tabs.indices {
      tabs[index].frame = CGRect(x: CGFloat(index) * tabWidth, y: 0, width: tabWidth, height: bounds.height)
      separators[index].frame = CGRect(x: CGFloat(index + 1) * tabWidth - 0.5, y: 0, width: 0.5, height: bounds.height)
    }
    scrollView.contentSize = CGSize(width: CGFloat(tabs.count) * tabWidth, height: bounds.height)
    ensureSelectedTabVisible(animated: false)
  }

  open func selectTabIndex(_ index: Int) {
    guard tabs.indices.contains(index) else {
      return
    }
    selectedIndex = index
    for tabIndex in tabs.indices {
      tabs[tabIndex].isSelected = tabIndex == index
    }
    updateTabPresentations()
    ensureSelectedTabVisible(animated: true)
  }

  func loadItems(_ items: [InputEmoticonTabItem]) {
    tabs.forEach { $0.removeFromSuperview() }
    separators.forEach { $0.removeFromSuperview() }
    tabs.removeAll()
    separators.removeAll()

    for (index, item) in items.enumerated() {
      let button = InputEmoticonTabButton(frame: .zero)
      button.tag = index
      button.setImage(item.normalIcon, for: .normal)
      button.setImage(item.selectedIcon, for: .selected)
      button.showsSelectionBackground = item.showsSelectionBackground
      button.imageView?.contentMode = .scaleAspectFit
      button.addTarget(self, action: #selector(onTouchTab), for: .touchUpInside)
      button.accessibilityIdentifier = "id.emoticonTab"
      button.accessibilityValue = item.accessibilityValue
      scrollView.addSubview(button)
      tabs.append(button)

      let separator = UIView()
      separator.backgroundColor = UIColor.ne_borderColor
      scrollView.addSubview(separator)
      separators.append(separator)
    }

    selectedIndex = min(selectedIndex, max(items.count - 1, 0))
    setNeedsLayout()
    layoutIfNeeded()
    if !items.isEmpty {
      selectTabIndex(selectedIndex)
    }
  }

  open func loadCatalogs(_ emoticonCatalogs: [NIMInputEmoticonCatalog]?) {
    let items = (emoticonCatalogs ?? []).map { catalog in
      InputEmoticonTabItem(
        normalIcon: UIImage.ne_bundleImage(name: catalog.iconPressed ?? "") ?? UIImage(),
        selectedIcon: UIImage.ne_bundleImage(name: catalog.iconPressed ?? "") ?? UIImage(),
        accessibilityValue: catalog.catalogID ?? "",
        showsSelectionBackground: true
      )
    }
    loadItems(items)
  }

  func setSendButtonVisible(_ visible: Bool) {
    sendButton.isHidden = !visible
  }

  private func updateTabPresentations() {
    for button in tabs {
      button.updateSelectionBackground(accentColor: accentColor)
    }
  }

  private func ensureSelectedTabVisible(animated: Bool) {
    guard tabs.indices.contains(selectedIndex) else {
      return
    }
    scrollView.scrollRectToVisible(tabs[selectedIndex].frame, animated: animated)
  }

  @objc private func onTouchTab(sender: UIButton) {
    let index = sender.tag
    guard tabs.indices.contains(index) else {
      return
    }
    selectTabIndex(index)
    delegate?.tabView?(self, didSelectTabIndex: index)
  }
}

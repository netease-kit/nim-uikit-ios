
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objc
public protocol InputEmoticonContainerViewDelegate: NSObjectProtocol {
  func selectedEmoticon(emoticonID: String, emotCatalogID: String, description: String)
  func didPressSend(sender: UIButton)
  @objc optional func didSelectSticker(_ sticker: NIMInputSticker)
}

struct InputEmoticonPageMapping {
  let pageCounts: [Int]

  var totalPages: Int {
    pageCounts.reduce(0, +)
  }

  func globalIndex(sectionIndex: Int, localPage: Int) -> Int? {
    guard pageCounts.indices.contains(sectionIndex), pageCounts[sectionIndex] > 0 else {
      return nil
    }
    let boundedLocalPage = min(max(localPage, 0), pageCounts[sectionIndex] - 1)
    return pageCounts[..<sectionIndex].reduce(0, +) + boundedLocalPage
  }

  func location(globalIndex: Int) -> (sectionIndex: Int, localPage: Int)? {
    guard totalPages > 0 else {
      return nil
    }
    let boundedIndex = min(max(globalIndex, 0), totalPages - 1)
    var startIndex = 0
    for sectionIndex in pageCounts.indices {
      let endIndex = startIndex + pageCounts[sectionIndex]
      if boundedIndex < endIndex {
        return (sectionIndex, boundedIndex - startIndex)
      }
      startIndex = endIndex
    }
    return nil
  }
}

private final class InputEmoticonPageIndicatorView: UIView {
  private let dotSize: CGFloat = 5
  private let dotSpacing: CGFloat = 5
  private let inactiveColor = UIColor.ne_borderColor
  private let scrollView = UIScrollView()
  private var dots = [UIView]()
  private var currentPage = 0
  private var accentColor: UIColor = .ne_funTheme

  override init(frame: CGRect) {
    super.init(frame: frame)
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.scrollsToTop = false
    addSubview(scrollView)
    accessibilityIdentifier = "id.emoticonPageIndicator"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(pageCount: Int, currentPage: Int, accentColor: UIColor) {
    self.currentPage = min(max(currentPage, 0), max(pageCount - 1, 0))
    self.accentColor = accentColor
    if dots.count != pageCount {
      dots.forEach { $0.removeFromSuperview() }
      dots = (0 ..< pageCount).map { _ in
        let dot = UIView()
        dot.layer.cornerRadius = dotSize / 2
        dot.isAccessibilityElement = false
        scrollView.addSubview(dot)
        return dot
      }
    }
    accessibilityValue = pageCount > 0 ? "\(self.currentPage + 1)/\(pageCount)" : nil
    setNeedsLayout()
    layoutIfNeeded()
    ensureCurrentDotVisible()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds
    let contentWidth = CGFloat(dots.count) * dotSize + CGFloat(max(dots.count - 1, 0)) * dotSpacing
    let startX = contentWidth < bounds.width ? (bounds.width - contentWidth) / 2 : 0
    for index in dots.indices {
      dots[index].frame = CGRect(
        x: startX + CGFloat(index) * (dotSize + dotSpacing),
        y: (bounds.height - dotSize) / 2,
        width: dotSize,
        height: dotSize
      )
      dots[index].backgroundColor = index == currentPage ? accentColor : inactiveColor
    }
    scrollView.contentSize = CGSize(width: max(bounds.width, contentWidth), height: bounds.height)
  }

  private func ensureCurrentDotVisible() {
    guard dots.indices.contains(currentPage) else {
      return
    }
    scrollView.scrollRectToVisible(dots[currentPage].frame.insetBy(dx: -dotSpacing, dy: 0), animated: false)
  }
}

private final class InputStickerButton: UIButton {
  var packageID = ""
  var sticker: NIMInputSticker?
}

private enum InputEmoticonSectionContent {
  case emoji(NIMInputEmoticonCatalog)
  case sticker(NIMInputStickerPackage)
}

private struct InputEmoticonSection {
  let id: String
  let title: String?
  let normalIcon: UIImage
  let selectedIcon: UIImage
  let pageCount: Int
  let content: InputEmoticonSectionContent
}

private struct InputEmoticonSelection {
  let sectionID: String
  let localPage: Int
}

@objcMembers
open class InputEmoticonContainerView: UIView {
  private let classTag = "InputEmoticonContainerView"
  private let stickerPageCapacity = 8
  private let imageCache = NSCache<NSURL, UIImage>()
  private var sections = [InputEmoticonSection]()
  private var pageMapping = InputEmoticonPageMapping(pageCounts: [])
  private var selection: InputEmoticonSelection?
  private var lastLayoutWidth: CGFloat = 0
  private var contentTopConstraint: NSLayoutConstraint?
  private var contentBottomConstraint: NSLayoutConstraint?

  public weak var delegate: InputEmoticonContainerViewDelegate?

  public var accentColor: UIColor = .ne_funTheme {
    didSet {
      tabView.accentColor = accentColor
      renderSelection()
    }
  }

  var contentVerticalOffset: CGFloat = 0 {
    didSet {
      contentTopConstraint?.constant = contentVerticalOffset
      contentBottomConstraint?.constant = contentVerticalOffset
      clipsToBounds = contentVerticalOffset >= 0
    }
  }

  var selectedSectionID: String? {
    selection?.sectionID
  }

  var selectedLocalPage: Int {
    selection?.localPage ?? 0
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setUpSubViews()
    loadEmojiData()
  }

  public init(frame: CGRect, accentColor: UIColor) {
    self.accentColor = accentColor
    super.init(frame: frame)
    setUpSubViews()
    loadEmojiData()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setUpSubViews()
    loadEmojiData()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard bounds.width > 0, abs(bounds.width - lastLayoutWidth) > 0.5 else {
      return
    }
    lastLayoutWidth = bounds.width
    rebuildSections(preserving: selection)
  }

  private func setUpSubViews() {
    clipsToBounds = true
    addSubview(emoticonPageView)
    addSubview(pageIndicatorView)
    addSubview(tabView)

    let contentTopConstraint = emoticonPageView.topAnchor.constraint(equalTo: topAnchor)
    let contentBottomConstraint = tabView.bottomAnchor.constraint(equalTo: bottomAnchor)
    self.contentTopConstraint = contentTopConstraint
    self.contentBottomConstraint = contentBottomConstraint

    NSLayoutConstraint.activate([
      contentTopConstraint,
      emoticonPageView.rightAnchor.constraint(equalTo: rightAnchor),
      emoticonPageView.leftAnchor.constraint(equalTo: leftAnchor),
      emoticonPageView.heightAnchor.constraint(equalToConstant: 159),
      pageIndicatorView.topAnchor.constraint(equalTo: emoticonPageView.bottomAnchor),
      pageIndicatorView.rightAnchor.constraint(equalTo: rightAnchor),
      pageIndicatorView.leftAnchor.constraint(equalTo: leftAnchor),
      pageIndicatorView.heightAnchor.constraint(equalToConstant: 6),
      tabView.topAnchor.constraint(equalTo: pageIndicatorView.bottomAnchor),
      contentBottomConstraint,
      tabView.rightAnchor.constraint(equalTo: rightAnchor),
      tabView.leftAnchor.constraint(equalTo: leftAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 35),
    ])

    tabView.accentColor = accentColor
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(stickerPackagesDidChange),
      name: NIMInputStickerNotification.packagesDidChange,
      object: NIMInputEmoticonManager.shared
    )
    layoutIfNeeded()
  }

  private func loadEmojiData() {
    lastLayoutWidth = bounds.width
    rebuildSections(preserving: nil)
  }

  @objc private func stickerPackagesDidChange() {
    rebuildSections(preserving: selection)
  }

  private func rebuildSections(preserving previousSelection: InputEmoticonSelection?) {
    guard let defaultCatalog = loadDefaultCatalog() else {
      sections = []
      pageMapping = InputEmoticonPageMapping(pageCounts: [])
      selection = nil
      tabView.loadItems([])
      pageIndicatorView.update(pageCount: 0, currentPage: 0, accentColor: accentColor)
      emoticonPageView.reloadData(currentPage: 0)
      return
    }

    let defaultSection = InputEmoticonSection(
      id: defaultCatalog.catalogID ?? NIMKit_EmojiCatalog,
      title: defaultCatalog.title,
      normalIcon: UIImage.ne_bundleImage(name: defaultCatalog.icon ?? "") ?? UIImage(),
      selectedIcon: UIImage.ne_bundleImage(name: defaultCatalog.iconPressed ?? "") ?? UIImage(),
      pageCount: defaultCatalog.pagesCount,
      content: .emoji(defaultCatalog)
    )
    var updatedSections = [defaultSection]
    for package in NIMInputEmoticonManager.shared.stickerPackages() {
      let pageCount = (package.stickers.count + stickerPageCapacity - 1) / stickerPageCapacity
      guard pageCount > 0 else {
        continue
      }
      updatedSections.append(InputEmoticonSection(
        id: package.packageID,
        title: package.title,
        normalIcon: package.normalIcon,
        selectedIcon: package.selectedIcon,
        pageCount: pageCount,
        content: .sticker(package)
      ))
    }

    sections = updatedSections
    pageMapping = InputEmoticonPageMapping(pageCounts: sections.map(\.pageCount))
    if let previousSelection,
       let section = sections.first(where: { $0.id == previousSelection.sectionID }) {
      selection = InputEmoticonSelection(
        sectionID: section.id,
        localPage: min(previousSelection.localPage, section.pageCount - 1)
      )
    } else {
      selection = InputEmoticonSelection(sectionID: defaultSection.id, localPage: 0)
    }

    tabView.loadItems(sections.map { section in
      InputEmoticonTabItem(
        normalIcon: section.selectedIcon,
        selectedIcon: section.selectedIcon,
        accessibilityValue: section.title ?? section.id,
        showsSelectionBackground: true
      )
    })
    let targetPage = globalPage(for: selection) ?? 0
    emoticonPageView.reloadData(currentPage: targetPage)
    renderSelection()
  }

  private func loadDefaultCatalog() -> NIMInputEmoticonCatalog? {
    guard let emoticonCatalog = NIMInputEmoticonManager.shared
      .emoticonCatalog(catalogID: NIMKit_EmojiCatalog) else {
      NEALog.errorLog(classTag, desc: "default emoji catalog is nil")
      return nil
    }
    let layoutWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    let layout = NIMInputEmoticonLayout(width: layoutWidth)
    emoticonCatalog.layout = layout
    emoticonCatalog.pagesCount = numberOfPagesWithEmoticon(emoticonCatalog: emoticonCatalog)
    return emoticonCatalog.pagesCount > 0 ? emoticonCatalog : nil
  }

  func numberOfPagesWithEmoticon(emoticonCatalog: NIMInputEmoticonCatalog?) -> NSInteger {
    guard let emotionsCount = emoticonCatalog?.emoticons?.count,
          let layoutCount = emoticonCatalog?.layout?.itemCountInPage,
          layoutCount > 0 else {
      NEALog.errorLog(classTag, desc: "emoji layout count is invalid")
      return 0
    }
    return (emotionsCount + layoutCount - 1) / layoutCount
  }

  func resetToFirstEmojiPage() {
    guard !sections.isEmpty else {
      return
    }
    emoticonPageView.scrollToPage(page: 0, animated: false)
  }

  private func globalPage(for selection: InputEmoticonSelection?) -> Int? {
    guard let selection,
          let sectionIndex = sections.firstIndex(where: { $0.id == selection.sectionID }) else {
      return nil
    }
    return pageMapping.globalIndex(sectionIndex: sectionIndex, localPage: selection.localPage)
  }

  private func setSelection(sectionIndex: Int, localPage: Int, scroll: Bool) {
    guard sections.indices.contains(sectionIndex) else {
      return
    }
    let section = sections[sectionIndex]
    selection = InputEmoticonSelection(
      sectionID: section.id,
      localPage: min(max(localPage, 0), section.pageCount - 1)
    )
    renderSelection()
    if scroll, let targetPage = globalPage(for: selection) {
      emoticonPageView.scrollToPage(page: targetPage)
    }
  }

  private func renderSelection() {
    guard let selection,
          let sectionIndex = sections.firstIndex(where: { $0.id == selection.sectionID }) else {
      return
    }
    let section = sections[sectionIndex]
    tabView.selectTabIndex(sectionIndex)
    switch section.content {
    case .emoji:
      tabView.setSendButtonVisible(true)
    case .sticker:
      tabView.setSendButtonVisible(false)
    }
    pageIndicatorView.update(
      pageCount: section.pageCount,
      currentPage: selection.localPage,
      accentColor: accentColor
    )
  }

  private func emojiPageView(emoticon: NIMInputEmoticonCatalog, page: Int) -> UIView {
    let pageView = UIView()
    guard let layout = emoticon.layout,
          let emotions = emoticon.emoticons,
          layout.columes > 0 else {
      return pageView
    }

    let startX = (layout.cellWidth - layout.imageWidth) / 2 + CGFloat(NIMKit_EmojiLeftMargin)
    let startY = (layout.cellHeight - layout.imageHeight) / 2 + CGFloat(NIMKit_EmojiTopMargin)
    let begin = page * layout.itemCountInPage
    let end = min(begin + layout.itemCountInPage, emotions.count)
    guard begin < end else {
      return pageView
    }

    for (indexInPage, itemIndex) in (begin ..< end).enumerated() {
      guard let catalogID = emoticon.catalogID else {
        continue
      }
      let button = NIMInputEmoticonButton.iconButtonWithData(
        data: emotions[itemIndex],
        catalogID: catalogID,
        delegate: self
      )
      let row = indexInPage / layout.columes
      let column = indexInPage % layout.columes
      button.frame = CGRect(
        x: CGFloat(column) * layout.cellWidth + startX,
        y: CGFloat(row) * layout.cellHeight + startY,
        width: layout.imageWidth,
        height: layout.imageHeight
      )
      pageView.addSubview(button)
    }

    if emoticon.catalogID == NIMKit_EmojiCatalog {
      let deleteIndex = end - begin
      let row = deleteIndex / layout.columes
      let column = deleteIndex % layout.columes
      let deleteButton = NIMInputEmoticonButton()
      deleteButton.isExclusiveTouch = true
      deleteButton.contentMode = .center
      deleteButton.delegate = self
      deleteButton.setImage(UIImage.ne_imageNamed(name: "emoji_del_normal"), for: .normal)
      deleteButton.setImage(UIImage.ne_imageNamed(name: "emoji_del_pressed"), for: .highlighted)
      deleteButton.addTarget(self, action: #selector(onDeleteSelected), for: .touchUpInside)
      deleteButton.accessibilityIdentifier = "id.emojiDelete"
      deleteButton.frame = CGRect(
        x: CGFloat(column) * layout.cellWidth + startX,
        y: CGFloat(row) * layout.cellHeight + startY,
        width: NIMKit_DeleteIconWidth,
        height: NIMKit_DeleteIconHeight
      )
      pageView.addSubview(deleteButton)
    }
    return pageView
  }

  private func stickerPageView(package: NIMInputStickerPackage, page: Int) -> UIView {
    let pageView = UIView()
    let begin = page * stickerPageCapacity
    let end = min(begin + stickerPageCapacity, package.stickers.count)
    guard begin < end else {
      return pageView
    }

    let contentWidth = max(emoticonPageView.bounds.width, bounds.width)
    let cellWidth = (contentWidth - 16) / 4
    let cellHeight = max(emoticonPageView.bounds.height, 159) / 2
    let buttonLength = min(70, min(cellWidth, cellHeight) - 8)
    for (indexInPage, itemIndex) in (begin ..< end).enumerated() {
      let sticker = package.stickers[itemIndex]
      let row = indexInPage / 4
      let column = indexInPage % 4
      let button = InputStickerButton(type: .custom)
      button.packageID = package.packageID
      button.sticker = sticker
      button.frame = CGRect(
        x: 8 + CGFloat(column) * cellWidth + (cellWidth - buttonLength) / 2,
        y: CGFloat(row) * cellHeight + (cellHeight - buttonLength) / 2,
        width: buttonLength,
        height: buttonLength
      )
      button.imageView?.contentMode = .scaleAspectFit
      button.accessibilityIdentifier = "id.sticker.\(package.packageID).\(sticker.stickerID)"
      button.accessibilityValue = sticker.stickerID
      button.addTarget(self, action: #selector(onStickerSelected), for: .touchUpInside)
      let cacheKey = sticker.fileURL as NSURL
      let image = imageCache.object(forKey: cacheKey) ?? UIImage(contentsOfFile: sticker.fileURL.path)
      if let image {
        imageCache.setObject(image, forKey: cacheKey)
        button.setImage(image, for: .normal)
      }
      pageView.addSubview(button)
    }
    return pageView
  }

  @objc private func onDeleteSelected() {
    delegate?.selectedEmoticon(emoticonID: "", emotCatalogID: "", description: "")
  }

  @objc private func onStickerSelected(sender: InputStickerButton) {
    guard let displayedSticker = sender.sticker,
          let package = NIMInputEmoticonManager.shared.stickerPackages()
          .first(where: { $0.packageID == sender.packageID }),
          let currentSticker = package.stickers.first(where: {
            $0.stickerID == displayedSticker.stickerID && $0.fileURL == displayedSticker.fileURL
          }) else {
      return
    }
    delegate?.didSelectSticker?(currentSticker)
  }

  @objc private func didPressSend(sender: UIButton) {
    delegate?.didPressSend(sender: sender)
  }

  private lazy var emoticonPageView: EmojiPageView = {
    let pageView = EmojiPageView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 159))
    pageView.translatesAutoresizingMaskIntoConstraints = false
    pageView.dataSource = self
    pageView.pageViewDelegate = self
    return pageView
  }()

  private lazy var pageIndicatorView: InputEmoticonPageIndicatorView = {
    let view = InputEmoticonPageIndicatorView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var tabView: InputEmoticonTabView = {
    let view = InputEmoticonTabView(frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.delegate = self
    view.sendButton.addTarget(self, action: #selector(didPressSend), for: .touchUpInside)
    return view
  }()
}

extension InputEmoticonContainerView: EmojiPageViewDelegate, EmojiPageViewDataSource {
  open func numberOfPages(pageView: EmojiPageView?) -> NSInteger {
    pageMapping.totalPages
  }

  open func pageView(pageView: EmojiPageView?, index: NSInteger) -> UIView {
    guard let location = pageMapping.location(globalIndex: index),
          sections.indices.contains(location.sectionIndex) else {
      return UIView()
    }
    switch sections[location.sectionIndex].content {
    case let .emoji(catalog):
      return emojiPageView(emoticon: catalog, page: location.localPage)
    case let .sticker(package):
      return stickerPageView(package: package, page: location.localPage)
    }
  }

  open func needScrollAnimation() -> Bool {
    true
  }

  open func pageViewDidScroll(_ pageView: EmojiPageView?) {}

  open func pageViewScrollEnd(_ pageView: EmojiPageView?, currentIndex: Int, totolPages: Int) {
    guard let location = pageMapping.location(globalIndex: currentIndex) else {
      return
    }
    setSelection(sectionIndex: location.sectionIndex, localPage: location.localPage, scroll: false)
  }
}

extension InputEmoticonContainerView: InputEmoticonTabViewDelegate {
  open func tabView(_ tabView: InputEmoticonTabView?, didSelectTabIndex index: Int) {
    setSelection(sectionIndex: index, localPage: 0, scroll: true)
  }
}

extension InputEmoticonContainerView: NIMInputEmoticonButtonDelegate {
  open func selectedEmoticon(emotion: NIMInputEmoticon, catalogID: String) {
    guard let emotionID = emotion.emoticonID else {
      NEALog.errorLog(classTag, desc: "emoticonID is nil")
      return
    }
    delegate?.selectedEmoticon(
      emoticonID: emotionID,
      emotCatalogID: catalogID,
      description: emotion.type == .unicode ? (emotion.unicode ?? "") : (emotion.tag ?? "")
    )
  }
}

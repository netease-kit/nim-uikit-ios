// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

private let operationItemWidth: CGFloat = 54
private let operationVisualItemWidth: CGFloat = 50
private let operationItemSpacing: CGFloat = 2
private let operationHorizontalPadding: CGFloat = 4
private let reactionPanelItemSize: CGFloat = 36
private let reactionPanelImageSize: CGFloat = 22
// Five operation cells plus the shared 4pt content inset on each side.
// Keeping this width in sync with the operation grid makes the seven-cell
// reaction rail share the same left and right content edges.

@objc
public protocol MessageOperationViewDelegate: NSObjectProtocol {
  func didSelectedItem(item: OperationItem)
}

/// Message operation popup matching the QChat interaction surface.
///
/// Reactions occupy a compact 50pt strip above the ordinary operation grid.
/// Expanding replaces the operation grid with the complete emoji collection
/// inside the same popup instead of presenting a second controller.
@objcMembers
open class MessageOperationView: UIView,
  UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  public weak var delegate: MessageOperationViewDelegate?

  public var items = [OperationItem]() {
    didSet { operationCollection.reloadData() }
  }

  public private(set) var showEmoji = false
  public var showMoreButton = true {
    didSet { moreButton.isHidden = !showMoreButton }
  }

  public var oldFrameHeight: CGFloat = 0
  /// Width of the ordinary operation menu, restored after the reaction grid
  /// is collapsed. The expanded grid uses its own compact seven-column width.
  public var oldFrameWidth: CGFloat = 0
  public var viewUnderMessage = true
  /// Visible message-list bounds in the operation view's superview
  /// coordinates. ChatViewController supplies this so a popup opened near the
  /// top or bottom of the list remains fully on-screen.
  public var visibleFrame: CGRect?
  public private(set) var isShowingAllEmoji = false

  @nonobjc public var onSelectReaction: ((Int) -> Void)?

  private var quickReactionItems = [MessageReactionEmoji]()
  private var allReactionItems = [MessageReactionEmoji]()
  private var operationTopToEmoji: NSLayoutConstraint?
  private var operationTopToView: NSLayoutConstraint?
  private var isClampingFrame = false

  public lazy var emojiBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public lazy var moreButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "reaction_more_emoji"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "reaction_less_emoji"), for: .selected)
    button.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
    button.backgroundColor = .white
    button.accessibilityIdentifier = "id.messageReaction.more"
    return button
  }()

  public lazy var emojiCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.itemSize = CGSize(width: reactionPanelItemSize, height: reactionPanelItemSize)
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    collection.register(
      MessageReactionEmojiCell.self,
      forCellWithReuseIdentifier: MessageReactionEmojiCell.reuseIdentifier
    )
    collection.accessibilityIdentifier = "id.messageReaction.quickCollection"
    return collection
  }()

  public lazy var emojiAllCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.itemSize = CGSize(width: reactionPanelItemSize, height: reactionPanelItemSize)
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    collection.register(
      MessageReactionEmojiCell.self,
      forCellWithReuseIdentifier: MessageReactionEmojiCell.reuseIdentifier
    )
    collection.accessibilityIdentifier = "id.messageReaction.allCollection"
    return collection
  }()

  public lazy var operationCollection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    // Keep the original operation grid geometry so adding the reaction strip
    // does not change the number of action buttons shown on each row.
    layout.itemSize = CGSize(width: operationVisualItemWidth, height: 56)
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = operationItemSpacing
    layout.scrollDirection = .vertical
    let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .white
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.dataSource = self
    collection.delegate = self
    collection.isUserInteractionEnabled = true
    collection.register(
      OperationCell.self,
      forCellWithReuseIdentifier: "\(OperationCell.self)"
    )
    collection.accessibilityIdentifier = "id.messageOperation.collection"
    return collection
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    backgroundColor = .white
    layer.cornerRadius = 7
    layer.shadowOffset = CGSize(width: 0, height: 4)
    layer.shadowColor = UIColor.ne_operationBorderColor.cgColor
    layer.shadowOpacity = 0.25
    layer.shadowRadius = 7

    emojiBackView.addSubview(emojiCollection)
    NSLayoutConstraint.activate([
      emojiCollection.leftAnchor.constraint(equalTo: emojiBackView.leftAnchor, constant: operationHorizontalPadding),
      emojiCollection.rightAnchor.constraint(equalTo: emojiBackView.rightAnchor, constant: -operationHorizontalPadding),
      emojiCollection.centerYAnchor.constraint(equalTo: emojiBackView.centerYAnchor),
      emojiCollection.heightAnchor.constraint(equalToConstant: reactionPanelItemSize),
    ])

    emojiBackView.addSubview(moreButton)
    moreButton.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
    NSLayoutConstraint.activate([
      moreButton.rightAnchor.constraint(equalTo: emojiBackView.rightAnchor, constant: -operationHorizontalPadding),
      moreButton.centerYAnchor.constraint(equalTo: emojiBackView.centerYAnchor),
      moreButton.widthAnchor.constraint(equalToConstant: reactionPanelItemSize),
      moreButton.heightAnchor.constraint(equalToConstant: reactionPanelItemSize),
    ])

    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = UIColor(hexString: "#E4E9F2")
    emojiBackView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leadingAnchor.constraint(equalTo: emojiBackView.leadingAnchor, constant: 16),
      line.trailingAnchor.constraint(equalTo: emojiBackView.trailingAnchor, constant: -16),
      line.bottomAnchor.constraint(equalTo: emojiBackView.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    addSubview(emojiBackView)
    NSLayoutConstraint.activate([
      emojiBackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      emojiBackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      emojiBackView.topAnchor.constraint(equalTo: topAnchor),
      emojiBackView.heightAnchor.constraint(equalToConstant: 50),
    ])

    addSubview(operationCollection)
    NSLayoutConstraint.activate([
      operationCollection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: operationHorizontalPadding),
      operationCollection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -operationHorizontalPadding),
      operationCollection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])
    operationTopToEmoji = operationCollection.topAnchor.constraint(
      equalTo: emojiBackView.bottomAnchor,
      constant: 8
    )
    operationTopToView = operationCollection.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    operationTopToView?.isActive = true
    emojiBackView.isHidden = true
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard !isClampingFrame else { return }
    isClampingFrame = true
    clampFrameToVisibleArea()
    isClampingFrame = false
  }

  @nonobjc
  open func configureReactions(provider: MessageReactionEmojiProvider?,
                               quickIndexes: [Int],
                               showEmoji: Bool,
                               showMoreButton: Bool) {
    self.showEmoji = showEmoji && provider != nil
    self.showMoreButton = showMoreButton
    emojiBackView.isHidden = !self.showEmoji
    moreButton.isHidden = !self.showEmoji || !showMoreButton
    moreButton.isSelected = false
    isShowingAllEmoji = false

    if let provider, self.showEmoji {
      let all = provider.allEmojis()
      // Long-press menus reserve the trailing slot for the expand control;
      // message-side panels hide that control and can show the seventh item.
      let visibleIndexes = showMoreButton
        ? Array(quickIndexes.prefix(6))
        : quickIndexes
      quickReactionItems = visibleIndexes.compactMap { index in
        all.first(where: { $0.index == index })
      }
      allReactionItems = all
    } else {
      quickReactionItems.removeAll()
      allReactionItems.removeAll()
    }
    emojiCollection.reloadData()
    emojiAllCollection.reloadData()
  }

  open func showAllEmoji() {
    guard showEmoji else { return }
    if oldFrameWidth <= 0 { oldFrameWidth = frame.width }
    // Preserve the operation menu width. The reaction collection wraps at
    // that width, so expanding the emoji grid never changes the popup edges.
    let expandedWidth = oldFrameWidth > 0 ? oldFrameWidth : frame.width
    if frame.width != expandedWidth {
      let oldMaxX = frame.maxX
      let keepTrailingEdge = frame.midX > UIScreen.main.bounds.width / 2
      frame.size.width = expandedWidth
      if keepTrailingEdge { frame.origin.x = oldMaxX - expandedWidth }
    }
    updateReactionLayoutSpacing()
    operationCollection.isHidden = true
    isShowingAllEmoji = true
    if emojiAllCollection.superview == nil {
      addSubview(emojiAllCollection)
      NSLayoutConstraint.activate([
        emojiAllCollection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: operationHorizontalPadding),
        emojiAllCollection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -operationHorizontalPadding),
        emojiAllCollection.topAnchor.constraint(equalTo: emojiBackView.bottomAnchor),
        emojiAllCollection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
      ])
    }
    emojiAllCollection.isHidden = false
    // The operation view is reused between messages. Reset both before and
    // after layout: reloadData can restore the previous offset during the first
    // layout pass when the collection was previously scrolled.
    resetAllEmojiCollectionToTop()

    let expandedHeight: CGFloat = 310
    if !viewUnderMessage, showMoreButton {
      frame.origin.y -= max(0, expandedHeight - frame.height)
    }
    frame.size = CGSize(width: frame.width, height: expandedHeight)
    layoutIfNeeded()
    clampFrameToVisibleArea()
  }

  private func resetAllEmojiCollectionToTop() {
    layoutIfNeeded()
    emojiAllCollection.layoutIfNeeded()
    emojiAllCollection.setContentOffset(.zero, animated: false)
    DispatchQueue.main.async { [weak self] in
      guard let self, !self.emojiAllCollection.isHidden else { return }
      self.layoutIfNeeded()
      self.emojiAllCollection.layoutIfNeeded()
      self.emojiAllCollection.setContentOffset(
        CGPoint(x: 0, y: -self.emojiAllCollection.adjustedContentInset.top),
        animated: false
      )
    }
  }

  private func reactionInteritemSpacing() -> CGFloat {
    let contentWidth = max(0, frame.width - operationHorizontalPadding * 2)
    let requiredItemWidth = reactionPanelItemSize * 7
    return max(0, (contentWidth - requiredItemWidth) / 6)
  }

  private func updateReactionLayoutSpacing() {
    let spacing = reactionInteritemSpacing()
    guard let layout = emojiCollection.collectionViewLayout as? UICollectionViewFlowLayout else {
      return
    }
    layout.minimumInteritemSpacing = spacing
    layout.invalidateLayout()
    if let allLayout = emojiAllCollection.collectionViewLayout as? UICollectionViewFlowLayout {
      allLayout.minimumInteritemSpacing = spacing
      allLayout.invalidateLayout()
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView === operationCollection {
      return CGSize(width: operationVisualItemWidth, height: 56)
    }
    return CGSize(width: reactionPanelItemSize, height: reactionPanelItemSize)
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    if collectionView === operationCollection { return operationItemSpacing }
    return reactionInteritemSpacing()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           insetForSectionAt section: Int) -> UIEdgeInsets {
    guard collectionView === operationCollection else { return .zero }
    // Keep the first operation on the same five-column grid origin even when
    // this message type exposes only a small subset of actions.
    let columnCount = 5
    let occupiedWidth = CGFloat(columnCount) * operationVisualItemWidth +
      CGFloat(max(0, columnCount - 1)) * operationItemSpacing
    let inset = max(0, (collectionView.bounds.width - occupiedWidth) / 2)
    return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
  }

  open func showOperation() {
    updateReactionLayoutSpacing()
    emojiAllCollection.isHidden = true
    operationCollection.isHidden = false
    isShowingAllEmoji = false
    operationTopToEmoji?.isActive = false
    operationTopToView?.isActive = false
    if showEmoji {
      operationTopToEmoji?.isActive = true
    } else {
      operationTopToView?.isActive = true
    }
    clampFrameToVisibleArea()
  }

  /// Keep the popup inside the message-list viewport after any height or
  /// layout change. The fallback uses the hosting view's safe area when a
  /// controller has not supplied a table-view viewport.
  private func clampFrameToVisibleArea() {
    guard let host = superview else { return }
    let area = visibleFrame ?? host.bounds.inset(by: UIEdgeInsets(
      top: max(0, NEConstant.navigationAndStatusHeight),
      left: 0,
      bottom: max(0, host.safeAreaInsets.bottom),
      right: 0
    ))
    let top = max(0, area.minY)
    let bottom = min(host.bounds.height, area.maxY)
    let maxY = max(top, bottom - frame.height)
    frame.origin.y = min(max(frame.origin.y, top), maxY)
  }

  open func moreButtonAction() {
    moreButton.isSelected.toggle()
    if moreButton.isSelected {
      showAllEmoji()
    } else {
      let targetWidth = oldFrameWidth > 0 ? oldFrameWidth : frame.width
      if frame.width < targetWidth {
        let currentMaxX = frame.maxX
        let keepTrailingEdge = frame.midX > UIScreen.main.bounds.width / 2
        frame.size.width = targetWidth
        if keepTrailingEdge { frame.origin.x = currentMaxX - targetWidth }
      }
      if !viewUnderMessage {
        frame.origin.y += max(0, 310 - oldFrameHeight)
      }
      frame.size = CGSize(width: frame.width, height: oldFrameHeight)
      showOperation()
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    if collectionView === emojiAllCollection { return allReactionItems.count }
    if collectionView === emojiCollection { return quickReactionItems.count }
    return items.count
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if collectionView === emojiCollection || collectionView === emojiAllCollection {
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: MessageReactionEmojiCell.reuseIdentifier,
        for: indexPath
      ) as? MessageReactionEmojiCell
      let values = collectionView === emojiCollection ? quickReactionItems : allReactionItems
      if indexPath.item < values.count {
        let emoji = values[indexPath.item]
        cell?.imageView.image = UIImage.ne_imageNamed(name: emoji.resourceName)
        cell?.accessibilityLabel = emoji.accessibilityDescription
        cell?.accessibilityIdentifier = "id.messageReaction.emoji.\(emoji.index)"
      }
      return cell ?? UICollectionViewCell()
    }

    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(OperationCell.self)",
      for: indexPath
    ) as? OperationCell
    if indexPath.item < items.count { cell?.model = items[indexPath.item] }
    return cell ?? UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    isHidden = true
    if collectionView === emojiCollection || collectionView === emojiAllCollection {
      let values = collectionView === emojiCollection ? quickReactionItems : allReactionItems
      guard indexPath.item < values.count else { return }
      onSelectReaction?(values[indexPath.item].index)
    } else {
      guard indexPath.item < items.count else { return }
      delegate?.didSelectedItem(item: items[indexPath.item])
    }
  }
}

private final class MessageReactionEmojiCell: UICollectionViewCell {
  static let reuseIdentifier = "MessageReactionEmojiCell"
  let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 13
    imageView.contentMode = .scaleAspectFit
    contentView.addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      imageView.widthAnchor.constraint(equalToConstant: reactionPanelImageSize),
      imageView.heightAnchor.constraint(equalToConstant: reactionPanelImageSize),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
}

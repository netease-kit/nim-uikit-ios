
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol NEMoreViewDelegate: NSObjectProtocol {
  func moreViewDidSelectMoreCell(moreView: NEChatMoreActionView, cell: NEInputMoreCell)
}

@objcMembers
open class NEChatMoreActionView: UIView {
  private var sectionCount: Int = 1
  private var itemsInSection: Int = 4
  // 默认行数
  private var rowCount: Int = 1
  // 流水布局
  public var moreFlowLayout: UICollectionViewFlowLayout?

  private var data: [NEMoreItemModel]?

  private var itemIndexs: [IndexPath: NSNumber]?

  public weak var delegate: NEMoreViewDelegate?

  /// 更多面板列表
  lazy var collcetionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 0, left: NEMoreView_Section_Padding, bottom: 0, right: NEMoreView_Section_Padding)
    self.moreFlowLayout = layout
    let collcetionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collcetionView.backgroundColor = UIColor.ne_backgroundColor
    collcetionView.translatesAutoresizingMaskIntoConstraints = false
    collcetionView.dataSource = self
    collcetionView.delegate = self
    collcetionView.isUserInteractionEnabled = true
    collcetionView.isPagingEnabled = true
    collcetionView.showsHorizontalScrollIndicator = false
    collcetionView.showsVerticalScrollIndicator = false
    collcetionView.alwaysBounceHorizontal = true
    collcetionView.register(
      NEInputMoreCell.self,
      forCellWithReuseIdentifier: NEMoreCell_ReuseId
    )
    return collcetionView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(collcetionView)
    setupConstraints()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configData(data: [NEMoreItemModel]) {
    self.data = data
    rowCount = (data.count > NEMoreView_Column_Count) ? 2 : 1
    itemsInSection = NEMoreView_Column_Count * rowCount
    sectionCount = Int(ceil(Double(data.count) / Double(itemsInSection)))

    itemIndexs = [IndexPath: NSNumber]()

    for curSection in 0 ..< sectionCount {
      for itemIndex in 0 ..< itemsInSection {
        let row = itemIndex % rowCount
        let column = itemIndex / rowCount
        let reIndex = NEMoreView_Column_Count * row + column + curSection * itemsInSection
        itemIndexs?[IndexPath(row: itemIndex, section: curSection)] = NSNumber(value: reIndex)
      }
    }
    collcetionView.reloadData()
    setupConstraints()
  }

  func setupConstraints() {
    let cellSize = NEInputMoreCell.getSize()
    let collectionHeight = cellSize.height * CGFloat(rowCount) + NEMoreView_Margin * CGFloat(rowCount - 1)

    // 设置collectionview frame
    collcetionView.frame = CGRect(x: 0, y: 0, width: width, height: collectionHeight)
    if rowCount > 1 {
      // 设置行间距
      moreFlowLayout?.minimumInteritemSpacing = (collcetionView.height - cellSize.height * CGFloat(rowCount)) / CGFloat(rowCount - 1)
    }

    let margin = NEMoreView_Section_Padding
    let spacing = (collcetionView.width - cellSize.width * CGFloat(NEMoreView_Column_Count) - 2 * margin) / CGFloat(NEMoreView_Column_Count - 1)
    moreFlowLayout?.minimumLineSpacing = spacing
    moreFlowLayout?.sectionInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)

//        let height: CGFloat = collcetionView.frame.origin.y + collcetionView.height + NEMoreView_Margin
  }
}

extension NEChatMoreActionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    sectionCount
  }

  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    itemsInSection
  }

  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: NEMoreCell_ReuseId,
      for: indexPath
    ) as? NEInputMoreCell

    var itemModel: NEMoreItemModel?

    guard let index = itemIndexs?[indexPath] else {
      return UICollectionViewCell()
    }

    guard let cellData = data else {
      return UICollectionViewCell()
    }

    if index.intValue >= cellData.count {
      itemModel = nil
    } else {
      itemModel = cellData[index.intValue]
    }
    cell?.config(itemModel ?? NEMoreItemModel())
    return cell ?? UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let cell = (collectionView.cellForItem(at: indexPath) as? NEInputMoreCell) {
      delegate?.moreViewDidSelectMoreCell(moreView: self, cell: cell)
    }
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    NEInputMoreCell.getSize()
  }
}

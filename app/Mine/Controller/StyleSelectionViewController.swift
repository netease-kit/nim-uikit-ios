// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import NEConversationUIKit
import NECoreKit
import UIKit

open class StyleCellModel: NSObject {
  public var styleName: String
  public var styleImageName: String
  public var styleTitle: String
  public var selected: Bool = false
  public var selectedImageName: String

  init(styleName: String, styleImageName: String, styleTitle: String, selected: Bool, selectedImageName: String) {
    self.styleName = styleName
    self.styleImageName = styleImageName
    self.styleTitle = styleTitle
    self.selected = selected
    self.selectedImageName = selectedImageName
  }
}

open class StyleSelectionViewController: NEBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  private var sectionCount: Int = 1
  private var itemsInSection: Int = 2
  private var topMargin: CGFloat = 40
  private var cellSize = StyleSelectionCell.getSize()
  private var currentStyle: StyleSelectionCell?
  public var styleData = [StyleCellModel]()

  public lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.itemSize = CGSize(width: NEConstant.screenWidth / 2, height: cellSize.height)
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: topMargin, left: 0, bottom: topMargin, right: 0)
    let collectView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectView.translatesAutoresizingMaskIntoConstraints = false
    collectView.dataSource = self
    collectView.delegate = self
    collectView.isUserInteractionEnabled = true
    collectView.backgroundColor = .white
    collectView.contentMode = .center
    collectView.register(StyleSelectionCell.self, forCellWithReuseIdentifier: "\(StyleSelectionCell.self)")

    return collectView
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = NSLocalizedString("style_selection", comment: "")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }
    getData()
    setupSubviews()
    navigationView.moreButton.isHidden = true
  }

  func getData() {
    styleData.append(contentsOf: [
      StyleCellModel(styleName: "default",
                     styleImageName: "style_normal",
                     styleTitle: NSLocalizedString("style_default", comment: ""),
                     selected: NEStyleManager.instance.isNormalStyle(),
                     selectedImageName: "clicked_normal"),
      StyleCellModel(styleName: "fun",
                     styleImageName: "style_fun",
                     styleTitle: NSLocalizedString("style_fun", comment: ""),
                     selected: !NEStyleManager.instance.isNormalStyle(),
                     selectedImageName: "clicked_fun"),
    ])
    sectionCount = Int(ceil(Double(styleData.count) / Double(itemsInSection)))
  }

  func setupSubviews() {
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
      collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    let collectionViewHeight: CGFloat = (cellSize.height + topMargin * 2.0) * CGFloat(sectionCount)
    if collectionViewHeight > NEConstant.screenHeight {
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    } else {
      collectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight).isActive = true
    }
  }

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    sectionCount
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == sectionCount - 1 {
      return styleData.count - itemsInSection * (sectionCount - 1)
    }
    return itemsInSection
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(StyleSelectionCell.self)", for: indexPath) as? StyleSelectionCell
    let itemModel = styleData[indexPath.section * itemsInSection + indexPath.row]
    cell?.configData(model: itemModel)
    return cell ?? UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      if NEStyleManager.instance.isNormalStyle() == false {
        NEStyleManager.instance.setNormalStyle()
        NotificationCenter.default.post(
          name: Notification.Name(CHANGE_UI),
          object: nil
        )
      }
    } else if indexPath.row == 1 {
      if NEStyleManager.instance.isNormalStyle() == true {
        NEStyleManager.instance.setFunStyle()
        NotificationCenter.default.post(
          name: Notification.Name(CHANGE_UI),
          object: nil
        )
      }
    }
  }
}

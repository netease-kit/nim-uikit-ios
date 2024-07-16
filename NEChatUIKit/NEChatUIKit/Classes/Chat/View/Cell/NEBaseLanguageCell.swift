//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseLanguageCell: CornerCell {
  /// 语言内容标签
  public lazy var languageLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.backgroundColor = .clear
    label.textColor = .ne_darkText
    return label
  }()

  /// 选中指示器
  public lazy var selectedImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("language_selected")
    imageView.isHidden = true
    return imageView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupLanguageCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI 初始化
  open func setupLanguageCellUI() {
    dividerLine.isHidden = true
  }

  /// 绑定数据
  /// - Parameter content: 语言内容
  /// - Parameter isSelect: 是否选中，选中高亮显示
  open func configureData(_ model: NElanguageCellModel) {
    languageLabel.text = model.language
    languageLabel.textColor = model.isSelect ? UIColor.ne_normalTheme : UIColor.ne_darkText
    selectedImageView.isHidden = !model.isSelect
    cornerType = model.cornerType
  }
}

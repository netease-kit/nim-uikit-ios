
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
open class NEBaseUserSettingCell: CornerCell {
  public var model: UserSettingCellModel?

  public var subCornerType: CornerType {
    get { cornerType }
    set {
      if cornerType != newValue {
        cornerType = newValue
        setNeedsDisplay()
      }
    }
  }

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0x333333)
    label.font = NEConstant.defaultTextFont(16.0)
    return label
  }()

  public lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: coreLoader.loadImage("arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    showDefaultLine = true
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func configure(_ anyModel: Any) {
    if let m = anyModel as? UserSettingCellModel {
      model = m
      subCornerType = m.cornerType
      titleLabel.text = m.cellName
    }
  }
}

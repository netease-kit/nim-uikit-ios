//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

class NEHistorySearchDateCell: UICollectionViewCell {
  var selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg
  lazy var dayLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = .ne_darkText
    label.font = .systemFont(ofSize: 16, weight: .medium)
    return label
  }()

  lazy var todayLabel: UILabel = {
    let label = UILabel()
    label.text = commonLocalizable("weekday_today")
    label.textAlignment = .center
    label.textColor = .ne_darkText
    label.font = .systemFont(ofSize: 10)
    label.isHidden = true
    return label
  }()

  lazy var selectionView: UIView = {
    let view = UIView()
    view.backgroundColor = selectButtonBackgroundColor
    view.layer.cornerRadius = 20
    view.isHidden = true
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    for item in [selectionView, dayLabel, todayLabel] {
      item.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(item)
    }

    NSLayoutConstraint.activate([
      selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      selectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
      selectionView.widthAnchor.constraint(equalToConstant: 40),
      selectionView.heightAnchor.constraint(equalToConstant: 40),

      dayLabel.centerXAnchor.constraint(equalTo: selectionView.centerXAnchor),
      dayLabel.centerYAnchor.constraint(equalTo: selectionView.centerYAnchor),

      todayLabel.topAnchor.constraint(equalTo: selectionView.bottomAnchor, constant: 2),
      todayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
    ])
  }

  func configure(day: Int?,
                 isToday: Bool,
                 isSelected: Bool,
                 isFuture: Bool) {
    if let day = day {
      dayLabel.text = "\(day)"
      dayLabel.isHidden = false

      if isFuture {
        dayLabel.textColor = .clear
        selectionView.isHidden = true
        todayLabel.isHidden = true
        isUserInteractionEnabled = false
      } else if isSelected {
        dayLabel.textColor = .white
        selectionView.isHidden = false
        selectionView.backgroundColor = selectButtonBackgroundColor
        todayLabel.isHidden = !isToday
        todayLabel.textColor = selectButtonBackgroundColor // 选中时颜色
        isUserInteractionEnabled = true
      } else {
        dayLabel.textColor = .black
        selectionView.isHidden = true
        todayLabel.isHidden = !isToday
        todayLabel.textColor = .ne_darkText // 未选中时灰色
        isUserInteractionEnabled = true
      }
    } else {
      dayLabel.text = nil
      dayLabel.isHidden = true
      selectionView.isHidden = true
      todayLabel.isHidden = true
      isUserInteractionEnabled = false
    }
  }
}

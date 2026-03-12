//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

class NEHistorySearchMonthYearPickerView: UIView {
  var currentDate: Date = .init()
  var maxDate: Date = .init()
  var onConfirm: ((Int, Int) -> Void)?
  var onCancel: (() -> Void)?

  var years: [Int] = []
  var months: [Int] = []
  var selectedYear: Int = 2025
  var selectedMonth: Int = 1
  var themeColor: UIColor = .ne_normalTheme {
    didSet {
      confirmButton.setTitleColor(themeColor, for: .normal)
    }
  }

  let calendar = Calendar.current

  lazy var closeButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "xmark"), for: .normal)
    button.tintColor = .black
    button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    return button
  }()

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = chatLocalizable("choose_date_year_month")
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.textAlignment = .center
    return label
  }()

  lazy var confirmButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle(commonLocalizable("complete"), for: .normal)
    button.setTitleColor(themeColor, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    return button
  }()

  lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .normalChatNavigationDivideBg
    return view
  }()

  lazy var pickerView: UIPickerView = {
    let picker = UIPickerView()
    picker.delegate = self
    picker.dataSource = self
    return picker
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    setupYears()
    updateMonthsForSelectedYear()
    setInitialSelection()
  }

  func setupYears() {
    let maxYear = calendar.component(.year, from: maxDate)
    years = Array(1970 ... maxYear)
  }

  func updateMonthsForSelectedYear() {
    let maxYear = calendar.component(.year, from: maxDate)
    let maxMonth = calendar.component(.month, from: maxDate)

    if selectedYear == maxYear {
      months = Array(1 ... maxMonth)
    } else {
      months = Array(1 ... 12)
    }
  }

  func setupUI() {
    backgroundColor = .white
    layer.cornerRadius = 16
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    for item in [closeButton, titleLabel, confirmButton, lineView, pickerView] {
      item.translatesAutoresizingMaskIntoConstraints = false
      addSubview(item)
    }

    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      closeButton.widthAnchor.constraint(equalToConstant: 26),
      closeButton.heightAnchor.constraint(equalToConstant: 26),

      titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

      confirmButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

      lineView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
      lineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
      lineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0),
      lineView.heightAnchor.constraint(equalToConstant: 0.5),

      pickerView.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 10),
      pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      pickerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -34),
    ])
  }

  func setInitialSelection() {
    selectedYear = calendar.component(.year, from: currentDate)
    selectedMonth = calendar.component(.month, from: currentDate)

    if let yearIndex = years.firstIndex(of: selectedYear) {
      pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
    }

    updateMonthsForSelectedYear()
    pickerView.reloadComponent(1)

    if let monthIndex = months.firstIndex(of: selectedMonth) {
      pickerView.selectRow(monthIndex, inComponent: 1, animated: false)
    }
  }

  @objc func closeTapped() {
    onCancel?()
  }

  @objc func confirmTapped() {
    onConfirm?(selectedYear, selectedMonth)
  }
}

// MARK: - UIPickerViewDataSource & Delegate

extension NEHistorySearchMonthYearPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    2
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    component == 0 ? years.count : months.count
  }

  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    let label = (view as? UILabel) ?? UILabel()
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 20, weight: .medium)

    if component == 0 {
      label.text = "\(years[row])"
    } else {
      label.text = String(format: "%02d", months[row])
    }

    return label
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if component == 0 {
      selectedYear = years[row]
      updateMonthsForSelectedYear()
      pickerView.reloadComponent(1)

      if !months.contains(selectedMonth) {
        selectedMonth = months.last ?? 1
        if let monthIndex = months.firstIndex(of: selectedMonth) {
          pickerView.selectRow(monthIndex, inComponent: 1, animated: true)
        }
      }
    } else {
      selectedMonth = months[row]
    }
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    44
  }

  func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
    bounds.width / 2 - 40
  }
}

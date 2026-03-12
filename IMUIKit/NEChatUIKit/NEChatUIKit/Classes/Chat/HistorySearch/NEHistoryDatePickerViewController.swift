//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import UIKit

// MARK: - 日期选择结果回调协议

protocol NEHistoryDatePickerViewControllerDelegate: AnyObject {
  func datePickerDidSelectDate(_ timestamp: Int64)
}

// MARK: - 主日期选择器

class NEHistoryDatePickerViewController: NEChatBaseViewController {
  weak var delegate: NEHistoryDatePickerViewControllerDelegate?

  var selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg

  // MARK: - Properties

  var selectedDate: Date?
  var currentDisplayMonth: Date = .init()
  var months: [Date] = []
  let calendar = Calendar.current
  let today = Date()

  var quickSelectType: QuickSelectType = .none

  enum QuickSelectType {
    case none
    case today
    case last7Days
    case last30Days
  }

  // MARK: - UI Components

  lazy var todayButton: UIButton = createQuickButton(title: commonLocalizable("weekday_today"), tag: 0)
  lazy var last7DaysButton: UIButton = createQuickButton(title: commonLocalizable("weekday_last7day"), tag: 1)
  lazy var last30DaysButton: UIButton = createQuickButton(title: commonLocalizable("weekday_last30day"), tag: 2)

  let pickerHeight: CGFloat = 350
  lazy var pickerView: NEHistorySearchMonthYearPickerView = {
    let pickerView = NEHistorySearchMonthYearPickerView(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: pickerHeight))
    pickerView.themeColor = selectButtonBackgroundColor
    return pickerView
  }()

  lazy var quickButtonStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [todayButton, last7DaysButton, last30DaysButton])
    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.spacing = 12
    return stack
  }()

  lazy var monthSelectorButton: UIButton = {
    let button = UIButton()
    button.setTitleColor(.ne_lightText, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 14)
    button.contentHorizontalAlignment = .left
    button.addTarget(self, action: #selector(monthSelectorTapped), for: .touchUpInside)

    let icon = UIImageView(image: UIImage.ne_imageNamed(name: "history_search_date_arrow_down"))
    icon.translatesAutoresizingMaskIntoConstraints = false

    button.addSubview(icon)
    NSLayoutConstraint.activate([
      icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 12),
      icon.heightAnchor.constraint(equalToConstant: 12),
    ])
    if let titleLabelRightAnchor = button.titleLabel?.rightAnchor {
      NSLayoutConstraint.activate([
        icon.leftAnchor.constraint(equalTo: titleLabelRightAnchor, constant: 0),
      ])
    } else {
      NSLayoutConstraint.activate([
        icon.rightAnchor.constraint(equalTo: button.rightAnchor, constant: 0),
      ])
    }
    return button
  }()

  lazy var weekdayHeader: UIStackView = {
    let weekdays = [commonLocalizable("weekday_sun"),
                    commonLocalizable("weekday_mon"),
                    commonLocalizable("weekday_tue"),
                    commonLocalizable("weekday_wed"),
                    commonLocalizable("weekday_thu"),
                    commonLocalizable("weekday_fri"),
                    commonLocalizable("weekday_sat")]
    let labels = weekdays.map { day -> UILabel in
      let label = UILabel()
      label.text = day
      label.textAlignment = .center
      label.font = .systemFont(ofSize: 14)
      label.textColor = .ne_lightText
      return label
    }
    let stack = UIStackView(arrangedSubviews: labels)
    stack.axis = .horizontal
    stack.distribution = .fillEqually
    return stack
  }()

  lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0

    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.backgroundColor = .white
    cv.showsVerticalScrollIndicator = false
    cv.delegate = self
    cv.dataSource = self
    cv.register(NEHistorySearchDateCell.self, forCellWithReuseIdentifier: NEHistorySearchDateCell.className())
    cv.register(NEHistorySearchMonthHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NEHistorySearchMonthHeaderView.className())
    return cv
  }()

  var monthPickerView: NEHistorySearchMonthYearPickerView?
  var dimView: UIView?

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    generateMonths()

    // 首次进入默认选中今天
    selectedDate = calendar.startOfDay(for: today)
    updateQuickButtonState(.today)

    DispatchQueue.main.async {
      self.scrollToToday(animated: false)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
      let width = (collectionView.bounds.width) / 7
      layout.itemSize = CGSize(width: width, height: 70)
      layout.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 50)
    }
  }

  // MARK: - Setup

  func setupUI() {
    view.backgroundColor = .white
    title = chatLocalizable("search_message_by_date")
    navigationView.setMoreButtonTitle(commonLocalizable("complete"), selectButtonBackgroundColor)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(doneTapped))
    navigationView.titleBarBottomLine.isHidden = false

    for item in [quickButtonStack, monthSelectorButton, weekdayHeader, collectionView] {
      item.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(item)
    }

    NSLayoutConstraint.activate([
      quickButtonStack.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 12),
      quickButtonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      quickButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      quickButtonStack.heightAnchor.constraint(equalToConstant: 40),

      monthSelectorButton.topAnchor.constraint(equalTo: quickButtonStack.bottomAnchor, constant: 20),
      monthSelectorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      monthSelectorButton.widthAnchor.constraint(equalToConstant: 100),
      monthSelectorButton.heightAnchor.constraint(equalToConstant: 30),

      weekdayHeader.topAnchor.constraint(equalTo: monthSelectorButton.bottomAnchor, constant: 10),
      weekdayHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      weekdayHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      weekdayHeader.heightAnchor.constraint(equalToConstant: 30),

      collectionView.topAnchor.constraint(equalTo: weekdayHeader.bottomAnchor, constant: 5),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  func createQuickButton(title: String, tag: Int) -> UIButton {
    let button = UIButton(type: .custom)
    button.setTitle(title, for: .normal)
    button.setTitleColor(.ne_darkText, for: .normal)
    button.setTitleColor(.white, for: .selected)
    button.titleLabel?.font = .systemFont(ofSize: 14)
    button.layer.cornerRadius = 4
    button.layer.borderWidth = 1
    button.layer.borderColor = UIColor(hexString: "#D9D9D9").cgColor
    button.tag = tag
    button.addTarget(self, action: #selector(quickButtonTapped(_:)), for: .touchUpInside)
    return button
  }

  func generateMonths() {
    months.removeAll()

    // 从1970年1月到当前月份
    var components = DateComponents()
    components.year = 1970
    components.month = 1
    components.day = 1

    guard let startDate = calendar.date(from: components) else { return }

    var currentComponents = calendar.dateComponents([.year, .month], from: today)
    currentComponents.day = 1
    guard let endDate = calendar.date(from: currentComponents) else { return }

    var date = startDate
    while date <= endDate {
      months.append(date)
      guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else { break }
      date = nextMonth
    }
  }

  func updateMonthSelectorTitle() {
    let formatter = DateFormatter()
    formatter.dateFormat = commonLocalizable("ym")
    let title = formatter.string(from: currentDisplayMonth)
    monthSelectorButton.setTitle(title, for: .normal)
  }

  func updateQuickButtonState(_ type: QuickSelectType) {
    quickSelectType = type

    for button in [todayButton, last7DaysButton, last30DaysButton] {
      button.isSelected = false
      button.backgroundColor = .white
      button.layer.borderColor = UIColor.lightGray.cgColor
    }

    var selectedButton: UIButton?
    switch type {
    case .today:
      selectedButton = todayButton
    case .last7Days:
      selectedButton = last7DaysButton
    case .last30Days:
      selectedButton = last30DaysButton
    case .none:
      break
    }

    selectedButton?.isSelected = true
    selectedButton?.backgroundColor = selectButtonBackgroundColor
    selectedButton?.layer.borderColor = selectButtonBackgroundColor.cgColor
  }

  // MARK: - Actions

  @objc func doneTapped() {
    guard let date = selectedDate else {
      showToast(chatLocalizable("choose"))
      return
    }

    if IMKitConfigCenter.shared.enableCloudMessageSearch {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        showToast(commonLocalizable("network_error"))
        return
      }
    }

    let timestamp = max(Int64(date.timeIntervalSince1970), 0)
    delegate?.datePickerDidSelectDate(timestamp)
  }

  @objc func quickButtonTapped(_ sender: UIButton) {
    var targetDate: Date?
    var type: QuickSelectType = .none

    switch sender.tag {
    case 0:
      targetDate = today
      type = .today
    case 1:
      targetDate = calendar.date(byAdding: .day, value: -7, to: today)
      type = .last7Days
    case 2:
      targetDate = calendar.date(byAdding: .day, value: -30, to: today)
      type = .last30Days
    default:
      break
    }

    guard let date = targetDate else { return }

    updateQuickButtonState(type)
    selectedDate = calendar.startOfDay(for: date)
    scrollToDate(date, animated: true)
    collectionView.reloadData()
  }

  @objc func monthSelectorTapped() {
    showMonthPicker()
  }

  func scrollToToday(animated: Bool) {
    scrollToDate(today, animated: animated)
  }

  func scrollToDate(_ date: Date, animated: Bool) {
    let targetComponents = calendar.dateComponents([.year, .month], from: date)

    for (section, month) in months.enumerated() {
      let monthComponents = calendar.dateComponents([.year, .month], from: month)
      if monthComponents.year == targetComponents.year, monthComponents.month == targetComponents.month {
        let dayOfMonth = calendar.component(.day, from: date)
        let firstWeekday = getFirstWeekdayOfMonth(month)
        let item = firstWeekday + dayOfMonth - 1

        let indexPath = IndexPath(item: item, section: section)

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)

        if section > 0 {
          currentDisplayMonth = months[section - 1]
        } else {
          currentDisplayMonth = month
        }
        updateMonthSelectorTitle()
        return
      }
    }
  }

  func scrollToMonth(_ date: Date, animated: Bool) {
    let targetComponents = calendar.dateComponents([.year, .month], from: date)

    for (section, month) in months.enumerated() {
      let monthComponents = calendar.dateComponents([.year, .month], from: month)
      if monthComponents.year == targetComponents.year, monthComponents.month == targetComponents.month {
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)

        currentDisplayMonth = month
        updateMonthSelectorTitle()
        return
      }
    }
  }

  func showMonthPicker() {
    let dimView = UIView(frame: view.bounds)
    dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    dimView.alpha = 0
    view.addSubview(dimView)
    self.dimView = dimView

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissMonthPicker))
    dimView.addGestureRecognizer(tapGesture)

    pickerView.currentDate = currentDisplayMonth
    pickerView.themeColor = selectButtonBackgroundColor
    pickerView.maxDate = today
    pickerView.onConfirm = { [weak self] year, month in
      self?.dismissMonthPicker()
      var components = DateComponents()
      components.year = year
      components.month = month
      components.day = 1
      if let date = self?.calendar.date(from: components) {
        self?.selectedDate = nil
        self?.updateQuickButtonState(.none)
        self?.scrollToMonth(date, animated: false)
        self?.collectionView.reloadData()
      }
    }
    pickerView.onCancel = { [weak self] in
      self?.dismissMonthPicker()
    }
    view.addSubview(pickerView)
    monthPickerView = pickerView

    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self = self else { return }
      dimView.alpha = 1
      self.pickerView.frame.origin.y = self.view.bounds.height - pickerHeight
    }
  }

  @objc func dismissMonthPicker() {
    UIView.animate(withDuration: 0.3, animations: {
      self.dimView?.alpha = 0
      self.monthPickerView?.frame.origin.y = self.view.bounds.height
    }) { _ in
      self.dimView?.removeFromSuperview()
      self.monthPickerView?.removeFromSuperview()
      self.dimView = nil
      self.monthPickerView = nil
    }
  }

  func getFirstWeekdayOfMonth(_ date: Date) -> Int {
    var components = calendar.dateComponents([.year, .month], from: date)
    components.day = 1
    guard let firstDay = calendar.date(from: components) else { return 0 }
    return calendar.component(.weekday, from: firstDay) - 1
  }

  func getDaysInMonth(_ date: Date) -> Int {
    calendar.range(of: .day, in: .month, for: date)?.count ?? 30
  }
}

// MARK: - UICollectionViewDataSource

extension NEHistoryDatePickerViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    months.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let month = months[section]
    let firstWeekday = getFirstWeekdayOfMonth(month)
    let daysInMonth = getDaysInMonth(month)
    return firstWeekday + daysInMonth
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NEHistorySearchDateCell.className(), for: indexPath) as! NEHistorySearchDateCell
    cell.selectButtonBackgroundColor = selectButtonBackgroundColor

    let month = months[indexPath.section]
    let firstWeekday = getFirstWeekdayOfMonth(month)

    if indexPath.item < firstWeekday {
      cell.configure(day: nil,
                     isToday: false,
                     isSelected: false,
                     isFuture: false)
    } else {
      let day = indexPath.item - firstWeekday + 1
      var components = calendar.dateComponents([.year, .month], from: month)
      components.day = day

      guard let date = calendar.date(from: components) else {
        cell.configure(day: nil,
                       isToday: false,
                       isSelected: false,
                       isFuture: false)
        return cell
      }

      let isToday = calendar.isDateInToday(date)
      let isFuture = date > today && !isToday
      let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)

      cell.configure(day: day,
                     isToday: isToday,
                     isSelected: isSelected,
                     isFuture: isFuture)
    }

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NEHistorySearchMonthHeaderView.className(), for: indexPath) as! NEHistorySearchMonthHeaderView

    let month = months[indexPath.section]
    let formatter = DateFormatter()
    formatter.dateFormat = commonLocalizable("m")
    header.configure(title: formatter.string(from: month))

    return header
  }
}

// MARK: - UICollectionViewDelegate

extension NEHistoryDatePickerViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let month = months[indexPath.section]
    let firstWeekday = getFirstWeekdayOfMonth(month)

    guard indexPath.item >= firstWeekday else { return }

    let day = indexPath.item - firstWeekday + 1

    // 直接提取年、月数值，避免 Date 对象传递中的问题
    let year = calendar.component(.year, from: month)
    let monthValue = calendar.component(.month, from: month)

    var components = DateComponents()
    components.year = year
    components.month = monthValue
    components.day = day
    components.hour = 0
    components.minute = 0
    components.second = 0

    guard let date = calendar.date(from: components) else { return }

    if date > today, !calendar.isDateInToday(date) { return }

    selectedDate = date

    // 调试日志（上线前删除）
    print("选中日期: \(year)-\(monthValue)-\(day), timestamp: \(Int64(date.timeIntervalSince1970))")

    if calendar.isDateInToday(date) {
      updateQuickButtonState(.today)
    } else {
      updateQuickButtonState(.none)
    }

    collectionView.reloadData()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted().first else { return }

    let month = months[visibleIndexPaths.section]
    if !calendar.isDate(month, equalTo: currentDisplayMonth, toGranularity: .month) {
      currentDisplayMonth = month
      updateMonthSelectorTitle()
    }
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NEHistoryDatePickerViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (collectionView.bounds.width) / 7
    return CGSize(width: width, height: 70)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    CGSize(width: collectionView.bounds.width, height: 50)
  }
}

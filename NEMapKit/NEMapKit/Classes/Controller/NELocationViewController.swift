// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NECommonKit
import NECoreKit
import UIKit

@objcMembers
open class NELocationViewController: UIViewController, NELocationBottomViewDelegate {
  /// 地图展示类型
  public var mapType: NEMapType?
  /// 当前定位点
  public var currentPoint = CGPoint(x: 0, y: 0)
  /// 地理位置标题
  public var locationTitle: String?
  /// 地理位置子标题
  public var subTitle: String?
  /// 底部弹出位置列表高度约束控制变量
  private var tableViewBottomConstraint: NSLayoutConstraint?
  /// 搜索框位置控制变量
  private var searchViewConstraint: NSLayoutConstraint?
  /// 记录键盘弹起状态
  private var foldKeyBoard = true
  /// 底部地理位置列表默认高度
  private let defaultTableHeight: CGFloat = 230
  /// 位置列表选中索引
  private var currentIndex: Int = 0
  /// 地图视图
  private var mapView: UIView?
  /// 地理位置列表数据源
  private var locations = [NELocaitonModel]()
  /// 当前选中的地理位置数据模型
  public var currentModel: NELocaitonModel?

  // 顶部返回按钮
  lazy var backButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(mapCoreLoader.loadImage("chat_map_back"), for: .normal)
    button.setImage(mapCoreLoader.loadImage("chat_map_back"), for: .highlighted)
    button.addTarget(self, action: #selector(backBackClick), for: .touchUpInside)
    return button
  }()

  // 顶部取消按钮
  lazy var cancelButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(.white, for: .normal)
    button.setTitle(mapLocalizable("cancel"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
    return button
  }()

  // 输入框取消搜索按钮
  lazy var searchCancelButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(mapLocalizable("search_cancel"), for: .normal)
    button.setTitleColor(UIColor.ne_emptyTitleColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    button.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  // 地理位置复位按钮
  lazy var resetButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(mapCoreLoader.loadImage("map_reset_normal"), for: .normal)
    button.setImage(mapCoreLoader.loadImage("map_reset_select"), for: .selected)
    button.addTarget(self, action: #selector(resetClick), for: .touchUpInside)
    return button
  }()

  // 发送按钮
  lazy var sendButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(.white, for: .normal)
    button.setTitle(mapLocalizable("send"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.backgroundColor = UIColor.ne_normalTheme
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(sendBtnClick), for: .touchUpInside)
    return button
  }()

  // 底部引导分享视图
  lazy var guideBottomView: NELocationGuideBottomView = {
    let bottomView = NELocationGuideBottomView(frame: CGRect.zero)
    bottomView.translatesAutoresizingMaskIntoConstraints = false
    bottomView.delegate = self
    return bottomView
  }()

  /// 空占位图
  public lazy var emptyImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = mapCoreLoader.loadImage("chat_map_empty")
    imageView.isHidden = true
    return imageView
  }()

  public lazy var emptyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_greyText
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.text = mapLocalizable("search_result_empty")
    label.isHidden = true
    return label
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NELocationAddressCell.self,
      forCellReuseIdentifier: NELocationAddressCell.className()
    )
    tableView.rowHeight = 72
    tableView.backgroundColor = .white
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  // 搜索输入框
  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.contentMode = .center
    textField.leftView = UIImageView(image: mapCoreLoader.loadImage("search"))
    textField.leftViewMode = .always
    textField.placeholder = mapLocalizable("search_place")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.layer.cornerRadius = 8
    textField.backgroundColor = .ne_lightBackgroundColor
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)
    return textField
  }()

  // 搜搜输入框背景
  lazy var searchBgView: UIView = {
    let bgView = UIView()
    bgView.translatesAutoresizingMaskIntoConstraints = false
    return bgView
  }()

  /// 位置定位图片
  public lazy var pointImage: UIImageView = {
    let pointImage = UIImageView()
    pointImage.translatesAutoresizingMaskIntoConstraints = false
    pointImage.image = mapCoreLoader.loadImage("location_point")
    return pointImage
  }()

  /// 初始化
  public init(type: NEMapType) {
    mapType = type
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = true
    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable {
        weakSelf?.sendButton.isEnabled = false
        weakSelf?.sendButton.alpha = 0.5
      } else {
        weakSelf?.sendButton.isEnabled = true
        weakSelf?.sendButton.alpha = 1.0
      }
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.isHidden = false
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
  }

  /// UI 初始化
  func setupSubviews() {
    weak var weakSelf = self

    // 获取地图视图加载
    if let mapView = NEMapClient.shared().getMapView() as? UIView {
      view.addSubview(mapView)
      self.mapView = mapView
    }

    // 配置地图控制器参数
    if let type = mapType {
      NEMapClient.shared().setupMapController(withMapType: type.rawValue)
    }

    // 地图触摸移动回调，如果有触摸重新定位到当前按钮变为可点击状态
    NEMapClient.shared().didmoveMap {
      weakSelf?.resetButton.isSelected = true
    }

    if mapType == .detail, let map = mapView {
      resetButton.isSelected = true
      NEMapClient.shared().setMapviewLocationWithLat(currentPoint.x, lng: currentPoint.y, mapview: map)
    } else {
      toSearchCurrentUserLocation()

      if let map = mapView {
        map.addSubview(pointImage)
        NSLayoutConstraint.activate([
          pointImage.centerXAnchor.constraint(equalTo: map.centerXAnchor),
          pointImage.centerYAnchor.constraint(equalTo: map.centerYAnchor, constant: -17),
        ])
      }
    }

    if mapType == .detail {
      NEMapClient.shared().setCustomAnnotationWith(mapCoreLoader.loadImage("location_point"), lat: currentPoint.x, lng: currentPoint.y)
      addDetailSubviews()
    } else {
      NEMapClient.shared().setCustomAnnotationWith(nil, lat: 0, lng: 0)
      addSearchSubviews()
    }
  }

  // 初始化详情类型视图
  func addDetailSubviews() {
    view.addSubview(backButton)
    view.addSubview(guideBottomView)
    NSLayoutConstraint.activate([
      backButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 28),
      backButton.widthAnchor.constraint(equalToConstant: 32),
      backButton.heightAnchor.constraint(equalToConstant: 32),
      backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
    ])

    NSLayoutConstraint.activate([
      guideBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      guideBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
      guideBottomView.heightAnchor.constraint(equalToConstant: 111),
      guideBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    guideBottomView.titleLabel.text = locationTitle
    guideBottomView.subtitleLabel.text = subTitle

    view.addSubview(resetButton)
    NSLayoutConstraint.activate([
      resetButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      resetButton.bottomAnchor.constraint(equalTo: guideBottomView.topAnchor, constant: -209),
      resetButton.widthAnchor.constraint(equalToConstant: 70),
      resetButton.heightAnchor.constraint(equalToConstant: 70),
    ])
  }

  // 搜索输入UI布局
  func addSearchSubviews() {
    // 添加键盘监听
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillShow(_:)),
                                           name: UIResponder.keyboardWillShowNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillHide(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)
    view.addSubview(cancelButton)
    view.addSubview(sendButton)
    view.addSubview(tableView)
    view.addSubview(resetButton)
    view.addSubview(searchBgView)

    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 64),
      cancelButton.heightAnchor.constraint(equalToConstant: 32),
      cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
    ])

    NSLayoutConstraint.activate([
      sendButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      sendButton.widthAnchor.constraint(equalToConstant: 64),
      sendButton.heightAnchor.constraint(equalToConstant: 32),
      sendButton.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
    ])

    tableViewBottomConstraint = tableView.heightAnchor.constraint(equalToConstant: defaultTableHeight)
    tableViewBottomConstraint?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      searchBgView.leftAnchor.constraint(equalTo: view.leftAnchor),
      searchBgView.rightAnchor.constraint(equalTo: view.rightAnchor),
      searchBgView.bottomAnchor.constraint(equalTo: tableView.topAnchor),
      searchBgView.heightAnchor.constraint(equalToConstant: 60),
    ])

    tableView.addSubview(emptyImageView)
    NSLayoutConstraint.activate([
      emptyImageView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyImageView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
    ])

    tableView.addSubview(emptyLabel)
    NSLayoutConstraint.activate([
      emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8.0),
    ])

    NSLayoutConstraint.activate([
      resetButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      resetButton.bottomAnchor.constraint(equalTo: searchBgView.topAnchor, constant: 0),
      resetButton.widthAnchor.constraint(equalToConstant: 70),
      resetButton.heightAnchor.constraint(equalToConstant: 70),
    ])
    if let map = mapView {
      map.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        map.leftAnchor.constraint(equalTo: view.leftAnchor),
        map.rightAnchor.constraint(equalTo: view.rightAnchor),
        map.topAnchor.constraint(equalTo: view.topAnchor),
        map.bottomAnchor.constraint(equalTo: searchBgView.topAnchor),
      ])
    }

    searchBgView.addSubview(searchTextField)
    searchBgView.addSubview(searchCancelButton)

    searchViewConstraint = searchTextField.rightAnchor.constraint(equalTo: searchBgView.rightAnchor, constant: -12)
    searchViewConstraint?.isActive = true
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: searchBgView.leftAnchor, constant: 12),
      searchTextField.topAnchor.constraint(equalTo: searchBgView.topAnchor, constant: 12),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])
    NSLayoutConstraint.activate([
      searchCancelButton.rightAnchor.constraint(equalTo: searchBgView.rightAnchor, constant: -12),
      searchCancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
      searchCancelButton.widthAnchor.constraint(equalToConstant: 52),
      searchCancelButton.heightAnchor.constraint(equalToConstant: 56),
    ])
    searchBgView.backgroundColor = .white
  }

  //    MARK: 键盘通知相关操作

  // 键盘弹出
  func keyBoardWillShow(_ notification: Notification) {
    foldKeyBoard = false
    searchCancelButton.isHidden = false
    searchViewConstraint?.constant = -64
    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    layoutInputView(offset: keyboardRect.size.height)
    UIView.animate(withDuration: 0.25, animations: {
      self.view.layoutIfNeeded()
    })
  }

  // 键盘隐藏
  func keyBoardWillHide(_ notification: Notification) {
    foldKeyBoard = true
  }

  private func layoutInputView(offset: CGFloat) {
    tableViewBottomConstraint?.constant = defaultTableHeight + offset
  }

  // 地理位置复位点击
  open func resetClick() {
    if let map = mapView {
      resetButton.isSelected = false
      if mapType == .detail, let map = mapView {
        NEMapClient.shared().setMapCenterWithMapview(map)
        return
      }
      searchTextField.text = nil
      toSearchLocalWithMapView()
      NEMapClient.shared().setMapCenterWithMapview(map)

      currentIndex = 0
      tableView.reloadData()
    }
  }

  // 取消搜索点击
  open func cancelSearch() {
    UIApplication.shared.keyWindow?.endEditing(true)
    UIView.animate(withDuration: 0.25, animations: {
      self.searchCancelButton.isHidden = true
      self.searchViewConstraint?.constant = -12
      self.tableViewBottomConstraint?.constant = self.defaultTableHeight
    })
    searchTextField.text = ""
    NEALog.infoLog(className(), desc: "toSearchCurrentUserLocation cancel earch call")

    toSearchCurrentUserLocation()
    NEMapClient.shared().setMapCenterWithMapview(mapView as Any)
  }

  func showEmptyView() {
    emptyImageView.isHidden = false
    emptyLabel.isHidden = false
  }

  func hideEmptyView() {
    emptyImageView.isHidden = true
    emptyLabel.isHidden = true
  }

  open func backBackClick() {
    navigationController?.popViewController(animated: true)
  }

  open func cancelBtnClick() {
    navigationController?.popViewController(animated: true)
  }

  /// 发送点击
  open func sendBtnClick() {
    var model: NELocaitonModel?

    if model == nil {
      if locations.count > currentIndex {
        model = locations[currentIndex]
      }
    }

    if model == nil {
      model = currentModel
    }

    if let m = model {
      // 地理位置回调
      navigationController?.popViewController(animated: false)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
        if let params = m.yx_modelToJSONObject() as? [String: Any] {
          Router.shared.use(NERouterUrl.LocationSearchResult, parameters: params)
        }
      }))
    } else {
      showToast(mapLocalizable("no_location"))
    }
  }

  open func searchTextFieldChange(textfield: SearchTextField) {
    guard let searchText = textfield.text else {
      return
    }

    let filterSpace = searchText.trimmingCharacters(in: .whitespaces)
    if filterSpace.count <= 0 && searchText.count > 0 {
      return
    }

    let textRange = textfield.markedTextRange
    if textRange == nil || ((textRange?.isEmpty) == nil) {
      weak var weakSelf = self
      if let text = textfield.text {
        NEMapClient.shared().searchPosition(withKey: text) { models, error in

          weakSelf?.loadModels(models: models)
        }
      }
    }
    if searchText.count <= 0 {
      if let map = mapView {
        NEMapClient.shared().setMapCenterWithMapview(map)
      }
      toSearchLocalWithMapView()
    }
  }

  open func toSearchLocalWithMapView() {
    guard let map = mapView else {
      return
    }
    weak var weakSelf = self
    NEMapClient.shared().searchMapCenter(withMapview: map) { models, error in
      if let text = weakSelf?.searchTextField.text, text.count > 0 {
        return
      }
      weakSelf?.resetButton.isSelected = false
      weakSelf?.loadModels(models: models)
    }
  }

  open func toSearchCurrentUserLocation() {
    weak var weakSelf = self
    NEMapClient.shared().searchRoundPosition { models, error in
      if let text = weakSelf?.searchTextField.text, text.count > 0 {
        return
      }
      weakSelf?.resetButton.isSelected = false
      weakSelf?.loadModels(models: models)
    }
  }

  // MARK: NEMapGuideBottomViewDelegate

  // 点击跳转三方应用
  open func didClickGuide() {
    showBottomSelectAlert(firstContent: mapLocalizable("gaode_map"), secondContent: mapLocalizable("tencent_map")) { value in

      if value == 0 {
        if let gaodeApp = URL(string: "iosamap://") {
          // 高德
          if UIApplication.shared.canOpenURL(gaodeApp) == true {
            if let url = "iosamap://viewMap?sourceApplication=yunxin_im&backScheme=im_uikit&poiname=\(self.locationTitle ?? "")&lat=\(self.currentPoint.x)&lon=\(self.currentPoint.y)&dev=1".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
              if let jumpUrl = URL(string: url) {
                if #available(iOS 10.0, *) {
                  UIApplication.shared.open(jumpUrl)
                } else {
                  UIApplication.shared.openURL(jumpUrl)
                }
              }
            }

          } else if let url = URL(string: aMapDownloadUrl) {
            if #available(iOS 10.0, *) {
              UIApplication.shared.open(url)
            } else {
              UIApplication.shared.openURL(url)
            }
          }
        }
      } else if value == 1 {
        // 腾讯
        if let gaodeApp = URL(string: "qqmap://") {
          if UIApplication.shared.canOpenURL(gaodeApp) == true {
            if let url = "qqmap://map/marker?marker=coord:\(self.currentPoint.x),\(self.currentPoint.y);title:\(self.locationTitle ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
              if let jumpUrl = URL(string: url) {
                if #available(iOS 10.0, *) {
                  UIApplication.shared.open(jumpUrl)
                } else {
                  UIApplication.shared.openURL(jumpUrl)
                }
              }
            }

          } else if let url = URL(string: tencentMapDownloadUrl) {
            if #available(iOS 10.0, *) {
              UIApplication.shared.open(url)
            } else {
              UIApplication.shared.openURL(url)
            }
          }
        }
      }
    }
  }

  open func loadModels(models: [NELocaitonModel]) {
    currentIndex = 0
    locations.removeAll()
    if let keyword = searchTextField.text, keyword.count > 0 {
      for model in models {
        model.attribute = model.title.highlight(keyWords: keyword, highlightColor: UIColor.ne_normalTheme)
      }
    } else {
      for model in models {
        model.attribute = NSMutableAttributedString(string: model.title)
      }
    }
    if models.count > currentIndex {
      let model = models[currentIndex]
      if let map = mapView {
        NEMapClient.shared().setMapviewLocationWithLat(model.lat, lng: model.lng, mapview: map)
      }
      if searchTextField.text?.count ?? 0 > 0 {
        resetButton.isSelected = true
      }
    }

    locations.append(contentsOf: models)
    tableView.reloadData()
    if models.count > 0 {
      tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: false)
      hideEmptyView()
    }
    if models.count <= 0 {
      showEmptyView()
      UIApplication.shared.keyWindow?.endEditing(true)
    }
    refreshCurrentCache()
  }

  open func refreshCurrentCache() {
    if locations.count > currentIndex {
      currentModel = locations[currentIndex]
    }
  }
}

extension NELocationViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    locations.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: NELocationAddressCell.className(),
      for: indexPath
    ) as! NELocationAddressCell
    let model = locations[indexPath.row]
    cell.configure(model, currentIndex == indexPath.row)
    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preiousCell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? NELocationAddressCell {
      preiousCell.selectImgView.isHidden = true
    }
    if let currentCell = tableView.cellForRow(at: indexPath) as? NELocationAddressCell {
      currentCell.selectImgView.isHidden = false
    }
    let model = locations[indexPath.row]
    if let map = mapView {
      NEMapClient.shared().setMapviewLocationWithLat(model.lat, lng: model.lng, mapview: map)
    }
    currentIndex = indexPath.row
    if indexPath.row != 0 {
      resetButton.isSelected = true
    }
    refreshCurrentCache()
  }
}

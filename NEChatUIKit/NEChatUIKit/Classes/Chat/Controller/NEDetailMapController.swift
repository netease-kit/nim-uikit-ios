// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreKit
import UIKit

@objcMembers
open class NEDetailMapController: ChatBaseViewController, NEMapGuideBottomViewDelegate {
  // 地图展示类型
  public var mapType: NEMapType?
  public var currentPoint = CGPoint(x: 0, y: 0)
  public var locationTitle: String?
  public var subTitle: String?
  private let reuseId = "NEMapAddressCell"
  private var tableViewBottomConstraint: NSLayoutConstraint?

  private var searchViewConstraint: NSLayoutConstraint?
  // 记录键盘弹起状态
  private var foldKeyBoard = true

  private let defaultTableHeight: CGFloat = 230

  var completion: NEPositionSelectCompletion?

  private var currentIndex: Int = 0

  private var mapView: UIView?

  private var locations = [ChatLocaitonModel]()

  public var currentModel: ChatLocaitonModel?

  public init(type: NEMapType) {
    mapType = type
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewWillAppear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = true
    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable {
        weakSelf?.sendBtn.isEnabled = false
        weakSelf?.sendBtn.alpha = 0.5
      } else {
        weakSelf?.sendBtn.isEnabled = true
        weakSelf?.sendBtn.alpha = 1.0
      }
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    navigationController?.navigationBar.isHidden = false
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
  }

  func setupSubviews() {
    if let mapDelagate = NEChatKitClient.instance.delegate {
      weak var weakSelf = self
      NELog.infoLog(className(), desc: "toSearchCurrentUserLocation setupSubviews call")
      toSearchCurrentUserLocation()

      if let mapView = mapDelagate.getMapView?() as? UIView {
        view.addSubview(mapView)
        self.mapView = mapView
      }
      // 配置地图控制器参数
      if let type = mapType {
        mapDelagate.setupMapController?(mapType: type.rawValue)
      }
      mapDelagate.didmoveMap?(completion: {
        weakSelf?.resetBtn.isSelected = true
        print("user move map")
      })

      if mapType == .detail, let map = mapView {
        resetBtn.isSelected = true
        mapDelagate.setMapviewLocation?(lat: currentPoint.x, lng: currentPoint.y, mapview: map)
      } else {
        if let map = mapView {
          let pointImage = UIImageView()
          pointImage.translatesAutoresizingMaskIntoConstraints = false
          pointImage.image = coreLoader.loadImage("location_point")
          map.addSubview(pointImage)
          NSLayoutConstraint.activate([
            pointImage.centerXAnchor.constraint(equalTo: map.centerXAnchor),
            pointImage.centerYAnchor.constraint(equalTo: map.centerYAnchor, constant: -17),
          ])
        }
      }

    } else {
      view.addSubview(emptyTip)
      NSLayoutConstraint.activate([
        emptyTip.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        emptyTip.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      ])
    }

    if mapType == .detail {
      NEChatKitClient.instance.delegate?.setCustomAnnotation?(image: coreLoader.loadImage("location_point"), lat: currentPoint.x, lng: currentPoint.y)
      addDetailSubviews()
    } else {
      NEChatKitClient.instance.delegate?.setCustomAnnotation?(image: nil, lat: 0, lng: 0)
      addSearchSubviews()
    }
  }

  func addDetailSubviews() {
    view.addSubview(backBtn)
    view.addSubview(guideBottomView)
    NSLayoutConstraint.activate([
      backBtn.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 28),
      backBtn.widthAnchor.constraint(equalToConstant: 32),
      backBtn.heightAnchor.constraint(equalToConstant: 32),
      backBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
    ])

    NSLayoutConstraint.activate([
      guideBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      guideBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
      guideBottomView.heightAnchor.constraint(equalToConstant: 111),
      guideBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    guideBottomView.title.text = locationTitle
    guideBottomView.subtitle.text = subTitle

    view.addSubview(resetBtn)
    NSLayoutConstraint.activate([
      resetBtn.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      resetBtn.bottomAnchor.constraint(equalTo: guideBottomView.topAnchor, constant: -209),
      resetBtn.widthAnchor.constraint(equalToConstant: 70),
      resetBtn.heightAnchor.constraint(equalToConstant: 70),
    ])
  }

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
    view.addSubview(cancelBtn)
    view.addSubview(sendBtn)
    view.addSubview(tableView)
    view.addSubview(resetBtn)
    view.addSubview(searchBgView)

    NSLayoutConstraint.activate([
      cancelBtn.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      cancelBtn.widthAnchor.constraint(equalToConstant: 64),
      cancelBtn.heightAnchor.constraint(equalToConstant: 32),
      cancelBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
    ])

    NSLayoutConstraint.activate([
      sendBtn.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      sendBtn.widthAnchor.constraint(equalToConstant: 64),
      sendBtn.heightAnchor.constraint(equalToConstant: 32),
      sendBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight),
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

    tableView.addSubview(emptyImage)
    NSLayoutConstraint.activate([
      emptyImage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyImage.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
    ])

    tableView.addSubview(emptyLabel)
    NSLayoutConstraint.activate([
      emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      emptyLabel.topAnchor.constraint(equalTo: emptyImage.bottomAnchor, constant: 8.0),
    ])

    NSLayoutConstraint.activate([
      resetBtn.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      resetBtn.bottomAnchor.constraint(equalTo: searchBgView.topAnchor, constant: 0),
      resetBtn.widthAnchor.constraint(equalToConstant: 70),
      resetBtn.heightAnchor.constraint(equalToConstant: 70),
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
    searchBgView.addSubview(searchCancelBtn)

    searchViewConstraint = searchTextField.rightAnchor.constraint(equalTo: searchBgView.rightAnchor, constant: -12)
    searchViewConstraint?.isActive = true
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: searchBgView.leftAnchor, constant: 12),
      searchTextField.topAnchor.constraint(equalTo: searchBgView.topAnchor, constant: 12),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])
    NSLayoutConstraint.activate([
      searchCancelBtn.rightAnchor.constraint(equalTo: searchBgView.rightAnchor, constant: -12),
      searchCancelBtn.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
      searchCancelBtn.widthAnchor.constraint(equalToConstant: 52),
      searchCancelBtn.heightAnchor.constraint(equalToConstant: 56),
    ])
    searchBgView.backgroundColor = .white
  }

  //    MARK: 键盘通知相关操作

  func keyBoardWillShow(_ notification: Notification) {
    foldKeyBoard = false
    searchCancelBtn.isHidden = false
    searchViewConstraint?.constant = -64
    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    layoutInputView(offset: keyboardRect.size.height)
    UIView.animate(withDuration: 0.25, animations: {
      self.view.layoutIfNeeded()
    })
  }

  func keyBoardWillHide(_ notification: Notification) {
    foldKeyBoard = true
  }

  private func layoutInputView(offset: CGFloat) {
    tableViewBottomConstraint?.constant = defaultTableHeight + offset
  }

  lazy var backBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("chat_map_back"), for: .normal)
    button.setImage(coreLoader.loadImage("chat_map_back"), for: .highlighted)
    button.addTarget(self, action: #selector(backBackClick), for: .touchUpInside)
    return button
  }()

  lazy var cancelBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(.white, for: .normal)
    button.setTitle(chatLocalizable("cancel"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
    return button
  }()

  lazy var searchCancelBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(chatLocalizable("search_cancel"), for: .normal)
    button.setTitleColor(UIColor.ne_emptyTitleColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    button.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  lazy var resetBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("map_reset_normal"), for: .normal)
    button.setImage(coreLoader.loadImage("map_reset_select"), for: .selected)
    button.addTarget(self, action: #selector(resetClick), for: .touchUpInside)
    return button
  }()

  lazy var sendBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(.white, for: .normal)
    button.setTitle(chatLocalizable("send"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.backgroundColor = UIColor.ne_blueText
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(sendBtnClick), for: .touchUpInside)
    return button
  }()

  lazy var guideBottomView: NEMapGuideBottomView = {
    let bottomView = NEMapGuideBottomView(frame: CGRect.zero)
    bottomView.translatesAutoresizingMaskIntoConstraints = false
    bottomView.delegate = self
    return bottomView
  }()

  lazy var emptyImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.image = coreLoader.loadImage("chat_map_empty")
    image.isHidden = true
    return image
  }()

  lazy var emptyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_greyText
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.text = chatLocalizable("search_result_empty")
    label.isHidden = true
    return label
  }()

  lazy var emptyTip: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.text = chatLocalizable("no_map_plugin")
    label.textColor = UIColor.ne_greyText
    return label
  }()

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NEMapAddressCell.self,
      forCellReuseIdentifier: reuseId
    )
    tableView.rowHeight = 72
    tableView.backgroundColor = .white
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  private lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.contentMode = .center
    textField.leftView = UIImageView(image: UIImage
      .ne_imageNamed(name: "search"))
    textField.leftViewMode = .always
    textField.placeholder = chatLocalizable("search_place")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.layer.cornerRadius = 8
    textField.backgroundColor = .ne_lightBackgroundColor
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)
    return textField
  }()

  lazy var searchBgView: UIView = {
    let bgView = UIView()
    bgView.translatesAutoresizingMaskIntoConstraints = false
    return bgView
  }()

  func resetClick() {
    if let map = mapView {
      resetBtn.isSelected = false
      if mapType == .detail, let map = mapView {
        NEChatKitClient.instance.delegate?.setMapCenter?(mapview: map)
        return
      }
      searchTextField.text = nil
      toSearchLocalWithMapView()
      NEChatKitClient.instance.delegate?.setMapCenter?(mapview: map)
      currentIndex = 0
      tableView.reloadData()
    }
  }

  func cancelSearch() {
    UIApplication.shared.keyWindow?.endEditing(true)
    UIView.animate(withDuration: 0.25, animations: {
      self.searchCancelBtn.isHidden = true
      self.searchViewConstraint?.constant = -12
      self.tableViewBottomConstraint?.constant = self.defaultTableHeight
    })
    searchTextField.text = ""
    NELog.infoLog(className(), desc: "toSearchCurrentUserLocation cancel earch call")

    toSearchCurrentUserLocation()
    NEChatKitClient.instance.delegate?.setMapCenter?(mapview: mapView)
  }

  func showEmptyView() {
    emptyImage.isHidden = false
    emptyLabel.isHidden = false
  }

  func hideEmptyView() {
    emptyImage.isHidden = true
    emptyLabel.isHidden = true
  }

  func backBackClick() {
    navigationController?.popViewController(animated: true)
  }

  func cancelBtnClick() {
    navigationController?.popViewController(animated: true)
  }

  func sendBtnClick() {
    var model: ChatLocaitonModel?

    if model == nil {
      if locations.count > currentIndex {
        model = locations[currentIndex]
      }
    }

    if model == nil {
      model = currentModel
    }

    if let m = model {
      navigationController?.popViewController(animated: false)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
        if let block = self.completion {
          block(m)
        }
      }))
    } else {
      showToast(chatLocalizable("no_location"))
    }
  }

  func searchTextFieldChange(textfield: SearchTextField) {
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
        NEChatKitClient.instance.delegate?.searchPosition?(key: text, completion: { models, error in
          weakSelf?.loadModels(models: models)
        })
      }
    }
    if searchText.count <= 0 {
      if let map = mapView {
        NEChatKitClient.instance.delegate?.setMapCenter?(mapview: map)
      }
      toSearchLocalWithMapView()
    }
  }

  func toSearchLocalWithMapView() {
    guard let map = mapView else {
      return
    }
    weak var weakSelf = self
    NEChatKitClient.instance.delegate?.searchMapCenter?(mapview: map, completion: { models, error in
      if let text = weakSelf?.searchTextField.text, text.count > 0 {
        return
      }
      weakSelf?.loadModels(models: models)
    })
  }

  func toSearchCurrentUserLocation() {
    weak var weakSelf = self
    let className = className()
    NEChatKitClient.instance.delegate?.searchRoundPosition?(completion: { models, error in
      NELog.infoLog(className, desc: "toSearchCurrentUserLocation end : \(models) error:  \(error?.localizedDescription ?? "") current text input : \(weakSelf?.searchTextField.text ?? "")")
      if let text = weakSelf?.searchTextField.text, text.count > 0 {
        return
      }
      weakSelf?.loadModels(models: models)
    })
  }

  // MARK: NEMapGuideBottomViewDelegate

  open func didClickGuide() {
    showBottomSelectAlert(firstContent: chatLocalizable("gaode_map"), secondContent: chatLocalizable("tencent_map")) { value in

      if value == 0 {
        if let gaodeApp = URL(string: "iosamap://") {
          if UIApplication.shared.canOpenURL(gaodeApp) == true {
            if let url = "iosamap://viewMap?sourceApplication=yunxin_im&backScheme=im_uikit&poiname=\(self.locationTitle ?? "")&lat=\(self.currentPoint.x)&lon=\(self.currentPoint.y)&dev=1".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
              print("jump url : ", url)
              if let jumpUrl = URL(string: url) {
                if #available(iOS 10.0, *) {
                  UIApplication.shared.open(jumpUrl)
                } else {
                  UIApplication.shared.openURL(jumpUrl)
                }
              }
            }

          } else if let url = URL(string: "https://itunes.apple.com/us/app/gao-tu-zhuan-ye-shou-ji-tu/id461703208?mt=8") {
            if #available(iOS 10.0, *) {
              UIApplication.shared.open(url)
            } else {
              UIApplication.shared.openURL(url)
            }
          }
        }
      } else if value == 1 {
        if let gaodeApp = URL(string: "qqmap://") {
          if UIApplication.shared.canOpenURL(gaodeApp) == true {
            if let url = "qqmap://map/marker?marker=coord:\(self.currentPoint.x),\(self.currentPoint.y);title:\(self.locationTitle ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
              print("jump url : ", url)
              if let jumpUrl = URL(string: url) {
                if #available(iOS 10.0, *) {
                  UIApplication.shared.open(jumpUrl)
                } else {
                  UIApplication.shared.openURL(jumpUrl)
                }
              }
            }

          } else if let url = URL(string: "https://apps.apple.com/cn/app/%E8%85%BE%E8%AE%AF%E5%9C%B0%E5%9B%BE-%E8%B7%AF%E7%BA%BF%E8%A7%84%E5%88%92-%E5%AF%BC%E8%88%AA%E6%89%93%E8%BD%A6%E5%87%BA%E8%A1%8C/id481623196") {
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

  open func loadModels(models: [ChatLocaitonModel]) {
    currentIndex = 0
    locations.removeAll()
    if let keyword = searchTextField.text, keyword.count > 0 {
      models.forEach { model in
        model.attribute = model.title.highlight(keyWords: keyword, highlightColor: UIColor.ne_blueText)
      }
    } else {
      models.forEach { model in
        model.attribute = NSMutableAttributedString(string: model.title)
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

extension NEDetailMapController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    locations.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseId,
      for: indexPath
    ) as! NEMapAddressCell
    let model = locations[indexPath.row]
    cell.configure(model, currentIndex == indexPath.row)
    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let preiousCell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? NEMapAddressCell {
      preiousCell.selectImg.isHidden = true
    }
    if let currentCell = tableView.cellForRow(at: indexPath) as? NEMapAddressCell {
      currentCell.selectImg.isHidden = false
    }
    let model = locations[indexPath.row]
    if let map = mapView {
      NEChatKitClient.instance.delegate?.setMapviewLocation?(lat: model.lat, lng: model.lng, mapview: map)
    }
    currentIndex = indexPath.row
    refreshCurrentCache()
  }
}

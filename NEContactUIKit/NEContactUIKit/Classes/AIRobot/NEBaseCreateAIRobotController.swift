// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseCreateAIRobotController: NEContactBaseViewController,
  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  public let viewModel = CreateAIRobotViewModel()

  /// 编辑模式：传入已有 bot 则为编辑，否则为新建
  public var editingBot: V2NIMUserAIBot?

  /// 编辑成功后的回调（由 Detail 页通过路由参数注入），用于更新 Detail 页显示
  public var onEditSavedCallback: ((V2NIMUserAIBot) -> Void)?

  /// 新建模式下的默认昵称（由路由参数注入，格式如 Bot_1、Bot_2 等）
  public var defaultName: String?

  /// 创建成功后需自动绑定的 qrCode（由绑定页通过路由参数注入，为 nil 则跳过自动绑定）
  public var autoBindQrCode: String?

  /// 自动绑定的来源绑定页（创建+绑定成功后需从导航栈移除它）
  public weak var autoBindSourceVC: UIViewController?

  /// 是否已有头像（本地选图 或 编辑模式下的网络头像），为 true 时编辑昵称不更新头像占位
  private var hasExistingAvatar: Bool = false

  // MARK: - 子视图

  /// 整体卡片容器（白色圆角）
  public lazy var cardView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  // -- 头像行 --

  /// 头像行容器
  public lazy var avatarRowView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .clear
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAvatarRow))
    v.addGestureRecognizer(tap)
    return v
  }()

  /// 头像标签
  public lazy var avatarTitleLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_avatar")
    l.font = .systemFont(ofSize: 16)
    l.textColor = .ne_darkText
    return l
  }()

  /// 头像视图
  public lazy var avatarImageView: NEUserHeaderView = {
    let v = NEUserHeaderView(frame: .zero)
    v.translatesAutoresizingMaskIntoConstraints = false
    v.layer.cornerRadius = 20
    v.clipsToBounds = true
    v.titleLabel.font = .systemFont(ofSize: 14)
    v.titleLabel.textColor = .white
    return v
  }()

  /// 头像行右侧箭头
  public lazy var avatarArrowView: UIImageView = {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  /// 头像/昵称之间的分隔线
  public lazy var sectionDivider: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .funContactLineBorderColor
    return v
  }()

  // -- 昵称行 --

  /// 昵称行容器（点击进入昵称编辑页）
  public lazy var nameRowView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .clear
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapNameRow))
    v.addGestureRecognizer(tap)
    return v
  }()

  /// 昵称标签
  public lazy var nameTitleLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_name")
    l.font = .systemFont(ofSize: 16)
    l.textColor = .ne_darkText
    return l
  }()

  /// 昵称当前值（灰色，右对齐）
  public lazy var nicknameValueLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = .systemFont(ofSize: 16)
    l.textColor = UIColor(hexString: "999999")
    l.textAlignment = .right
    return l
  }()

  /// 昵称行右侧箭头
  public lazy var nicknameArrowView: UIImageView = {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  /// 保留为 backing store，供 viewModel 和 didTapSave 使用（不加入视图层级）
  public lazy var nameTextField: UITextField = {
    let tf = UITextField()
    tf.font = .systemFont(ofSize: 16)
    tf.textColor = .ne_darkText
    tf.textAlignment = .right
    tf.placeholder = localizable("ai_robot_name_placeholder")
    tf.returnKeyType = .done
    tf.addTarget(self, action: #selector(nameTextFieldChanged), for: .editingChanged)
    tf.delegate = self
    return tf
  }()

  // MARK: - 生命周期

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupCreateRobotUI()
    // 新建模式：自动填充默认昵称
    if editingBot == nil, let name = defaultName, !name.isEmpty {
      nameTextField.text = name
      viewModel.name = name
      nicknameValueLabel.text = name
      updateAvatarPlaceholderIfNeeded(name: name)
    }
    // 编辑模式：修改标题并预填充昵称和头像
    if let bot = editingBot {
      title = localizable("edit_ai_robot")
      let name = bot.name ?? ""
      nameTextField.text = name
      viewModel.name = name
      nicknameValueLabel.text = name
      let shortName = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
      avatarImageView.configHeadData(headUrl: bot.icon, name: shortName, uid: bot.accid)
      // 编辑模式下已有网络头像，标记为已有头像，编辑昵称时不覆盖
      if let icon = bot.icon, !icon.isEmpty {
        hasExistingAvatar = true
      }
    }
  }

  // MARK: - UI 构建（子类可 override 定制风格）

  /// 构建页面 UI，子类可覆写此方法追加/修改样式
  open func setupCreateRobotUI() {
    title = localizable("create_ai_robot")

    // 导航右侧"保存"按钮
    navigationView.setMoreButtonTitle(localizable("save"), saveButtonColor())
    navigationView.addMoreButtonTarget(target: self, selector: #selector(didTapSave))

    // 页面背景
    view.backgroundColor = pageBackgroundColor()

    // 卡片
    view.addSubview(cardView)
    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      cardView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      cardView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
    ])

    // 头像行
    cardView.addSubview(avatarRowView)
    NSLayoutConstraint.activate([
      avatarRowView.topAnchor.constraint(equalTo: cardView.topAnchor),
      avatarRowView.leftAnchor.constraint(equalTo: cardView.leftAnchor),
      avatarRowView.rightAnchor.constraint(equalTo: cardView.rightAnchor),
      avatarRowView.heightAnchor.constraint(equalToConstant: 74),
    ])

    avatarRowView.addSubview(avatarTitleLabel)
    NSLayoutConstraint.activate([
      avatarTitleLabel.leftAnchor.constraint(equalTo: avatarRowView.leftAnchor, constant: 16),
      avatarTitleLabel.centerYAnchor.constraint(equalTo: avatarRowView.centerYAnchor),
    ])

    avatarRowView.addSubview(avatarArrowView)
    NSLayoutConstraint.activate([
      avatarArrowView.rightAnchor.constraint(equalTo: avatarRowView.rightAnchor, constant: -16),
      avatarArrowView.centerYAnchor.constraint(equalTo: avatarRowView.centerYAnchor),
      avatarArrowView.widthAnchor.constraint(equalToConstant: 16),
      avatarArrowView.heightAnchor.constraint(equalToConstant: 16),
    ])

    avatarRowView.addSubview(avatarImageView)
    NSLayoutConstraint.activate([
      avatarImageView.rightAnchor.constraint(equalTo: avatarArrowView.leftAnchor, constant: -8),
      avatarImageView.centerYAnchor.constraint(equalTo: avatarRowView.centerYAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 40),
      avatarImageView.heightAnchor.constraint(equalToConstant: 40),
    ])

    // 新建模式初始占位（无文字）
    avatarImageView.configHeadData(headUrl: nil, name: "", uid: "")

    // 分隔线
    cardView.addSubview(sectionDivider)
    NSLayoutConstraint.activate([
      sectionDivider.topAnchor.constraint(equalTo: avatarRowView.bottomAnchor),
      sectionDivider.leftAnchor.constraint(equalTo: cardView.leftAnchor, constant: 16),
      sectionDivider.rightAnchor.constraint(equalTo: cardView.rightAnchor),
      sectionDivider.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    // 昵称行（作为卡片底部）
    cardView.addSubview(nameRowView)
    NSLayoutConstraint.activate([
      nameRowView.topAnchor.constraint(equalTo: sectionDivider.bottomAnchor),
      nameRowView.leftAnchor.constraint(equalTo: cardView.leftAnchor),
      nameRowView.rightAnchor.constraint(equalTo: cardView.rightAnchor),
      nameRowView.heightAnchor.constraint(equalToConstant: 56),
      nameRowView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
    ])

    nameRowView.addSubview(nameTitleLabel)
    NSLayoutConstraint.activate([
      nameTitleLabel.leftAnchor.constraint(equalTo: nameRowView.leftAnchor, constant: 16),
      nameTitleLabel.centerYAnchor.constraint(equalTo: nameRowView.centerYAnchor),
    ])

    // 右侧箭头
    nameRowView.addSubview(nicknameArrowView)
    NSLayoutConstraint.activate([
      nicknameArrowView.rightAnchor.constraint(equalTo: nameRowView.rightAnchor, constant: -16),
      nicknameArrowView.centerYAnchor.constraint(equalTo: nameRowView.centerYAnchor),
      nicknameArrowView.widthAnchor.constraint(equalToConstant: 16),
      nicknameArrowView.heightAnchor.constraint(equalToConstant: 16),
    ])

    // 右侧昵称值（灰色）
    nameRowView.addSubview(nicknameValueLabel)
    NSLayoutConstraint.activate([
      nicknameValueLabel.rightAnchor.constraint(equalTo: nicknameArrowView.leftAnchor, constant: -8),
      nicknameValueLabel.centerYAnchor.constraint(equalTo: nameRowView.centerYAnchor),
      nicknameValueLabel.leftAnchor.constraint(greaterThanOrEqualTo: nameTitleLabel.rightAnchor, constant: 12),
    ])

    setupCardBorderRadius()
  }

  /// 卡片圆角设置，子类可 override
  open func setupCardBorderRadius() {
    cardView.layer.cornerRadius = 8
    cardView.clipsToBounds = true
  }

  /// 页面背景色 — 子类 override
  open func pageBackgroundColor() -> UIColor {
    .funContactNavigationBackgroundColor
  }

  /// 保存按钮颜色 — 子类 override（Normal: normalContactThemeColor，Fun: funContactThemeColor）
  open func saveButtonColor() -> UIColor {
    .normalContactThemeColor
  }

  /// 卡片水平边距 — 子类 override
  open func cardHorizontalMargin() -> CGFloat { 0 }

  // MARK: - Actions

  open func didTapAvatarRow() {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: commonLocalizable("take_picture"), style: .default) { [weak self] _ in
      self?.openCamera()
    })
    sheet.addAction(UIAlertAction(title: commonLocalizable("select_from_album"), style: .default) { [weak self] _ in
      self?.openPhotoLibrary()
    })
    sheet.addAction(UIAlertAction(title: commonLocalizable("cancel"), style: .cancel))
    present(sheet, animated: true)
  }

  open func didTapSave() {
    // 网络检查
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    view.endEditing(true)
    viewModel.name = nameTextField.text ?? ""
    view.isUserInteractionEnabled = false

    if let bot = editingBot {
      let accid = bot.accid
      viewModel.updateRobot(accid: accid) { [weak self] error in
        guard let strongSelf = self else { return }
        DispatchQueue.main.async {
          strongSelf.view.isUserInteractionEnabled = true
          if let error = error {
            strongSelf.showToast(robotErrorMessage(error))
            return
          }
          strongSelf.viewModel.fetchUpdatedBot(accid: accid) { [weak strongSelf] updatedBot in
            guard let s = strongSelf else { return }
            // 更新后同步 Manager 缓存
            if let updatedBot = updatedBot {
              NEAIRobotManager.shared.update(updatedBot)
              s.onEditSavedCallback?(updatedBot)
            }
            s.navigationController?.popViewController(animated: true)
          }
        }
      }
    } else {
      viewModel.createRobot { [weak self] error in
        guard let strongSelf = self else { return }
        DispatchQueue.main.async {
          strongSelf.view.isUserInteractionEnabled = true
          if let error = error {
            strongSelf.showToast(localizable("ai_robot_create_failed"))
            return
          }
          guard let bot = strongSelf.viewModel.createdBot,
                let nav = strongSelf.navigationController else {
            strongSelf.navigationController?.popViewController(animated: true)
            return
          }
          // 创建成功，加入 Manager 缓存
          NEAIRobotManager.shared.add(bot)
          if let qrCode = strongSelf.autoBindQrCode, !qrCode.isEmpty {
            // 来自扫码绑定页的新建流程：创建后自动绑定
            strongSelf.view.isUserInteractionEnabled = false
            AIRepo.shared.bindUserAIBot(accid: bot.accid, token: bot.token ?? "", qrCode: qrCode) { [weak strongSelf] error in
              guard let s = strongSelf else { return }
              DispatchQueue.main.async {
                s.view.isUserInteractionEnabled = true
                if let error = error {
                  s.showToast(robotErrorMessage(error))
                  return
                }
                var vcs = nav.viewControllers
                vcs.removeAll(where: { $0 === s || $0 === s.autoBindSourceVC })
                nav.setViewControllers(vcs, animated: false)
                Router.shared.use(ContactAIRobotDetailRouter,
                                  parameters: ["nav": nav, "bot": bot, "animated": true],
                                  closure: nil)
              }
            }
          } else {
            nav.popViewController(animated: false)
            Router.shared.use(ContactAIRobotDetailRouter,
                              parameters: ["nav": nav, "bot": bot, "animated": true],
                              closure: nil)
          }
        }
      }
    }
  }

  /// 点击昵称行 → 通过 Router push 昵称编辑页，保存后同步回本页
  open func didTapNameRow() {
    Router.shared.use(ContactRobotNicknameEditRouter,
                      parameters: ["nav": navigationController as Any,
                                   "currentName": nameTextField.text ?? "",
                                   "animated": true,
                                   "onSaved": { [weak self] (name: String) in
                                     guard let self = self else { return }
                                     self.nameTextField.text = name
                                     self.viewModel.name = name
                                     self.nicknameValueLabel.text = name
                                     self.updateAvatarPlaceholderIfNeeded(name: name)
                                   }],
                      closure: nil)
  }

  open func nameTextFieldChanged() {
    let name = nameTextField.text ?? ""
    viewModel.name = name
    updateAvatarPlaceholderIfNeeded(name: name)
  }

  /// 无头像时，用当前昵称后两字更新头像占位文字（与全局 getShortName 规则一致）
  /// 已有头像（本地选图或编辑模式网络头像）时不更新，避免覆盖
  open func updateAvatarPlaceholderIfNeeded(name: String) {
    guard !hasExistingAvatar else { return }
    let shortName = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
    avatarImageView.configHeadData(headUrl: nil, name: shortName, uid: "")
  }

  // MARK: - 相册/相机

  open func openPhotoLibrary() {
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.allowsEditing = true
    picker.delegate = self
    present(picker, animated: true)
  }

  open func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.allowsEditing = true
    picker.delegate = self
    present(picker, animated: true)
  }

  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)
    let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
    guard let image = image, let data = image.jpegData(compressionQuality: 0.8) else { return }

    let tmpURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("robot_avatar_\(Int(Date().timeIntervalSince1970)).jpg")
    try? data.write(to: tmpURL)

    viewModel.avatarLocalPath = tmpURL.path
    hasExistingAvatar = true
    avatarImageView.image = image
    avatarImageView.setTitle("")
  }
}

// MARK: - UITextFieldDelegate

extension NEBaseCreateAIRobotController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

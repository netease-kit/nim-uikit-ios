
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitTeamUI
import NEKitChatUI
import NIMSDK

class PersonInfoViewController: NEBaseViewController {
    
    public var cellClassDic = [SettingCellType.SettingSubtitleCell.rawValue: TeamSettingSubtitleCell.self, SettingCellType.SettingHeaderCell.rawValue: TeamSettingHeaderCell.self,
        SettingCellType.SettingSubtitleCustomCell.rawValue: TeamSettingRightCustomCell.self]
    private var viewModel = PersonInfoViewModel()
    private var className = "PersonInfoViewController"

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.getData()
        setupSubviews()
        initialConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func initialConfig(){
        self.title = "个人信息"
        view.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
        viewModel.delegate = self
        NIMSDK.shared().userManager.add(self)
    }
    
    func setupSubviews(){
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        cellClassDic.forEach { (key: Int, value: BaseTeamSettingCell.Type) in
            tableView.register(value, forCellReuseIdentifier: "\(key)")
        }
    }
    
    func showAlert(firstContent:String,secondContent:String,selectValue:@escaping ((_ value:NSInteger)->Void)) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        
        let first = UIAlertAction.init(title: firstContent, style: .default) { action in
            selectValue(0)
        }
        first.setValue(UIColor.init(hexString: "0x333333"), forKey: "_titleTextColor")

        let second = UIAlertAction.init(title: secondContent, style: .default) { action in
            selectValue(1)
        }
        second.setValue(UIColor.init(hexString: "0x333333"), forKey: "_titleTextColor")

        let cancel = UIAlertAction(title: "取消", style: .cancel) { action in
            
        }
        cancel.setValue(UIColor.init(hexString: "0x333333"), forKey: "_titleTextColor")

        alert.addAction(first)
        alert.addAction(second)
        alert.addAction(cancel)
 
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDatePicker() {
        self.view.addSubview(pickerView)
        
        weak var weakSelf = self
        pickerView.timeCallBack = {time in
            if let t = time {
                weakSelf?.viewModel.updateBirthday(birthDay: t, { error in
                    if error != nil {
                        weakSelf?.showToast("设置生日失败")
                    }
                })
            }

        }
        NSLayoutConstraint.activate([
            pickerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            pickerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 229),
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
        table.dataSource = self
        table.delegate = self
        table.separatorColor = .clear
        table.separatorStyle = .none
        table.sectionHeaderHeight = 12.0
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0.0
        }
        return table
    }()

    private lazy var pickerView:BirthdayDatePickerView = {
       let picker = BirthdayDatePickerView()
        picker.backgroundColor = .white
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    deinit {
        NIMSDK.shared().userManager.remove(self)
    }
}


extension PersonInfoViewController:NIMUserManagerDelegate {
    
    func onUserInfoChanged(_ user: NIMUser) {
        if user.userId == CoreKitIMEngine.instance.imAccid {
            viewModel.getData()
            tableView.reloadData()
        }
    }
    
}


extension PersonInfoViewController:UINavigationControllerDelegate {
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        let image : UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        uploadHeadImage(image: image)
        self.dismiss(animated: true, completion: nil)
    }
    
    public func uploadHeadImage(image:UIImage){

        self.view.makeToastActivity(.center)
        weak var weakSelf = self
        if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
             let filePath = NSHomeDirectory().appending("/Documents/").appending(CoreKitIMEngine.instance.imAccid)
             let succcess =  imageData.write(toFile: filePath, atomically: true)
            if succcess {
                NIMSDK.shared().resourceManager.upload(filePath, scene: NIMNOSSceneTypeAvatar, progress: nil) { urlString, error in
                    if error == nil {
                        weakSelf?.viewModel.updateAvatar(avatar: urlString ?? "", { error in
                            if error != nil {
                                weakSelf?.showToast("修改头像失败失败")
                            }
                        })
                       
                    }else {
                        QChatLog.errorLog(weakSelf?.className ?? "", desc: "❌upload image failed,error = \(error!)")
                    }
                    self.view.hideToastActivity()
                }
                
            }
        }
    }
}

extension PersonInfoViewController:PersonInfoViewModelDelegate {


    func didClickHeadImage() {
        showBottomAlert(self)
    }
    
    func didClickNickName(name: String) {
        let ctrl = InputPersonInfoController()
        ctrl.configTitle(editType: .nickName)
        ctrl.contentText = name
        weak var weakSelf = self
        ctrl.callBack = {editText in
            weakSelf?.viewModel.updateNickName(name: editText, { error in
                if error != nil {
                    weakSelf?.showToast("修改昵称失败")
                }
            })
        }
        navigationController?.pushViewController(ctrl, animated: true)
    }

    func didClickGender() {
        var sex = NIMUserGender.unknown
        weak var weakSelf = self
        showAlert(firstContent: "男", secondContent: "女") { value in
            sex = value == 0 ? .male : .female
            weakSelf?.viewModel.updateSex(sex: sex) { error in
                if error != nil {
                    weakSelf?.showToast("修改性别失败")
                }
            }
        }
    }
    
    func didClickBirthday() {
        showDatePicker()
    }
    
    func didClickMobile(mobile: String) {
        let ctrl = InputPersonInfoController()
        ctrl.configTitle(editType: .cellphone)
        ctrl.contentText = mobile
        weak var weakSelf = self
        ctrl.callBack = {editText in
            weakSelf?.viewModel.updateMobile(mobile: editText, { error in
                if error != nil {
                    weakSelf?.showToast("修改手机号失败")
                }
            })
        }
        navigationController?.pushViewController(ctrl, animated: true)
    }

    func didClickEmail(email: String) {
        let ctrl = InputPersonInfoController()
        ctrl.configTitle(editType: .email)
        ctrl.contentText = email
        weak var weakSelf = self
        ctrl.callBack = {editText in
            weakSelf?.viewModel.updateEmail(email: editText, { error in
                if error != nil {
                    weakSelf?.showToast("修改邮箱失败")
                }
            })
        }
        navigationController?.pushViewController(ctrl, animated: true)
    }

    func didClickSign(sign: String) {
        let ctrl = InputPersonInfoController()
        ctrl.configTitle(editType: .specialSign)
        ctrl.contentText = sign
        weak var weakSelf = self
        ctrl.callBack = {editText in
            weakSelf?.viewModel.updateSign(sign: editText, { error in
                if error != nil {
                    weakSelf?.showToast("修改签名失败")
                }
            })
        }
        navigationController?.pushViewController(ctrl, animated: true)
    }

    func didCopyAccount(account: String) {
        showToast("复制成功")
        UIPasteboard.general.string = account
    }
}



extension PersonInfoViewController:UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.sectionData.count > section {
            let model = viewModel.sectionData[section]
            return model.cellModels.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionData.count
    }



    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "\(model.type)", for: indexPath) as? BaseTeamSettingCell {
            cell.configure(model)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
        if let block = model.cellClick {
            block()
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
        return model.rowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        if viewModel.sectionData.count > section {
            let model = viewModel.sectionData[section]
            if model.cellModels.count > 0 {
                return 12.0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
        return header
    }
}

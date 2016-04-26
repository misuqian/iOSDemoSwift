//
//  QuickContactsViewController.swift
//  QuickContactsSwift
//
//  Created by 彭芊 on 16/4/26.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

let kUIEditUnknownContactRowHeight : CGFloat = 81.0

//TableRow类型枚举
enum TableRowSelected : Int{
    case kUIDisplayPickerRow=0,kUICreateNewContactRow,kUIDisplayContactRow,kUIEditUnknownContactRow
    
    var index : Int{
        return self.rawValue
    }
}

//使用AddressBookUI快速访问通讯录
class QuickContactsViewController: UITableViewController,ABPeoplePickerNavigationControllerDelegate,ABPersonViewControllerDelegate,
ABNewPersonViewControllerDelegate,ABUnknownPersonViewControllerDelegate{
    var addressBook : ABAddressBookRef! = nil
    var menuArray : NSMutableArray = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        addressBook = ABAddressBookCreateWithOptions(nil, nil).takeUnretainedValue()
        
        checkAddressBookAccess()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //检查应用通讯录授权状态
    func checkAddressBookAccess(){
        switch ABAddressBookGetAuthorizationStatus(){
        case .Authorized:
            accessGrantedForAddressBook()
        case .NotDetermined:
            requestAddressBookAccess()
        case .Denied,.Restricted:
            //alertView提醒
            let alert = UIAlertView(title: "Privacy Warning", message: "Permission was not granted for Contacts.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles:"")
            alert.show()
        }
    }

    //授权允许状况下执行
    func accessGrantedForAddressBook(){
        //读取Menu.plist
        let plistPath = NSBundle.mainBundle().pathForResource("Menu", ofType: "plist")
        self.menuArray = NSMutableArray(contentsOfFile: plistPath!)!
        self.tableView.reloadData()
    }
    
    //请求通讯录权限许可
    func requestAddressBookAccess(){
        //ABAddressBookRequestAccessCompletionHandler = (Bool, CFError!) -> Void
        ABAddressBookRequestAccessWithCompletion(self.addressBook, {
            if $0{
                if $1 == nil{
                    //刷新UI必须在主线程中
                    dispatch_async(dispatch_get_main_queue(), {
                        self.accessGrantedForAddressBook()
                    })
                }else{
                    print("request error\n\($1)")
                }
            }
        })
    }
    
    /**
     *  UITableView DataSource
     */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.menuArray.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("CellID")
        if indexPath.section < 2{
            if cell == nil{
                cell = UITableViewCell(style: .Default, reuseIdentifier: "CellID")
            }
            cell!.textLabel?.textAlignment = NSTextAlignment.Center //居中对齐
        }else{
            if cell == nil{
                cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "CellID")
            }
            cell!.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell!.detailTextLabel?.numberOfLines = 0 //自动换行
            cell!.detailTextLabel?.text = self.menuArray.objectAtIndex(indexPath.section).valueForKey("description") as! String
        }
        cell!.textLabel?.text = self.menuArray.objectAtIndex(indexPath.section).valueForKey("title") as! String
        return cell!
    }
    
    /**
     *  UITableView Delegate
     */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == TableRowSelected.kUIEditUnknownContactRow.index ? kUIEditUnknownContactRowHeight : tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tableSelect = TableRowSelected(rawValue: indexPath.section)!
        switch tableSelect {
        case .kUIDisplayPickerRow:
            self.showPeoplePickerController()
        case .kUICreateNewContactRow:
            self.showNewPersonViewController()
        case .kUIDisplayContactRow:
            self.showPersonViewController()
        case .kUIEditUnknownContactRow:
            self.showUnknownPersonViewController()
        }
    }
    
    /**
     *  AddressBookUI应用
     */
    //显示所有的联系人
    func showPeoplePickerController(){
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self //ABPeoplePickerNavigationControllerDelegate
        picker.displayedProperties = [NSNumber(int: kABPersonPhoneProperty),NSNumber(int: kABPersonEmailProperty),NSNumber(int: kABPersonBirthdayProperty)] //设置显示属性
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    //显示并可以修改某一个人的信息
    func showPersonViewController(){
        let peoples = ABAddressBookCopyPeopleWithName(self.addressBook,"Appleseed").takeUnretainedValue() as [AnyObject]
        if peoples.count > 0{
            let person = peoples[0] 
            let picker = ABPersonViewController()
            picker.personViewDelegate = self //ABPersonViewControllerDelegate
            picker.displayedPerson = person //设置显示信息的人
            picker.allowsEditing = true
            self.navigationController?.pushViewController(picker, animated: true)
        }else{
            let alert = UIAlertView(title: "Error", message: "Could not find Appleseed in the Contacts application", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles:"")
            alert.show()
        }
    }
    
    //新建联系人
    func showNewPersonViewController(){
        let picker = ABNewPersonViewController()
        picker.newPersonViewDelegate = self //ABNewPersonViewControllerDelegate
        let navi = UINavigationController(rootViewController: picker) //创建一个以新建联系人窗口为根的导航视图
        self.presentViewController(navi, animated: true, completion: nil)
    }
    
    //给已存在的联系人添加信息
    func showUnknownPersonViewController(){
        let contact = ABPersonCreate()
        var anError : Unmanaged<CFErrorRef>? = nil
        let email = ABMultiValueCreateMutable(ABPropertyType.init(kABMultiStringPropertyType)).takeUnretainedValue()
        let didAdd = ABMultiValueAddValueAndLabel(email, "John-Appleseed@mac.com", kABOtherLabel, nil)
        if didAdd{
            ABRecordSetValue(contact.takeUnretainedValue(), kABPersonEmailProperty, email, &anError) // anError指针传入,outin
            if anError == nil{
                let picker = ABUnknownPersonViewController()
                picker.unknownPersonViewDelegate = self //ABUnknownPersonViewControllerDelegate
                picker.displayedPerson = contact.takeUnretainedValue()
                picker.allowsAddingToAddressBook = true 
                picker.allowsActions = true //开启可使用Facetime,电话
                picker.alternateName = "John Appleseed" //替换名字
                picker.title = "John Appleseed" //备注
                picker.message = "Company, Inc" //公司备注
                self.navigationController?.pushViewController(picker, animated: true)
            }
        }else{
            let alert = UIAlertView(title: "Error", message: "Could not create unknown user", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles:"")
            alert.show()
        }
    }
    
    /**
     *  ABPeoplePickerNavigationControllerDelegate
     */
    //返回true可以显示选择后的联系人详细信息
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, shouldContinueAfterSelectingPerson person: ABRecord) -> Bool {
        return true
    }
    
    //返回true可以开启实现默认的动作，比如打电话
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, shouldContinueAfterSelectingPerson person: ABRecord, property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return false
    }
    
    //取消按钮点击
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     *  ABPersonViewControllerDelegate
     */
    //返回false,联系人详细信息界面不能执行默认东西，比如打电话
    func personViewController(personViewController: ABPersonViewController, shouldPerformDefaultActionForPerson person: ABRecord, property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return false
    }
    
    /**
     *  ABNewPersonViewControllerDelegate
     */
    func newPersonViewController(newPersonView: ABNewPersonViewController, didCompleteWithNewPerson person: ABRecord?) {
        newPersonView.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     *  ABUnknownPersonViewControllerDelegate
     */
    //导航栏点击返回时响应
    func unknownPersonViewController(unknownCardViewController: ABUnknownPersonViewController, didResolveToPerson person: ABRecord?) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //返回false,使联系人详细界面的动作无法执行,比如打电话
    func unknownPersonViewController(personViewController: ABUnknownPersonViewController, shouldPerformDefaultActionForPerson person: ABRecord, property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return false
    }
    
}


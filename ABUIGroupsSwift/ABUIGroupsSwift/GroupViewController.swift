//
//  ViewController.swift
//  ABUIGroupsSwift
//
//  Created by 彭芊 on 16/4/25.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit
import AddressBook

//获取通讯录分组的主体VC
class GroupViewController: UITableViewController,GroupsDelegate{
    //存储从通讯录读取出的数据。相当于官方OC的MySource.m
    struct MySource {
        var name : String = ""
        var groups : [AnyObject]
        
        init(name : String,groups : [AnyObject]){
            self.name = name
            self.groups = groups
        }
    }
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    var addressBook : ABAddressBookRef! = nil
    var sourcesAndGroups = [MySource]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化ABAddressBook
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
        self.addButton.enabled = true
        //Navigation导航栏增加左边的编辑按钮
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        self.sourcesAndGroups = fetchGroupsInAddressBook(self.addressBook)
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
    
    //获取所有的分组信息
    func fetchGroupsInAddressBook(myAddressBook:ABAddressBookRef) -> [MySource]{
        var list = [MySource]()
        //获取通讯录里面所有的数据.Unmanaged结构类型需要自己管理内存释放
        let allSources = ABAddressBookCopyArrayOfAllSources(myAddressBook).takeUnretainedValue() 
        if CFArrayGetCount(allSources) > 0{
            for i in 0..<CFArrayGetCount(allSources){
                let unsafepoint = CFArrayGetValueAtIndex(allSources, i)
                let source = CFBridgingRetain(unsafeBitCast(unsafepoint, AnyObject.self))! as ABRecordRef
                //获取分组信息.Swift2.0后,也可以将CFArray强转[AnyObject]
                let results = ABAddressBookCopyArrayOfAllGroupsInSource(myAddressBook, source).takeUnretainedValue() as[AnyObject]
                if results.count > 0{
                    let sourceName = nameForSource(source)
                    let mysource = MySource(name: sourceName, groups: results)
                    list.append(mysource)
                }
            }
        }
        return list
    }
    
    //获取ABRecordRef的类型
    func nameForSource(source : ABRecordRef) -> String{
        //CFNumber可以强转NSNumber
        let sourceType = ABRecordCopyValue(source, kABSourceTypeProperty).takeUnretainedValue()
        if sourceType.intValue == nil{
            return ""
        }
        switch Int(sourceType.intValue){
        case kABSourceTypeLocal:
            return "On My Device"
        case kABSourceTypeExchange:
            return "Exchange server"
        case kABSourceTypeExchangeGAL:
            return "Exchange Global Address List"
        case kABSourceTypeMobileMe:
            return "MobileMe"
        case kABSourceTypeLDAP:
            return "LDAP server"
        case kABSourceTypeCardDAV:
            return "CardDAV server"
        case kABSourceTypeCardDAVSearch:
            return "Searchable CardDAV server"
        default:
            return ""
        }
    }
    
    /**
     *  UITable DataSource
     */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sourcesAndGroups.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sourcesAndGroups[section].name
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourcesAndGroups[section].groups.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("groupCell")
        if cell == nil{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "groupCell")
        }
        let source = sourcesAndGroups[indexPath.section]
        let group = CFBridgingRetain(source.groups[indexPath.row])! as ABRecordRef
        
        cell!.textLabel?.text = ABRecordCopyCompositeName(group).takeUnretainedValue() as? String
        return cell!
    }
    
    /**
     *  UITable Delegate,增加滑动删除功能
     */
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.navigationItem.rightBarButtonItem?.enabled = !editing
    }
    
    //处理删除分组操作
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if UITableViewCellEditingStyle.Delete == editingStyle{
            var source = self.sourcesAndGroups[indexPath.section]
            let group = CFBridgingRetain(source.groups[indexPath.row])! as ABRecordRef
            
            //删除通讯录中记录
            source.groups.removeAtIndex(indexPath.row)
            self.sourcesAndGroups[indexPath.section] = source
            ABAddressBookRemoveRecord(self.addressBook, group, nil)
            ABAddressBookSave(self.addressBook, nil)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
            //section中数据全部删除，则删除这个section
            if source.groups.count == 0{
                self.sourcesAndGroups.removeAtIndex(indexPath.section)
                tableView.deleteSections(NSIndexSet(index: indexPath.row), withRowAnimation: .Fade)
            }
        }
    }
    
    /**
     监听segue
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addGroup"{
            let sourceVC = segue.destinationViewController as! AddGroupViewController
            sourceVC.groupDelegate = self // 设置GroupsDelegate
        }
    }
    
    /**
     GroupsDelegate,添加Group
     */
    func addNewGroups(name : String){
        var sourceFound = false
        let newGroup = ABGroupCreate().takeUnretainedValue() as ABRecordRef
        ABRecordSetValue(newGroup, kABGroupNameProperty, name, nil)
        
        //增加Group
        ABAddressBookAddRecord(self.addressBook, newGroup, nil)
        ABAddressBookSave(self.addressBook, nil)
        
        let groupSource = ABGroupCopySource(newGroup).takeUnretainedValue() as ABRecordRef
        let sourceName = nameForSource(groupSource)
        
        //如果存在这个分组了,直接加入数据
        for i in 0..<self.sourcesAndGroups.count{
            var source = sourcesAndGroups[i]
            if source.name == sourceName{
                source.groups.append(newGroup)
                self.sourcesAndGroups[i] = source
                sourceFound = true
                //break
            }
        }
        
        //如果没有相同名字分组,直接增加
        if !sourceFound{
            var arr = [AnyObject]()
            arr.append(newGroup)
            let newSource = MySource(name: sourceName, groups: arr)
            self.sourcesAndGroups.append(newSource)
        }
        self.tableView.reloadData()
    }
}


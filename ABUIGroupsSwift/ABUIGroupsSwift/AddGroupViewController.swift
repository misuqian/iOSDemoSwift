//
//  AddGroupViewController.swift
//  ABUIGroupsSwift
//
//  Created by 彭芊 on 16/4/25.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit

protocol GroupsDelegate {
    func addNewGroups(name : String)
}

//增加新的分组VC
class AddGroupViewController: UIViewController,UITextFieldDelegate{
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    var groupDelegate : GroupsDelegate! //VC之间采用协议通信
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.delegate = self
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        //取消聚焦，回收键盘
        textField.resignFirstResponder()
        doneButton.enabled = textField.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0
        return true
    }
    
    //输入框内容为空不能增加分组
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        if string == ""{
            doneButton.enabled = textField.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 1
        }else{
            doneButton.enabled = textField.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0
        }
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        doneButton.enabled = false
        return true
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.textField.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        self.groupDelegate.addNewGroups(self.textField.text!)
        self.textField.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

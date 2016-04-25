//
//  ViewController.swift
//  ZoomingPDFViewerSwift
//
//  Created by 彭芊 on 16/4/24.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit

// 根视图，用来创建PageController并管理视图切换
class RootViewController: UIViewController,UIPageViewControllerDelegate,UIPageViewControllerDataSource{
    //全局声明初始化pageController.PageCurl将展示翻页效果(page-turning),Scroll展示滚动页面效果(page-scrolling)
    private var pageController : UIPageViewController = UIPageViewController(transitionStyle: .PageCurl, navigationOrientation: .Horizontal, options: nil)
    
    private var pdf : CGPDFDocument? = nil
    private var numberPages : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readPDF()
        
        //设置pageController
        self.pageController.delegate = self
        self.pageController.dataSource = self //官方OC版本将这部分封装到了modelController中
        let startingViewController = viewControllerAtIndex(0, storyBoard: self.storyboard!)
        self.pageController.setViewControllers([startingViewController], direction: .Forward, animated: false, completion: nil)
        
        self.addChildViewController(self.pageController)
        self.view.addSubview(self.pageController.view)
        
        let pageViewRect = self.view.bounds
        self.pageController.view.frame = pageViewRect
        self.pageController.didMoveToParentViewController(self)
        self.view.gestureRecognizers = self.pageController.gestureRecognizers
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     UIPageViewControllerDataSource
     */
    //返回当前页面的前一页ViewController
    internal func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?{
        //获取当前VC的index
        var index = self.indexOfViewController(viewController as! DataViewController)
        //NSNotFound是一个在32位和64位上不一样的int,一般声明为UInt最大值,用来表示没有找到
        if index == 0 || index == NSNotFound{
            return nil
        }
        index -= 1
        return self.viewControllerAtIndex(index, storyBoard: self.storyboard!)
    }
    
    //返回当前页面的后一页ViewController
    internal func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?{
        var index = self.indexOfViewController(viewController as! DataViewController)
        //NSNotFound是一个在32位和64位上不一样的int,用来表示没有找到
        if index == NSNotFound{
            return nil
        }
        index += 1
        if index == self.numberPages{
            return nil
        }
        return self.viewControllerAtIndex(index, storyBoard: self.storyboard!)
    }
    
    /**
     UIPageViewControllerDelegate
     */
    //当屏幕转向变化的时候调用，仅在pageStyle为PageCurl时生效
    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        let currentVC = self.pageController.viewControllers![0] as! DataViewController
        var VCArray = [currentVC]
        //竖屏或者iPhone,返回SpineLocation.Min(页面只有一个page),doubleSided双页设置flase,并重置pageController的VC数组只含当前页面
        if orientation == UIInterfaceOrientation.Portrait || UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone{
            self.pageController.setViewControllers(VCArray, direction: .Forward, animated: true, completion: nil)
            self.pageController.doubleSided = false
            return UIPageViewControllerSpineLocation.Min
        }
        
        //横屏或者iPad设备,返回SpineLocation.Mid(页面有两个page),pageController的VC数组需要两个以上VC.判断当前页位置,偶数加载当前和之后VC,奇数加载当前和之前的VC(当前页位置从0开始)
        let VCIndex = self.indexOfViewController(currentVC)
        if VCIndex % 2 == 0 {
            let nextVC = self.pageViewController(self.pageController, viewControllerAfterViewController: currentVC) as! DataViewController
            VCArray.append(nextVC)
        }else{
            let preVC = self.pageViewController(self.pageController, viewControllerBeforeViewController: currentVC) as! DataViewController
            VCArray.removeAll()
            VCArray.append(preVC)
            VCArray.append(currentVC)
        }
        self.pageController.setViewControllers(VCArray, direction: .Forward, animated: true, completion: nil)
        return UIPageViewControllerSpineLocation.Mid
    }
    
    
    /**
     相当于官方OC版中的ModelController
     */
    //读取PDF
    func readPDF(){
        let url = NSBundle.mainBundle().URLForResource("input_pdf", withExtension: ".pdf")
        pdf = CGPDFDocumentCreateWithURL(url)
        numberPages = CGPDFDocumentGetNumberOfPages(pdf)
        if numberPages % 2 == 1 {
            numberPages += 1
        }
    }
    
    func viewControllerAtIndex(index : Int,storyBoard : UIStoryboard) -> DataViewController{
        //storyboard中VC的identify inspector设置StoryBoard Id为DataViewController
        let dataViewController = storyBoard.instantiateViewControllerWithIdentifier("DataViewController") as! DataViewController
        dataViewController.numberPages = index + 1
        dataViewController.pdf = self.pdf!
        return dataViewController
    }
    
    func indexOfViewController(dataViewController : DataViewController) -> Int{
        return dataViewController.numberPages - 1
    }
    
    //隐藏顶部状态栏
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}


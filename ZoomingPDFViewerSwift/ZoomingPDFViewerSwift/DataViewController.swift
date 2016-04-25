//
//  DataViewController.swift
//  ZoomingPDFViewerSwift
//
//  Created by 彭芊 on 16/4/24.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit

//PDF显示视图。通过ScrollView中嵌套绘制PDF的View实现(ScrollView的作用是为了放缩和上下滑浏览)
class DataViewController: UIViewController {
    
    @IBOutlet weak var scrollView: PDFScrollView!
    
    var pdf : CGPDFDocumentRef! = nil
    var page : CGPDFPageRef! = nil
    var numberPages : Int = 0
    var scaled : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //DataViewController在RootVC是通过storyboard初始化,只执行了awakeFormNib
        page = CGPDFDocumentGetPage(self.pdf, self.numberPages)
        scrollView.setPDFPage(page)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        restoreScale()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //重新计算ScrollView缩放大小
    func restoreScale(){
        let pageRect = CGPDFPageGetBoxRect(self.page,CGPDFBox.MediaBox)
        let yScale = self.view.frame.height / pageRect.height
        let xScale = self.view.frame.width / pageRect.width
        self.scaled = min(yScale,xScale)
        
        scrollView.bounds = self.view.bounds
        scrollView.zoomScale = 1.0
        scrollView.scaled = self.scaled
        scrollView.contentSize = CGSize(width: self.view.frame.width * self.scaled, height: self.view.frame.height * self.scaled)
        scrollView.pdfView.bounds = self.view.bounds
        scrollView.pdfView.scaled = self.scaled
        scrollView.pdfView.layer.setNeedsDisplay()
    }
}

//
//  MainController.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}
class MainController: UIViewController {
    
    var scroll = UIScrollView()
    
    
    let en = UIButton()
    
    var downLoadImageCount:Int = 0
    
    var url:String?
    
    var obj:ImageRep?
    
    var c = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scroll.frame = self.view.frame
        let firstView = UIImageView()
        firstView.contentMode = .scaleAspectFill
        firstView.clipsToBounds = true
        firstView.image = UIImage(named:"startimg_ios")
        firstView.frame = CGRect(x: 0,y: 20,width: self.view.frame.width,height: self.view.frame.height-20)
        self.view.addSubview(firstView)
        var hi:[UIImageView] = []
        var holex:Int = 1
        var jj:CGFloat = 0
        VersionAPIDAO.getVersion({ (obj) in
            DispatchQueue.main.async {
                self.obj = obj;
                if (obj.version != nil){
                    if let ClientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        var ServerVersion = String (obj.version)
                        if (ClientVersion != ServerVersion){
                            let alertView = UIAlertController(title:"提示", message: "请更新版本", preferredStyle: .alert)
                            let action = UIAlertAction(title: "确定", style: .default, handler: { (alert) -> Void in
                                if let checkURL = NSURL(string: "http://www.google.com") {  //路由為下載.ipa的位置
                                    if UIApplication.shared.openURL(checkURL as URL){
                                        
                                    }
                                }
                            })
                            alertView.addAction(action)
                            self.present(alertView, animated: true, completion: nil)
                            return
                        }
                    }
                }
                for num in obj.img
                {
                    //var hh = "view\(holex)"
                    let gg = UIImageView()
                    hi.append(gg)
                    holex += 1
                    
                }
                self.url = obj.result
                if(obj.img != nil){
                    for (j,k) in zip(hi,obj.img)
                    {
                        let tr = k as! String
                        ImageLoader.sharedLoader.imageForUrl(tr, completionHandler:{(image: UIImage?, url: String) in
                            self.downLoadImageCount = self.downLoadImageCount + 1
                            
                            if(image == nil)
                            {
                                j.image = nil
                            }else
                            {
                                j.image = image
                            }
                            
                            if(self.downLoadImageCount == obj.img.count){
                                firstView.isHidden = true
                                self.en.setTitle("进入主页", for: UIControlState())
                                self.en.frame = CGRect(x: self.view.frame.width-150, y: self.view.frame.height-100, width: 150, height: 150)
                                self.en.titleLabel!.font = UIFont(name: "MicrosoftYaHei-Bold",size: 30)
                                self.en.setTitleColor(UIColor(red:252, green:194, blue: 0, alpha: 1.0),for: UIControlState())
                                
                                let vr = UITapGestureRecognizer(target:self, action: #selector(MainController.gotoUrl(_:)))
                                self.en.addGestureRecognizer(vr)
                                
                            }
                        })
                        j.frame = CGRect(x: jj,y: 0,width: self.view.frame.width,height: self.view.frame.height)
                        self.scroll.addSubview(j)
                        jj += self.view.frame.width
                    }
                    self.scroll.contentSize=CGSize(width: self.view.frame.width*CGFloat(obj.img.count),height: self.view.frame.height)
                        let timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: "update", userInfo: nil, repeats: true)
                }
                self.scroll.isPagingEnabled = true
                self.scroll.isScrollEnabled = false
                self.scroll.showsVerticalScrollIndicator = false
                self.scroll.showsHorizontalScrollIndicator = false
                self.scroll.alwaysBounceHorizontal = true
                self.view.addSubview((self.scroll))
                self.view.addSubview(self.en)
            }
        }) { (str) in
            DispatchQueue.main.async {
                let alert : UIAlertView = UIAlertView(title: "提示", message: "连线异常",       delegate: nil, cancelButtonTitle: "确定")
                alert.show()
            }
            
        }
    }
    
    func update()
    {
        let offset = scroll.contentOffset
        
        if(c < obj?.img.count)
        {
            scroll.setContentOffset(CGPoint(x: offset.x + view.frame.width, y: offset.y ), animated: false)
            if(scroll.contentOffset.x >= view.frame.width*CGFloat((obj?.img.count)!))
            {
                scroll.setContentOffset(CGPoint(x: 0, y: offset.y), animated: false)
            }
            c+=1
            
        }
        if(c==obj?.img.count)
        {
            if(!ToolsString.isEmpty(url))
            {
                openLink(url!);
            }
        }
    }

    
    func gotoUrl(_ sender: UITapGestureRecognizer){
        if(!ToolsString.isEmpty(url))
        {
            openLink(url!);
        }
    }
    
    func openLink(_ str:String){
        DispatchQueue.main.async {
            if let checkURL = URL(string: str) {
                if UIApplication.shared.openURL(checkURL) {
                    
                }
            }
        }
    }
    
    
    
}

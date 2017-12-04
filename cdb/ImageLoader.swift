//
//  ImageLoader.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import UIKit
import Foundation


class ImageLoader {
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    init() {
        cache.totalCostLimit = 50 * 1024 * 1024 //100 MB
        cache.countLimit = 15
        cache.name = "com.asus.cache"
        NotificationCenter.default.addObserver(self, selector: #selector(ImageLoader.clearMemoryCache),
                                               name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ImageLoader.clearMemoryCache),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc internal func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    class var sharedLoader : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    func imageForUrl(_ urlString: String, completionHandler:@escaping (_ image: UIImage?, _ url: String) -> ()) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {()in
            let doImageUrl = urlString.replacingOccurrences(of: "\\", with: "/")
            let data: Data? = self.cache.object(forKey: doImageUrl as AnyObject) as? Data
            
            if let goodData = data {
                let image = UIImage(data: goodData)
                DispatchQueue.main.async(execute: {() in
                    completionHandler(image, doImageUrl)
                })
                return
            }
            let str = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            print(str)
            URLSession.shared.dataTask(with: NSURL(string: str)! as URL, completionHandler: { (data, response, error) -> Void in
                
                if (error != nil) {
                    completionHandler(nil, doImageUrl)
                    return
                }
                if let data = data {
                    
                    let image = UIImage(data: data)
                    self.cache.setObject(data as AnyObject, forKey: doImageUrl as AnyObject)
                    DispatchQueue.main.async(execute: {() in
                        completionHandler(image, doImageUrl)
                    })
                    return
                }
                
            }).resume()
        })
        
    }
}

//
//  APIProcess.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import Foundation
class APIProcess:NSObject {
    
    
    
    //統一處理傳送單元
    static func SendAsynchronousRequest(_ apiStr:String!,sendContent:String!, apiSelect:String!, apiRequest:String!,success:@escaping (String,_ response:URLResponse) -> Void, failure:@escaping (String) -> Void){
        var request:NSMutableURLRequest!
        //宣告要post的值
        var httpBodyString:NSString!
        
        request = NSMutableURLRequest(url: URL(string: apiStr + apiSelect)!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.httpShouldHandleCookies = false
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        httpBodyString = NSString(format: "%@", sendContent)
        request.httpBody = httpBodyString.data(using: String.Encoding.utf8.rawValue)
        var session = URLSession.shared
        do {
            var task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                print("Response: \(response)")
                if(error != nil)
                {
                    failure(error.debugDescription)
                    return
                }
                let result = (NSString(data: data!, encoding: String.Encoding.utf8.rawValue))
                if(result != nil){
                    let returnStr =  result! as String
                    success(returnStr,response!)
                }else
                {
                    failure("网路连线异常")
                    return
                }
                
            })
            task.resume()
        }
        catch {
            print("執行NSURLConnection.sendAsynchronousRequest失敗")
            return
        }
    }
    
    
}


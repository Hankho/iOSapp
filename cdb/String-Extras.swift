//
//  String-Extras.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

extension String {
    func positionOf(_ sub:String)->Int {
        var pos = -1
        if let range = self.range(of: sub) {
            if !range.isEmpty {
                pos = self.characters.distance(from: self.startIndex, to: range.lowerBound)
            }
        }
        return pos
    }
    
    func subStringFrom(_ pos:Int)->String {
        var substr = ""
        let start = self.characters.index(self.startIndex, offsetBy: pos)
        let end = self.endIndex
        //		println("String: \(self), start:\(start), end: \(end)")
        let range = start..<end
        substr = self[range]
        //		println("Substring: \(substr)")
        return substr
    }
    
    func subStringTo(_ pos:Int)->String {
        var substr = ""
        let end = self.characters.index(self.startIndex, offsetBy: pos-1)
        let range = self.startIndex...end
        substr = self[range]
        return substr
    }
    
    func urlEncoded()->String {
        let res:NSString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, self as NSString, nil,
                                                                   "!*'();:@&=+$,/?%#[]" as CFString!, CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
        return res as String
    }
    
    func urlDecoded()->String {
        let res:NSString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, self as NSString, "" as CFString!, CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
        return res as String
    }
    
    func range()->Range<String.Index> {
        return (startIndex ..< endIndex)
    }
}


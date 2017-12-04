//
//  DatabaseManagerForURL.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import Foundation
class DatabaseManagerForURL {
    private static var __once: () = {
        instance = SQLiteURL()
    }()
    /** 帳號登入DB執行*/
    fileprivate static var instance:SQLiteURL!
    /** 檢測記憶體是否已有DB初始化過*/
    fileprivate static var token:Int = 0
    
    internal static func getInstance()->SQLiteURL
    {
        _ = DatabaseManagerForURL.__once
        return instance
    }
    
}


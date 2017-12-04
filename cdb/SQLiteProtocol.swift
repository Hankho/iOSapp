//
//  SQLiteProtocol.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import Foundation
protocol SQLiteProtocol {
    /**建立table*/
    func onCreate(_ sQLiteDB:SQLiteDB)
    /**更新table*/
    func onUpgrade(_ sQLiteDB:SQLiteDB,oldVersion:Int,newVersion:Int)
    
}


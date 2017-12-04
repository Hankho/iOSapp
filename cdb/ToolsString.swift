//
//  ToolsString.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//


import Foundation

struct ToolsString {
    
    /**
     檢測字串,是否為空字串,或者nil
     @param str 檢測字串
     */
    static func isEmpty(_ str:String?) -> Bool{
        if(str == nil || "" == str)
        {
            return true;
        }
        return false;
    }
    /**
     轉換字串,若為nil,將會轉換成空字串
     */
    static func transToString(_ int:Int?) ->String
    {
        if(int == nil )
        {
            return "";
        }
        return (int?.description)!;
    }
    
    /**
     轉換字串,若為nil,將會轉換成空字串
     */
    static func transToString(_ str:String?) ->String
    {
        if(str == nil || "" == str)
        {
            return "";
        }
        return str!;
    }
    
}


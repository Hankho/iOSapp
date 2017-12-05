//
//  ImageRep.swift
//  cdb
//
//  Created by Brain Liao on 2017/11/7.
//  Copyright © 2017年 cdb. All rights reserved.
//

import Foundation
import ObjectMapper
class ImageRep:Mappable {
    /**companyCode*/
    var result:String!
    var version:Int!
    var img:[String]!
    init() {}
    
    required init?(map: Map) {
        
    }
    
    // Mappable
    
    func mapping(map: Map) {
        result <- map["result"]
        version <- map["version"]
        img <- map["img"]
    }
    
}


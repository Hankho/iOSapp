//
//  SQLiteDB.swift
//  ManDan
//
//  Created by Brain Liao on 2015/11/28.
//  Copyright © 2015年 com.CHomeStudy. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
    // FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
    // Consider refactoring the code to use the non-optional operators.
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
    fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?):
            return l > r
        default:
            return rhs < lhs
        }
    }
    
#else
    import AppKit
#endif

let SQLITE_DATE = SQLITE_NULL + 1

private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK:- SQLiteDB Class - Does all the work
class SQLiteDB {
    //let DB_NAME = "data.db"
    //let QUEUE_LABEL = "SQLiteDB"
    fileprivate var db:OpaquePointer? = nil
    fileprivate var queue:DispatchQueue
    fileprivate var fmt = DateFormatter()
    fileprivate var GROUP = ""
    
    fileprivate var db_NAME:String!
    
    fileprivate var queue_LABEL:String!
    
    fileprivate var nowVersion:Int!
    
    required init(gid:String,db_NAME:String,queue_LABEL:String,nowVersion:Int) {
        assert(true, "Singleton already initialized!")
        self.db_NAME = db_NAME
        self.queue_LABEL = queue_LABEL
        self.nowVersion = nowVersion
        GROUP = gid
        // Set queue
        queue = DispatchQueue(label: queue_LABEL, attributes: [])
        fmt.timeZone = TimeZone(secondsFromGMT:0)
        // Set up for file operations
        let fm = FileManager.default
        let dbName:String = db_NAME
        var docDir = ""
        // Is this for an app group?
        if GROUP.isEmpty {
            // Get path to DB in Documents directory
            docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        } else {
            // Get path to shared group folder
            if let url = fm.containerURL(forSecurityApplicationGroupIdentifier: GROUP) {
                docDir = url.path
            } else {
                assert(false, "Error getting container URL for group: \(GROUP)")
            }
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(dbName)
        let dbPath: String = fileURL.path
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dbPath) {
            let documentsURL = Bundle.main.resourceURL
            let fromPath = documentsURL!.appendingPathComponent(dbName as String)
            var error : NSError?
            do {
                try fm.createFile(atPath: dbPath, contents: nil, attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            
            if (error != nil) {
                print("Error Occured: " + (error?.localizedDescription)!)
            } else {
                print("Successfully Copy: Your database copy successfully!")
            }
        }
        
        
        
        let fileURL2 = documentsURL.appendingPathComponent(dbName)
        let databasePath = fileURL2.path
        
        if !fm.fileExists(atPath: databasePath) {
            print("Error: " + dbName + " file not found")
        }
        else {
            //            print("Success: " + dbName + " is exists")
        }
        
        //        let path = (docDir as NSString).stringByAppendingPathComponent(dbName)
        //        print("Database path: \(path)")
        // Check if copy of DB is there in Documents directory
        //        if !(fm.fileExistsAtPath(path)) {
        //            // The database does not exist, so copy to Documents directory
        //            do {
        //               // try fm.createFileAtPath(path, contents: nil, attributes: nil)
        //
        //               // try fm.copyItemAtPath(from, toPath:path)
        //            } catch let error as NSError {
        //                print("SQLiteDB - failed to copy writable version of DB!")
        //                print("Error - \(error.localizedDescription)")
        //                return
        //            }
        //        }
        // Open the DB
        let cpath = databasePath.cString(using: String.Encoding.utf8)
        let error = sqlite3_open(cpath!, &db)
        if error != SQLITE_OK {
            // Open failed, close DB and fail
            print("SQLiteDB - failed to open DB!")
            sqlite3_close(db)
        }
        fmt.dateFormat = "YYYY-MM-dd HH:mm:ss"
    }
    
    deinit {
        closeDatabase()
    }
    
    func checkVersion(_ sQLiteProtocol:SQLiteProtocol)
    {
        let versionData = self.query(sql: "select * from Version")
        if versionData.count > 0 {
            let versionRow = versionData[versionData.count - 1]
            let version = versionRow["Version"] as? Int
            if(nowVersion > version)
            {
                sQLiteProtocol.onUpgrade(self, oldVersion: version!, newVersion: nowVersion)
                let updateSQL = "update Version SET Version = '\(nowVersion)'"
                self.execute(sql: updateSQL)
            }
            
        }else{
            self.execute(sql: "create table if not exists Version(Version integer)")
            let createSQL = "insert into Version(version) values('\(nowVersion)')"
            self.execute(sql: createSQL)
            sQLiteProtocol.onCreate(self)
        }
    }
    
    fileprivate func closeDatabase() {
        if db != nil {
            // Get launch count value
            let ud = UserDefaults.standard
            var launchCount = ud.integer(forKey:"LaunchCount")
            launchCount -= 1
            NSLog("SQLiteDB - Launch count \(launchCount)")
            var clean = false
            if launchCount < 0 {
                clean = true
                launchCount = 500
            }
            ud.set(launchCount, forKey:"LaunchCount")
            ud.synchronize()
            // Do we clean DB?
            if !clean {
                sqlite3_close(db)
                return
            }
            // Clean DB
            NSLog("SQLiteDB - Optimize DB")
            let sql = "VACUUM; ANALYZE"
            if CInt(execute(sql:sql)) != SQLITE_OK {
                NSLog("SQLiteDB - Error cleaning DB")
            }
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    // Execute SQL with parameters and return result code
    func execute(sql:String, parameters:[Any]? = nil)->Int {
        assert(db != nil, "Database has not been opened! Use the openDB() method before any DB queries.")
        var result = 0
        queue.sync {
            if let stmt = self.prepare(sql:sql, params:parameters) {
                result = self.execute(stmt:stmt, sql:sql)
            }
        }
        return result
    }
    
    // Run SQL query with parameters
    //    func query(_ sql:String, parameters:[AnyObject]?=nil)->[[String:AnyObject]] {
    //        var rows = [[String:AnyObject]]()
    //        // print("sql: \(sql)")
    //        queue.sync {
    //            let stmt = self.prepare(sql: sql, params:parameters)
    //            if stmt != nil {
    //                rows = self.query(stmt!, parameters:sql)
    //            }
    //        }
    //        return rows
    //    }
    
    func query(sql:String, parameters:[Any]? = nil)->[[String:Any]] {
        assert(db != nil, "Database has not been opened! Use the openDB() method before any DB queries.")
        var rows = [[String:Any]]()
        queue.sync {
            if let stmt = self.prepare(sql:sql, params:parameters) {
                rows = self.query(stmt:stmt, sql:sql)
            }
        }
        return rows
    }
    
    // Show alert with either supplied message or last error
    func alert(_ msg:String) {
        DispatchQueue.main.async {
            #if os(iOS)
                let alert = UIAlertView(title: "SQLiteDB", message:msg, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            #else
                let alert = NSAlert()
                alert.addButtonWithTitle("OK")
                alert.messageText = "SQLiteDB"
                alert.informativeText = msg
                alert.alertStyle = NSAlertStyle.WarningAlertStyle
                alert.runModal()
            #endif
        }
    }
    
    private func prepare(sql:String, params:[Any]?) -> OpaquePointer? {
        var stmt:OpaquePointer? = nil
        let cSql = sql.cString(using: String.Encoding.utf8)
        // Prepare
        let result = sqlite3_prepare_v2(self.db, cSql!, -1, &stmt, nil)
        if result != SQLITE_OK {
            sqlite3_finalize(stmt)
            if let error = String(validatingUTF8:sqlite3_errmsg(self.db)) {
                let msg = "SQLiteDB - failed to prepare SQL: \(sql), Error: \(error)"
                NSLog(msg)
            }
            return nil
        }
        // Bind parameters, if any
        if params != nil {
            // Validate parameters
            let cntParams = sqlite3_bind_parameter_count(stmt)
            let cnt = params!.count
            if cntParams != CInt(cnt) {
                let msg = "SQLiteDB - failed to bind parameters, counts did not match. SQL: \(sql), Parameters: \(params!)"
                NSLog(msg)
                return nil
            }
            var flag:CInt = 0
            // Text & BLOB values passed to a C-API do not work correctly if they are not marked as transient.
            for ndx in 1...cnt {
                //				NSLog("Binding: \(params![ndx-1]) at Index: \(ndx)")
                // Check for data types
                if let txt = params![ndx-1] as? String {
                    flag = sqlite3_bind_text(stmt, CInt(ndx), txt, -1, SQLITE_TRANSIENT)
                } else if let data = params![ndx-1] as? NSData {
                    flag = sqlite3_bind_blob(stmt, CInt(ndx), data.bytes, CInt(data.length), SQLITE_TRANSIENT)
                } else if let date = params![ndx-1] as? Date {
                    let txt = fmt.string(from:date)
                    flag = sqlite3_bind_text(stmt, CInt(ndx), txt, -1, SQLITE_TRANSIENT)
                } else if let val = params![ndx-1] as? Bool {
                    let num = val ? 1 : 0
                    flag = sqlite3_bind_int(stmt, CInt(ndx), CInt(num))
                } else if let val = params![ndx-1] as? Double {
                    flag = sqlite3_bind_double(stmt, CInt(ndx), CDouble(val))
                } else if let val = params![ndx-1] as? Int {
                    flag = sqlite3_bind_int(stmt, CInt(ndx), CInt(val))
                } else {
                    flag = sqlite3_bind_null(stmt, CInt(ndx))
                }
                // Check for errors
                if flag != SQLITE_OK {
                    sqlite3_finalize(stmt)
                    if let error = String(validatingUTF8:sqlite3_errmsg(self.db)) {
                        let msg = "SQLiteDB - failed to bind for SQL: \(sql), Parameters: \(params!), Index: \(ndx) Error: \(error)"
                        NSLog(msg)
                    }
                    return nil
                }
            }
        }
        return stmt
    }
    // Private method which handles the actual execution of an SQL statement
    private func execute(stmt:OpaquePointer, sql:String)->Int {
        // Step
        let res = sqlite3_step(stmt)
        if res != SQLITE_OK && res != SQLITE_DONE {
            sqlite3_finalize(stmt)
            if let error = String(validatingUTF8:sqlite3_errmsg(self.db)) {
                let msg = "SQLiteDB - failed to execute SQL: \(sql), Error: \(error)"
                NSLog(msg)
            }
            return 0
        }
        // Is this an insert
        let upp = sql.uppercased()
        var result = 0
        if upp.hasPrefix("INSERT ") {
            // Known limitations: http://www.sqlite.org/c3ref/last_insert_rowid.html
            let rid = sqlite3_last_insert_rowid(self.db)
            result = Int(rid)
        } else if upp.hasPrefix("DELETE") || upp.hasPrefix("UPDATE") {
            var cnt = sqlite3_changes(self.db)
            if cnt == 0 {
                cnt += 1
            }
            result = Int(cnt)
        } else {
            result = 1
        }
        // Finalize
        sqlite3_finalize(stmt)
        return result
    }
    // Private method which handles the actual execution of an SQL query
    private func query(stmt:OpaquePointer, sql:String)->[[String:Any]] {
        var rows = [[String:Any]]()
        var fetchColumnInfo = true
        var columnCount:CInt = 0
        var columnNames = [String]()
        var columnTypes = [CInt]()
        var result = sqlite3_step(stmt)
        while result == SQLITE_ROW {
            // Should we get column info?
            if fetchColumnInfo {
                columnCount = sqlite3_column_count(stmt)
                for index in 0..<columnCount {
                    // Get column name
                    let name = sqlite3_column_name(stmt, index)
                    columnNames.append(String(validatingUTF8:name!)!)
                    // Get column type
                    columnTypes.append(self.getColumnType(index:index, stmt:stmt))
                }
                fetchColumnInfo = false
            }
            // Get row data for each column
            var row = [String:Any]()
            for index in 0..<columnCount {
                let key = columnNames[Int(index)]
                let type = columnTypes[Int(index)]
                if let val = getColumnValue(index:index, type:type, stmt:stmt) {
                    //						NSLog("Column type:\(type) with value:\(val)")
                    row[key] = val
                }
            }
            rows.append(row)
            // Next row
            result = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        return rows
    }
    // Get column type
    private func getColumnType(index:CInt, stmt:OpaquePointer)->CInt {
        var type:CInt = 0
        // Column types - http://www.sqlite.org/datatype3.html (section 2.2 table column 1)
        let blobTypes = ["BINARY", "BLOB", "VARBINARY"]
        let charTypes = ["CHAR", "CHARACTER", "CLOB", "NATIONAL VARYING CHARACTER", "NATIVE CHARACTER", "NCHAR", "NVARCHAR", "TEXT", "VARCHAR", "VARIANT", "VARYING CHARACTER"]
        let dateTypes = ["DATE", "DATETIME", "TIME", "TIMESTAMP"]
        let intTypes  = ["BIGINT", "BIT", "BOOL", "BOOLEAN", "INT", "INT2", "INT8", "INTEGER", "MEDIUMINT", "SMALLINT", "TINYINT"]
        let nullTypes = ["NULL"]
        let realTypes = ["DECIMAL", "DOUBLE", "DOUBLE PRECISION", "FLOAT", "NUMERIC", "REAL"]
        // Determine type of column - http://www.sqlite.org/c3ref/c_blob.html
        let buf = sqlite3_column_decltype(stmt, index)
        //		NSLog("SQLiteDB - Got column type: \(buf)")
        if buf != nil {
            var tmp = String(validatingUTF8:buf!)!.uppercased()
            // Remove bracketed section
            if let pos = tmp.range(of:"(") {
                tmp = tmp.substring(to:pos.lowerBound)
            }
            // Remove unsigned?
            // Remove spaces
            // Is the data type in any of the pre-set values?
            //			NSLog("SQLiteDB - Cleaned up column type: \(tmp)")
            if intTypes.contains(tmp) {
                return SQLITE_INTEGER
            }
            if realTypes.contains(tmp) {
                return SQLITE_FLOAT
            }
            if charTypes.contains(tmp) {
                return SQLITE_TEXT
            }
            if blobTypes.contains(tmp) {
                return SQLITE_BLOB
            }
            if nullTypes.contains(tmp) {
                return SQLITE_NULL
            }
            if dateTypes.contains(tmp) {
                return SQLITE_DATE
            }
            return SQLITE_TEXT
        } else {
            // For expressions and sub-queries
            type = sqlite3_column_type(stmt, index)
        }
        return type
    }
    // Get column value
    private func getColumnValue(index:CInt, type:CInt, stmt:OpaquePointer)->Any? {
        // Integer
        if type == SQLITE_INTEGER {
            let val = sqlite3_column_int(stmt, index)
            return Int(val)
        }
        // Float
        if type == SQLITE_FLOAT {
            let val = sqlite3_column_double(stmt, index)
            return Double(val)
        }
        // Text - handled by default handler at end
        // Blob
        if type == SQLITE_BLOB {
            let data = sqlite3_column_blob(stmt, index)
            let size = sqlite3_column_bytes(stmt, index)
            let val = NSData(bytes:data, length:Int(size))
            return val
        }
        // Null
        if type == SQLITE_NULL {
            return nil
        }
        // Date
        if type == SQLITE_DATE {
            // Is this a text date
            if let ptr = UnsafeRawPointer.init(sqlite3_column_text(stmt, index)) {
                let uptr = ptr.bindMemory(to:CChar.self, capacity:0)
                let txt = String(validatingUTF8:uptr)!
                let set = CharacterSet(charactersIn:"-:")
                if txt.rangeOfCharacter(from:set) != nil {
                    // Convert to time
                    var time:tm = tm(tm_sec: 0, tm_min: 0, tm_hour: 0, tm_mday: 0, tm_mon: 0, tm_year: 0, tm_wday: 0, tm_yday: 0, tm_isdst: 0, tm_gmtoff: 0, tm_zone:nil)
                    strptime(txt, "%Y-%m-%d %H:%M:%S", &time)
                    time.tm_isdst = -1
                    let diff = TimeZone.current.secondsFromGMT()
                    let t = mktime(&time) + diff
                    let ti = TimeInterval(t)
                    let val = Date(timeIntervalSince1970:ti)
                    return val
                }
            }
            // If not a text date, then it's a time interval
            let val = sqlite3_column_double(stmt, index)
            let dt = Date(timeIntervalSince1970: val)
            return dt
        }
        // If nothing works, return a string representation
        if let ptr = UnsafeRawPointer.init(sqlite3_column_text(stmt, index)) {
            let uptr = ptr.bindMemory(to:CChar.self, capacity:0)
            let txt = String(validatingUTF8:uptr)
            return txt
        }
        return nil
    }
}

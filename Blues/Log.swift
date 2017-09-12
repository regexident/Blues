//
//  Log.swift
//  Blues
//
//  Created by Michał Kałużny on 11/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

class Log {
    enum Level: String, CustomStringConvertible {
        case debug
        case warning
        case error
        
        var description: String {
            return self.rawValue.uppercased()
        }
    }
    
    static let shared = Log()
    
    private init() {}
    
    var enabledLevels: [Level] = [.debug, .warning, .error]
    
    internal func log(level: Level, message:  @autoclosure () -> String) {
        guard enabledLevels.contains(level) else {
            return
        }
        
        print("[\(level)] \(message())")
    }
    
    func debug(_ message:  @autoclosure () -> String) {
        log(level: .debug, message: message)
    }
    
    func warning(_ message:  @autoclosure () -> String) {
        log(level: .warning, message: message)
    }
    
    func error(_ message:  @autoclosure () -> String) {
        log(level: .error, message: message)
    }
}

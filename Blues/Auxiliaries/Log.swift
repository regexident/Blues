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
        
        var icon: Character {
            switch self {
            case .debug: return "🛠"
            case .warning: return "⚠️"
            case .error: return "⛔️"
            }
        }
    }
    
    static let shared = Log()
    static let capture: () -> String = {
        return #file
    }
    
    private init() {}
    
    var enabledLevels: [Level] = [.debug, .warning, .error]
    var shouldFailOnError: Bool = true
    
    internal func log(level: Level, message:  @autoclosure () -> String, file: String, line: Int) {
        guard enabledLevels.contains(level) else {
            return
        }
        
        print("\(file) Line: \(line)")
        print("\(level.icon) \(message())")
    }
    
    func debug(_ message:  @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    func warning(_ message:  @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }
    
    func error(_ message:  @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
        if shouldFailOnError {
            fatalError()
        }
    }
}

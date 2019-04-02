// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
        log(level: .debug, message: message(), file: file, line: line)
    }
    
    func warning(_ message:  @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message(), file: file, line: line)
    }
    
    func error(_ message:  @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message(), file: file, line: line)
        if shouldFailOnError {
            fatalError()
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerOptionsTests: XCTestCase {
    private enum Key {
        static let restoreIdentifierKey: String = CBCentralManagerOptionRestoreIdentifierKey
        static let showPowerAlertKey: String = CBCentralManagerOptionShowPowerAlertKey
    }
    
    private enum Stub {
        static let restoreIdentifier = "RestoreIdentifier"
        static let shouldShowPowerAlert = true
        
        static let dictionary: [String: Any] = [
            Key.restoreIdentifierKey: Stub.restoreIdentifier,
            Key.showPowerAlertKey: Stub.shouldShowPowerAlert
        ]
    }

    func test_shouldShowPowerAlert() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = true

        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, true)
    }
    
    func test_shouldntShowPowerAlert() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = false
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, false)
    }
    
    func test_showPowerAlertWithNoKey() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, nil)
    }
    
    func test_properIdentifier() {
        let identifier = UUID().uuidString
        var dictionary = Stub.dictionary
        
        dictionary[Key.restoreIdentifierKey] = identifier
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        guard let optionsIdentifier = options.restoreIdentifier else {
            return XCTFail()
        }
        
        guard case .custom(let value) = optionsIdentifier else {
            return XCTFail()
        }
        
        XCTAssertEqual(value, identifier)
    }
    
    func test_noRestoreIdentifier() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.restoreIdentifierKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.restoreIdentifier)
    }
    
    func test_dictionaryMarshalling() {
        let dictionary = Stub.dictionary
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        let parsed = options.dictionary
        
        let restoreIdentifier = parsed[Key.restoreIdentifierKey]
        let shoudShowPowerAlert = parsed[Key.showPowerAlertKey]
        
        XCTAssertEqual(restoreIdentifier as? String, Stub.restoreIdentifier)
        XCTAssertEqual(shoudShowPowerAlert as? Bool, Stub.shouldShowPowerAlert)
    }
    
    func test_invalidDictionaryMarshalling() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.restoreIdentifierKey] = 123
        dictionary[Key.showPowerAlertKey] = "Test"

        
        let options = CentralManagerOptions(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}

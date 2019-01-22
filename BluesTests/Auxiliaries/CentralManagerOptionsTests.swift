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

    func testShouldShowPowerAlert() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = true

        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, true)
    }
    
    func testShouldntShowPowerAlert() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = false
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, false)
    }
    
    func testShowPowerAlertWithNoKey() {
        var dictionary = Stub.dictionary
        dictionary[Key.showPowerAlertKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, nil)
    }
    
    func testProperIdentifier() {
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
    
    func testNoRestoreIdentifier() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.restoreIdentifierKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.restoreIdentifier)
    }
    
    func testDictionaryMarshalling() {
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
    
    func testInvalidDictionaryMarshalling() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.restoreIdentifierKey] = 123
        dictionary[Key.showPowerAlertKey] = "Test"

        
        let options = CentralManagerOptions(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}

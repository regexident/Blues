// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerScanningOptionsTests: XCTestCase {
    typealias Options = CentralManagerScanningOptions
    
    private enum Key {
        static let allowDuplicatesKey: String = CBCentralManagerScanOptionAllowDuplicatesKey
        static let solicitedServiceUUIDsKey: String = CBCentralManagerScanOptionSolicitedServiceUUIDsKey
    }
    
    private enum Stub {
        static let solicitedServiceIdentifiers = [CBUUID(), CBUUID()]
        static let allowDuplicates = true
    }
    
    static let dictionary: [String: Any] = [
        Key.allowDuplicatesKey: Stub.allowDuplicates,
        Key.solicitedServiceUUIDsKey: Stub.solicitedServiceIdentifiers
    ]
    
    func test_allowDuplicatesTrue() {
        var dictionary = type(of: self).dictionary
        dictionary[Key.allowDuplicatesKey] = true
        
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, true)
    }
    
    func test_allowDuplicatesFalse() {
        var dictionary = type(of: self).dictionary
        dictionary[Key.allowDuplicatesKey] = false
        
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func test_allowDuplicatesWithNoKey() {
        var dictionary = type(of: self).dictionary
        dictionary[Key.allowDuplicatesKey] = nil
        
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        // There's a default value of false.
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func test_validServiceIdentifier() {
        var dictionary = type(of: self).dictionary
        let stub = Stub.solicitedServiceIdentifiers
        dictionary[Key.solicitedServiceUUIDsKey] = stub
        
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        guard let optionsIdentifiers = options.solicitedServiceIdentifiers else {
            return XCTFail()
        }
        
        XCTAssertEqual(optionsIdentifiers.count, stub.count)
        
        for (expected, parsed) in zip(stub, optionsIdentifiers) {
            XCTAssertEqual(expected, parsed.uuid)
        }
    }
    
    func test_noServiceIdentifiers() {
        var dictionary = type(of: self).dictionary
        
        dictionary[Key.solicitedServiceUUIDsKey] = nil
        
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.solicitedServiceIdentifiers)
    }
    
    func test_dictionaryMarshalling() {
        let dictionary = type(of: self).dictionary
        guard let options = Options(dictionary: dictionary) else {
            return XCTFail()
        }
        
        let parsed = options.dictionary
        
        let allowDuplicates = parsed[Key.allowDuplicatesKey]
        let solicitedServicesIdentifiers = parsed[Key.solicitedServiceUUIDsKey]
        
        XCTAssertEqual(allowDuplicates as? Bool, Stub.allowDuplicates)
        XCTAssertEqual(solicitedServicesIdentifiers as? [CBUUID], Stub.solicitedServiceIdentifiers)
    }
    
    func test_invalidDictionaryMarshalling() {
        var dictionary = type(of: self).dictionary
        
        dictionary[Key.solicitedServiceUUIDsKey] = 123
        dictionary[Key.allowDuplicatesKey] = "Test"
        
        
        let options = Options(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}

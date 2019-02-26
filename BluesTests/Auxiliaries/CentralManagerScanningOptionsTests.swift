// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerScanningOptionsTests: XCTestCase {
    static private let SolicitedServiceIdentifiersStub = [CBUUID(), CBUUID()]
    static private let AllowDuplicatesStub = true
    
    static let dictionary: [String: Any] = [
        CBCentralManagerScanOptionAllowDuplicatesKey: AllowDuplicatesStub,
        CBCentralManagerScanOptionSolicitedServiceUUIDsKey: SolicitedServiceIdentifiersStub
    ]
    
    func testAllowDuplicatesTrue() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = true
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, true)
    }
    
    func testAllowDuplicatesFalse() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = false
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func testAllowDuplicatesWithNoKey() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = nil
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        // There's a default value of false.
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func testValidServiceIdentifier() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        let stub = CentralManagerScanningOptionsTests.SolicitedServiceIdentifiersStub
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = stub
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
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
    
    func testNoServiceIdentifiers() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = nil
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.solicitedServiceIdentifiers)
    }
    
    func testDictionaryMarshalling() {
        guard let options = CentralManagerScanningOptions(dictionary: CentralManagerScanningOptionsTests.dictionary) else {
            return XCTFail()
        }
        
        let parsed = options.dictionary
        
        guard
            let solicitedServicesIdentifiers = parsed[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID],
            let allowDuplicates = parsed[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool
            else {
                return XCTFail()
        }
        
        XCTAssertEqual(allowDuplicates, CentralManagerScanningOptionsTests.AllowDuplicatesStub)
        XCTAssertEqual(solicitedServicesIdentifiers, CentralManagerScanningOptionsTests.SolicitedServiceIdentifiersStub)
    }
    
    func testInvalidDictionaryMarshalling() {
        var dictionary = CentralManagerScanningOptionsTests.dictionary
        
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = 123
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = "Test"
        
        
        let options = CentralManagerScanningOptions(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}

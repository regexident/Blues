//
//  CentralManagerScanningOptionsTestCase.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerScanningOptionsTestCase: XCTestCase {
    static private let SolicitedServiceIdentifiersStub = [CBUUID(), CBUUID()]
    static private let AllowDuplicatesStub = true
    
    let dictionary: [String: Any] = [
        CBCentralManagerScanOptionAllowDuplicatesKey: AllowDuplicatesStub,
        CBCentralManagerScanOptionSolicitedServiceUUIDsKey: SolicitedServiceIdentifiersStub
    ]
    
    func testAllowDuplicatesTrue() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = true
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, true)
    }
    
    func testAllowDuplicatesFalse() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = false
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func testAllowDuplicatesWithNoKey() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = nil
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        // There's a default value of false.
        XCTAssertEqual(options.allowDuplicates, false)
    }
    
    func testValidServiceIdentifier() {
        var dictionary = self.dictionary
        let stub = CentralManagerScanningOptionsTestCase.SolicitedServiceIdentifiersStub
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
        var dictionary = self.dictionary
        
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = nil
        
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.solicitedServiceIdentifiers)
    }
    
    func testDictionaryMarshalling() {
        guard let options = CentralManagerScanningOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        let parsed = options.dictionary
        
        guard
            let solicitedServicesIdentifiers = parsed[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID],
            let allowDuplicates = parsed[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool
            else {
                return XCTFail()
        }
        
        XCTAssertEqual(allowDuplicates, CentralManagerScanningOptionsTestCase.AllowDuplicatesStub)
        XCTAssertEqual(solicitedServicesIdentifiers, CentralManagerScanningOptionsTestCase.SolicitedServiceIdentifiersStub)
    }
    
    func testInvalidDictionaryMarshalling() {
        var dictionary = self.dictionary
        
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = 123
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = "Test"
        
        
        let options = CentralManagerScanningOptions(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}

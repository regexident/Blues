// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

@testable import Blues

class CentralManagerConnectionDelegateCatcher: CentralManagerConnectionDelegate {
    typealias NonFailableCallback = (Peripheral, CentralManager) -> Void
    typealias FailableCallback = (Peripheral, Swift.Error?, CentralManager) -> Void

    var willConnectClosure: NonFailableCallback? = nil
    var didConnectClosure: NonFailableCallback? = nil
    var willDisconnectClosure: NonFailableCallback? = nil
    var didDisconnectClosure: FailableCallback? = nil
    var didFailToConnectClosure: FailableCallback? = nil

    func willConnect(to peripheral: Peripheral, on manager: CentralManager) {
        willConnectClosure?(peripheral, manager)
    }
    
    func didConnect(to peripheral: Peripheral, on manager: CentralManager) {
        didConnectClosure?(peripheral, manager)
    }
    
    func willDisconnect(from peripheral: Peripheral, on manager: CentralManager) {
        willDisconnectClosure?(peripheral, manager)
    }
    
    func didDisconnect(from peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        didDisconnectClosure?(peripheral, error, manager)
    }
    
    func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?, on manager: CentralManager) {
        didFailToConnectClosure?(peripheral, error, manager)
    }
}

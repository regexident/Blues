//
//  DefaultService.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Service` protocol.
open class DefaultService:
    Service, DelegatedServiceProtocol, DataSourcedServiceProtocol {
    public weak var delegate: ServiceDelegate?
    public weak var dataSource: ServiceDataSource?
}

// MARK: - ServiceDataSource
extension DefaultService: ServiceDataSource {
    public func characteristic(
        with identifier: Identifier,
        for service: Service
    ) -> Characteristic {
        if let dataSource = self.dataSource {
            return dataSource.characteristic(with: identifier, for: service)
        } else {
            return DefaultCharacteristic(identifier: identifier, service: service)
        }
    }
}

// MARK: - ServiceDelegate
extension DefaultService: ServiceDiscoveryDelegate {
    public func didDiscover(
        includedServices: Result<[Service], Error>,
        for service: Service
    ) {
        if let delegate = self.delegate as? ServiceDiscoveryDelegate {
            delegate.didDiscover(includedServices: includedServices, for: service)
        }
    }

    public func didDiscover(
        characteristics: Result<[Characteristic], Error>,
        for service: Service
    ) {
        if let delegate = self.delegate as? ServiceDiscoveryDelegate {
            delegate.didDiscover(characteristics: characteristics, for: service)
        }
    }
}

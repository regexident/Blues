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

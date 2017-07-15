//
//  DefaultDescriptor.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Descriptor` protocol.
open class DefaultDescriptor: Descriptor, DelegatedDescriptorProtocol {
    public weak var delegate: DescriptorDelegate?
}

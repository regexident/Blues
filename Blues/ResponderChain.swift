//
//  ResponderChain.swift
//  Blues
//
//  Created by Vincent Esche on 29/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

// Created by Matthew Johnson on 5/28/16.
// Copyright © 2016 Anandabits LLC. All rights reserved.

public protocol Message {
    associatedtype Handler
    associatedtype Output
    func sendToHandler(_ handler: Handler) -> Output
}

private extension Message {

    func tryToSendTo(_ firstResponder: Responder) -> Output? {
        guard let handler: Handler = findHandlerInChainStartingWith(firstResponder)
        else { return nil }
        return sendToHandler(handler)
    }

    func canSendTo(_ firstResponder: Responder) -> Bool {
        let handler = findHandlerInChainStartingWith(firstResponder) as Handler?
        return handler != nil
    }
}

public protocol Responder {
    var nextResponder: Responder? { get }
}

public extension Responder {

    func tryToHandle<MessageType: Message>(_ message: MessageType) -> MessageType.Output? {
        return message.tryToSendTo(self)
    }

    func canHandle<MessageType: Message>(_ message: MessageType) -> Bool {
        return message.canSendTo(self)
    }
}

private func findHandlerInChainStartingWith<Handler>(_ firstResponder: Responder) -> Handler? {
    var nextResponder: Responder? = firstResponder
    while let responder = nextResponder {
        if let handler = responder as? Handler {
            return handler
        }
        nextResponder = responder.nextResponder
    }
    return nil
}

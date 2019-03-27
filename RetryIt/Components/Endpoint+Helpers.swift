//
//  Endpoint+Helpers.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/28/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift
import Result

extension SignalProducer {

    static func request(value: Value) -> SignalProducer<Value, Error> {
        return SignalProducer(value: value)
            .delay(3, on: QueueScheduler(qos: .background))
    }

    static func request(error: Error) -> SignalProducer<Value, Error> {
        return SignalProducer<Void, NoError>(value: Void())
            .delay(3, on: QueueScheduler(qos: .background))
            .flatMap(.latest) { SignalProducer(error: error) }
    }
}

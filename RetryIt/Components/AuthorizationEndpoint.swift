//
//  AuthorizationEndpoint.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift

typealias Token = String

final class AuthorizationEndpoint {

    let apply: (() -> SignalProducer<Token, APIError>)

    init() {
        var runCount = 0
        self.apply = {
            print("Authorization request fired \(runCount).")
            runCount += 1

            if runCount > 3 {
                return SignalProducer.request(value: "Some Token")
            } else if runCount % 2 == 0 {
                return SignalProducer.request(error: APIError.noInternet)
            } else {
                return SignalProducer.request(error: APIError.service)
            }
        }
    }
}

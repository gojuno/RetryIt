//
//  BiographyEndpoint.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift

typealias Biography = String

final class BiographyEndpoint {

    let apply: ((Token) -> SignalProducer<Biography, APIError>)

    init() {
        var runCount = 0
        self.apply = { token in
            print("Biography request fired \(runCount) with token \(token)")
            runCount += 1

            if runCount > 3 {
                return SignalProducer.request(value: "Some Biography")
            } else if runCount % 2 == 0 {
                return SignalProducer.request(error: APIError.service)
            } else {
                return SignalProducer.request(error: APIError.notAllowed)
            }
        }
    }
}

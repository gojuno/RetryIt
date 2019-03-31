//
//  BiographyEndpoint.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift

typealias SuperSecuredData = String

final class SuperSecuredEndpoint {

    let apply: ((Token) -> SignalProducer<SuperSecuredData, APIError>)

    init() {
        var runCount = 0
        self.apply = { token in
            print("Super secured request fired \(runCount) with token \(token)")
            runCount += 1

            if runCount > 1 {
                return SignalProducer.request(value: "Attention, super secured data, mum's the word!!!")
            } else if runCount % 2 == 0 {
                return SignalProducer.request(error: APIError.notAllowed)
            } else {
                return SignalProducer.request(error: APIError.service)
            }
        }
    }
}

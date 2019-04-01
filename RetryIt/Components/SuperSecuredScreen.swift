//
//  LoginScreen.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import Foundation
import FraktalSimplified
import ReactiveSwift
import Result

// sourcery: presentableV2
final class SuperSecuredScreen {

    init() {
        let authorizationEndpoint = AuthorizationEndpoint()
        let biographyEndpoint = SuperSecuredEndpoint()

        let authorizationAction = Action<Void, Token, APIError> { _ in
            return authorizationEndpoint.apply()
        }

        let biographyAction = Action<Token, SuperSecuredData, APIError> {
            return biographyEndpoint.apply($0)
        }

        let action = Action<Void, SuperSecuredData, APIError>(
            enabledIf: authorizationAction.isEnabled && biographyAction.isEnabled
        ) { _ -> SignalProducer<SuperSecuredData, APIError> in
            authorizationAction.apply(()).expectedToBeEnabled()
                .flatMap(.latest) { token -> SignalProducer<SuperSecuredData, APIError> in
                    biographyAction.apply(token).expectedToBeEnabled()
                }
        }

        let retryableAction = RetryableAction(original: action)

        self.state = retryableAction.makeOneShotStateProperty(input: ())
        self.alert = self.state.producer
            .map { $0.alert }
            .ignoreNil()
        self.child = self.state.producer
            .map(SuperSecuredScreenChild.init)
            .ignoreNil()
    }

    private let state: Property<LoadingState<SuperSecuredData, APIError>>
    // sourcery: presentable, type = * $SuperSecuredScreenChild
    private let child: SignalProducer<SuperSecuredScreenChild, NoError>
    // sourcery: presentable, type = * Alert
    private let alert: SignalProducer<Alert, NoError>
}

// sourcery: presentableV2
enum SuperSecuredScreenChild {
    case content(SuperSecuredData)
    case error(String)
    case loading
}

// sourcery:inline:SuperSecuredScreen.Presentable
// swiftlint:disable line_length
extension SuperSecuredScreen: Presentable {

    internal var present: (SuperSecuredScreenPresenters) -> Disposable? {
        return { [weak self] presenters in
            guard let sself = self else { return nil }
            let disposable = CompositeDisposable()
            disposable += presenters.child.present(sself.child.producer.map { SuperSecuredScreenChildAnyPresentable($0) })
            disposable += presenters.alert.present(sself.alert)
            return disposable
        }
    }
}
// swiftlint:enable line_length
// sourcery:end

// sourcery:inline:SuperSecuredScreenChild.AnyPresentable
// swiftlint:disable line_length
internal extension SuperSecuredScreenChildAnyPresentable {

    init(_ value: SuperSecuredScreenChild) {
        switch value {
        case .content(let item):
            self = .content(item)
        case .error(let item):
            self = .error(item)
        case .loading:
            self = .loading
        }
    }
}
// swiftlint:enable line_length
// sourcery:end

private extension SuperSecuredScreenChild {

    init?(_ state: LoadingState<SuperSecuredData, APIError>) {
        switch state {
        case .error:
            return nil
        case let .ignored(error):
            self = .error(error.reason)
        case let .loaded(value):
            self = .content(value)
        case .loading:
            self = .loading
        }
    }
}

private extension LoadingState where Error == APIError {

    var alert: Alert? {
        switch self {
        case let .error(retryable):
            let error = retryable.error
            return makeAlert(
                error: error,
                retry: error.isRetryable ? retryable.retry : nil,
                ignore: retryable.ignore
            )
        case .ignored, .loading, .loaded:
            return nil
        }
    }
}

private func makeAlert(
    error: APIError,
    retry: (() -> Void)? = nil,
    ignore: (() -> Void)? = nil
) -> Alert {
    return Alert(
        title: "Error",
        message: error.reason,
        primary: retry.map {
            AlertAction(title: "Retry", style: .highlighted, action: $0)
        },
        cancel: ignore.map {
            AlertAction(title: "Ignore", style: .destructive, action: $0)
        }
    )
}

private extension APIError {

    var isRetryable: Bool {
        switch self {
        case .noInternet, .service: return true
        case .notAllowed: return false
        }
    }

    var reason: String {
        switch self {
        case .noInternet: return "Connectivity issue, please check your internet connection."
        case .service: return "Service error, sometimes even the best let us down."
        case .notAllowed: return "Request is not allowed, are you a cool-hacker?"
        }
    }
}

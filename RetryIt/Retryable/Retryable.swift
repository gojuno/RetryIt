//
//  Retryable.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift
import Result

struct Retryable<E: Error> : Error {
    public let error: E
    public let retry: () -> Void
    public let ignore: () -> Void
}

struct RetryableAction<Input, Output, Error: Swift.Error> {

    let action: Action<Input, Output, Error>
    let error: Property<Retryable<Error>?>

    init(original: Action<Input, Output, Error>) {

        let retryable = original.retryable()

        self.action = retryable.action
        self.error = Property(
            initial: nil,
            then: retryable.retryable
            ).skipNilRepeats()
    }
}

extension Action {

    func retryable() -> (action: Action<Input, Output, Error>, retryable: Signal<Retryable<Error>?, NoError>) {

        let inner = Action<Input, RetryableNext<Output, Error>, Error>(enabledIf: self.isEnabled) {
            return self.apply($0)
                .expectedToBeEnabled()
                .retryable()
        }

        let action = Action<Input, Output, Error>(enabledIf: inner.isEnabled) {
            inner.apply($0)
                .expectedToBeEnabled()
                .materialize()
                .promoteError(Error.self)
                .flatMap(.concat) { (event) -> SignalProducer<Output, Error> in
                    switch event {
                    case let .value(.some(output)):
                        return SignalProducer(value: output)
                    case let .failed(error):
                        return SignalProducer(error: error)
                    case .value(.retrying), .value(.error), .interrupted, .completed:
                        return .empty
                    }
            }
        }

        let retryable = inner.events
            .map { $0.value?.error }
            .skipNilRepeats()

        return (action, retryable)
    }
}

private enum RetryableNext<T, E: Error> {

    case some(T)
    case error(Retryable<E>)
    case retrying

    var value: T? {
        if case let .some(value) = self {
            return value
        } else {
            return nil
        }
    }

    var error: Retryable<E>? {
        if case let .error(retryable) = self {
            return retryable
        } else {
            return nil
        }
    }

    var retrying: Bool {
        if case .retrying = self {
            return true
        } else {
            return false
        }
    }
}

private extension SignalProducer {

    func retryable() -> SignalProducer<RetryableNext<Value, Error>, Error> {

        return SignalProducer<RetryableNext<Value, Error>, Error> { observer, lifetime in

            let retryPipe = Signal<Void, NoError>.pipe()
            let valuesPipe = Signal<Value, NoError>.pipe()

            typealias RetryableProducer = SignalProducer<RetryableNext<Value, Error>, Error>
            let processedErrorsPipe = Signal<RetryableProducer, Error>.pipe()

            let queuePipe = Signal<RetryableNext<Value, Error>, Error>.pipe()

            let selfWithSideEffects = self
                .on(value: valuesPipe.input.send)
                .on(completed: observer.sendCompleted)
                .on(interrupted: observer.sendInterrupted)
                .on(failed: { innerError in
                    let retryableError = RetryableNext<Value, Error>.error(
                        Retryable(
                            error: innerError,
                            retry: {
                                processedErrorsPipe.input.send(value: RetryableProducer(value: .retrying))
                                retryPipe.input.send(value: ())
                            },
                            ignore: {
                                queuePipe.input.send(error: innerError)
                            }
                        )
                    )
                    processedErrorsPipe.input.send(value: RetryableProducer(value: retryableError).concat(queuePipe.output.producer.take(first: 1)))
                })
                .completeOnError()
            SignalProducer<RetryableNext<Value, Error>, Error>.merge([
                processedErrorsPipe.output.flatten(.latest).producer,
                valuesPipe.output.producer.map(RetryableNext<Value, Error>.some).promoteError(Error.self)
            ]).take(during: lifetime).start(observer)

            retryPipe.output.producer.flatMap(.latest) {
                selfWithSideEffects
            }.take(during: lifetime).start()

            retryPipe.input.send(value: ())
        }
    }
}

extension Retryable {
    func map<T>(_ transform: (E) -> T) -> Retryable<T> {
        return Retryable<T>(
            error: transform(self.error),
            retry: self.retry,
            ignore: self.ignore
        )
    }
}

enum LoadingState<Value, Error> where Error: Swift.Error {
    case loading
    case loaded(Value)
    case error(Retryable<Error>)
    case ignored(Error)
}

extension RetryableAction {

    func makeOneShotStateProperty(input: Input) -> Property<LoadingState<Output, Error>> {
        let error: Property<LoadingState<Output, Error>?> = self.error.map { $0.map(LoadingState.error) }
        let loading: Property<LoadingState<Output, Error>?> = self.action.isExecuting.map { $0 ? .loading : nil }
        let content = Property<LoadingState<Output, Error>?>(
            initial: nil,
            then: self.action
                .apply(input)
                .expectedToBeEnabled()
                .map(LoadingState.loaded)
                .flatMapError { SignalProducer(value: .ignored($0)) }
        )
        return nilCoalescingFlatMap(
            error,
            loading,
            content
        ).map { $0 ?? .loading }
    }
}

//
//  Retryable.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift
import Result

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

public struct Retryable<E: Error> : Error {
    public let error: E
    public let retry: () -> Void
    public let ignore: () -> Void
}

private extension SignalProducer {

    func retryable() -> SignalProducer<RetryableNext<Value, Error>, Error> {

        return SignalProducer<RetryableNext<Value, Error>, Error> { observer, lifetime in

            let retryPipe = Signal<Void, NoError>.pipe()
            let valuesPipe = Signal<Value, NoError>.pipe()

            typealias RetryableProducer = SignalProducer<RetryableNext<Value, Error>, Error>
            let processedErrorsPipe = Signal<RetryableProducer, Error>.pipe()

            let queuePipe = Signal<RetryableNext<Value, Error>, Error>.pipe()
            let queue = queuePipe.output.producer

            let selfWithSideEffects = self
                .on(value: valuesPipe.1.send)
                .on(completed: observer.sendCompleted)
                .on(interrupted: observer.sendInterrupted)
                .on(failed: { innerError in
                    let retryableError = RetryableNext<Value, Error>.error(
                        Retryable(
                            error: innerError,
                            retry: {
                                processedErrorsPipe.1.send(value: RetryableProducer(value: .retrying))
                                retryPipe.1.send(value: ())
                            },
                            ignore: {
                                queuePipe.1.send(error: innerError)
                            }
                        )
                    )
                    processedErrorsPipe.1.send(value: RetryableProducer(value: retryableError).concat(queue.take(first: 1)))
                })
                .completeOnError()
            SignalProducer<RetryableNext<Value, Error>, Error>.merge([
                processedErrorsPipe.0.flatten(.latest).producer,
                valuesPipe.0.producer.map(RetryableNext<Value, Error>.some).promoteError(Error.self)
            ]).take(during: lifetime).start(observer)

            retryPipe.0.producer.flatMap(.latest) {
                selfWithSideEffects
            }.take(during: lifetime).start()

            retryPipe.1.send(value: ())
        }
    }
}

public struct RetryableAction<Input, Output, Error: Swift.Error> {

    public let action: Action<Input, Output, Error>
    public let error: Property<Retryable<Error>?>

    public init(original: Action<Input, Output, Error>) {

        let retryable = original.retryable()

        self.action = retryable.action
        self.error = Property(
            initial: nil,
            then: retryable.retryable
        ).skipNilRepeats()
    }
}

extension Action {

    public func retryable() -> (action: Action<Input, Output, Error>, retryable: Signal<Retryable<Error>?, NoError>) {

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

public extension Retryable {
    func map<T>(_ transform: (E) -> T) -> Retryable<T> {
        return Retryable<T>(
            error: transform(self.error),
            retry: self.retry,
            ignore: self.ignore
        )
    }
}

extension SignalProducer {
    func completeOnError() -> SignalProducer<Value, NoError> {
        return flatMapError { _ in .empty }
    }
}

extension Property where Value: OptionalType {
    func skipNilRepeats() -> Property<Value> {
        return self.skipRepeats { $0.optional == nil && $1.optional == nil }
    }
}

extension Signal where Value: OptionalType {
    func skipNilRepeats() -> Signal<Value, Error> {
        return self.skipRepeats { $0.optional == nil && $1.optional == nil }
    }
}

protocol OptionalType {
    associatedtype Wrapped

    var optional: Wrapped? { get }
}

extension Optional: OptionalType {
    public var optional: Wrapped? {
        return self
    }
}

protocol ActionErrorType: Error {
    associatedtype UnderlyingError: Error
    var actionError: ActionError<UnderlyingError> { get }
}

extension ActionError: ActionErrorType {
    typealias UnderlyingError = Error
    var actionError: ActionError<UnderlyingError> { return self }
}

extension SignalProducer where Error: ActionErrorType {
    func expectedToBeEnabled() -> SignalProducer<Value, Error.UnderlyingError> {
        return self.producer.flatMapError { error in
            switch error.actionError {
            case let .producerFailed(e):
                return SignalProducer<Value, Error.UnderlyingError>(error: e)
            case .disabled:
                assertionFailure()
                return .empty
            }
        }
    }
}

public enum LoadingState<Value, Error> where Error: Swift.Error {
    case loading
    case loaded(Value)
    case error(Retryable<Error>)
    case ignored(Error)
}

extension RetryableAction {

    public func makeOneShotStateProperty(input: Input) -> Property<LoadingState<Output, Error>> {
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

func nilCoalescingFlatMap<T>(_ properties: [Property<T?>]) -> Property<T?> {
    guard let first = properties.first else { return Property(value: nil) }
    return first
        .skipNilRepeats()
        .flatMap(.latest) { (value: T?) -> Property<T?> in
            switch value {
            case let some?:
                return Property(value: some).map(Optional.init)
            case nil:
                return nilCoalescingFlatMap(Array(properties.suffix(from: 1)))
            }
        }
}

func nilCoalescingFlatMap<T>(_ properties: Property<T?>...) -> Property<T?> {
    return nilCoalescingFlatMap(properties)
}

extension Action {
    static func simple(
        enabledIf enabled: Property<Bool> = Property(value: true),
        f: @escaping () -> Void = {}
    ) -> Action {
        return Action(enabledIf: enabled) { _ in
            return SignalProducer { observer, _ in
                f()
                observer.sendCompleted()
            }
        }
    }
}

extension Signal where Value: OptionalType {
    func ignoreNil() -> Signal<Value.Wrapped, Error> {
        return filter { $0.optional != nil }.map { $0.optional! }
    }
}

extension SignalProducer where Value: OptionalType {
    func ignoreNil() -> SignalProducer<Value.Wrapped, Error> {
        return lift { $0.ignoreNil() }
    }
}

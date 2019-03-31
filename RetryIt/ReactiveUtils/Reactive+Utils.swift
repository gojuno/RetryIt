//
//  Reactive+Utils.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/31/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import ReactiveSwift
import Result

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

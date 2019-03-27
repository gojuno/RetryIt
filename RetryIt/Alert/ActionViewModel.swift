//
//  ActionViewModel.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/28/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import FraktalSimplified
import ReactiveSwift
import Result

// sourcery: presentableV2
final class ActionViewModel {

    let values: Signal<Void, NoError>
    let executed: Signal<Void, NoError>

    private init(own action: Action<Void, Void, NoError>) {

        self.action = action
        self.values = action.values
        self.executed = action.isExecuting.signal
            .filter { $0 == true }
            .map { _ in }

        self.disposable = ScopedDisposable(
            executionIntents.0.producer
                .filter { action.isEnabled.value }
                .flatMap(.latest) { action.apply().expectedToBeEnabled() }
                .start()
        )

        self.simpleAction = { [executionIntents] in
            executionIntents.1.send(value: ())
        }
        self.executing = self.action.isExecuting.skipRepeats()
        self.enabled = self.action.isExecuting.skipRepeats()
    }

    convenience init<P: PropertyProtocol>(enabledIf: P, _ apply: @escaping () -> SignalProducer<Void, NoError>) where P.Value == Bool {
        self.init(own: Action(enabledIf: enabledIf, execute: apply))
    }

    convenience init(_ action: Action<Void, Void, NoError>) {
        self.init(enabledIf: action.isEnabled) {
            action.apply().expectedToBeEnabled()
        }
    }

    // sourcery: presentable
    let simpleAction: () -> Void
    // sourcery: presentable, type = * Bool
    let executing: Property<Bool>
    // sourcery: presentable, type = * Bool, mock_value = true
    let enabled: Property<Bool>

    private let action: Action<Void, Void, NoError>
    private let executionIntents = Signal<Void, NoError>.pipe()
    private let disposable: ScopedDisposable<AnyDisposable>

    deinit {
        self.executionIntents.1.sendInterrupted()
    }
}

// sourcery:inline:ActionViewModel.Presentable
// swiftlint:disable line_length
extension ActionViewModel: Presentable {

    internal var present: (ActionViewModelPresenters) -> Disposable? {
        return { [weak self] presenters in
            guard let sself = self else { return nil }
            let disposable = CompositeDisposable()
            disposable += presenters.simpleAction.present(sself.simpleAction)
            disposable += presenters.executing.present(sself.executing)
            disposable += presenters.enabled.present(sself.enabled)
            return disposable
        }
    }
}
// swiftlint:enable line_length
// sourcery:end

// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length file_length
import FraktalSimplified

import ReactiveSwift


struct LoginScreenPresenters {

    let child: Presenter<LoginScreenChildAnyPresentable>
    let alert: Presenter<Alert>

    init(
        child: Presenter<LoginScreenChildAnyPresentable>,
        alert: Presenter<Alert>
    ) {
        self.child = child
        self.alert = alert
    }
}

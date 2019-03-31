// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length file_length
import FraktalSimplified

import ReactiveSwift


struct SuperSecuredScreenPresenters {

    let child: Presenter<SuperSecuredScreenChildAnyPresentable>
    let alert: Presenter<Alert>

    init(
        child: Presenter<SuperSecuredScreenChildAnyPresentable>,
        alert: Presenter<Alert>
    ) {
        self.child = child
        self.alert = alert
    }
}

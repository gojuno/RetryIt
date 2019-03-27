// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length file_length
import FraktalSimplified

import ReactiveSwift


struct ActionViewModelPresenters {

    let simpleAction: Presenter<() -> Void>
    let executing: Presenter<Bool>
    let enabled: Presenter<Bool>

    init(
        simpleAction: Presenter<() -> Void>,
        executing: Presenter<Bool>,
        enabled: Presenter<Bool>
    ) {
        self.simpleAction = simpleAction
        self.executing = executing
        self.enabled = enabled
    }
}

struct AlertContentPresenters {

    let title: Presenter<String?>
    let text: Presenter<String?>

    init(
        title: Presenter<String?>,
        text: Presenter<String?>
    ) {
        self.title = title
        self.text = text
    }
}

struct AlertActionPresenters {

    let title: Presenter<String>
    let style: Presenter<AlertActionStyle>
    let action: Presenter<FraktalSimplified.AnyPresentable<ActionViewModelPresenters>>

    init(
        title: Presenter<String>,
        style: Presenter<AlertActionStyle>,
        action: Presenter<FraktalSimplified.AnyPresentable<ActionViewModelPresenters>>
    ) {
        self.title = title
        self.style = style
        self.action = action
    }
}

struct AlertActionsPresenters {

    let primary: Presenter<FraktalSimplified.AnyPresentable<AlertActionPresenters>?>
    let secondary: Presenter<[FraktalSimplified.AnyPresentable<AlertActionPresenters>]>
    let cancel: Presenter<FraktalSimplified.AnyPresentable<AlertActionPresenters>?>

    init(
        primary: Presenter<FraktalSimplified.AnyPresentable<AlertActionPresenters>?>,
        secondary: Presenter<[FraktalSimplified.AnyPresentable<AlertActionPresenters>]>,
        cancel: Presenter<FraktalSimplified.AnyPresentable<AlertActionPresenters>?>
    ) {
        self.primary = primary
        self.secondary = secondary
        self.cancel = cancel
    }
}

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

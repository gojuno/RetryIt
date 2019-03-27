//
//  Alert.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/28/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import FraktalSimplified
import ReactiveSwift
import Result

final class Alert {

    // sourcery: presentable, type = ^Alert.Content
    let content: Content
    // sourcery: presentable, type = ^AlertActions
    let actions: AlertActions

    convenience init(
        title: String?,
        message: String?,
        actions: [AlertAction],
        cancel: AlertAction? = nil
    ) {
        self.init(title: title, message: message, primary: nil, secondary: actions, cancel: cancel)
    }

    convenience init(
        title: String?,
        message: String?,
        primary: AlertAction?,
        secondary: AlertAction? = nil,
        cancel: AlertAction? = nil
    ) {
        self.init(title: title, message: message, primary: primary, secondary: [secondary].compactMap { $0 }, cancel: cancel)
    }

    init(
        title: String?,
        message: String?,
        primary: AlertAction?,
        secondary: [AlertAction],
        cancel: AlertAction? = nil
    ) {
        self.content = Content(title: title, text: message)
        self.actions = AlertActions(primary: primary, secondary: secondary, cancel: cancel)
    }
}

extension Alert {
    // sourcery: presentableV2
    final class Content {

        // sourcery: presentable
        let title: String?
        // sourcery: presentable
        let text: String?

        init(title: String?, text: String?) {
            self.title = title
            self.text = text
        }
    }
}

// sourcery: presentableV2
final class AlertActions {

    // sourcery: presentable, type = ? ^AlertAction
    let primary: AlertAction?
    // sourcery: presentable, type = [] ^AlertAction
    let secondary: [AlertAction]
    // sourcery: presentable, type = ? ^AlertAction
    let cancel: AlertAction?

    convenience init(primary: AlertAction?, secondary: AlertAction? = nil, cancel: AlertAction? = nil) {
        self.init(primary: primary, secondary: [secondary].compactMap { $0 }, cancel: cancel)
    }

    init(primary: AlertAction?, secondary: [AlertAction], cancel: AlertAction? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.cancel = cancel
    }
}

// sourcery: presentableV2
final class AlertAction {

    // sourcery: presentable
    let title: String
    // sourcery: presentable
    let style: AlertActionStyle
    // sourcery: presentable
    let action: ActionViewModel

    init(
        title: String,
        style: AlertActionStyle,
        action: Action<Void, Void, NoError>
    ) {
        self.title = title
        self.style = style
        self.action = ActionViewModel(action)
    }

    convenience init(
        title: String,
        style: AlertActionStyle,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            style: style,
            action: .simple(f: action)
        )
    }
}


enum AlertActionStyle {
    case normal
    case highlighted
    case destructive
}

// sourcery:inline:Alert.Content.Presentable
// swiftlint:disable line_length
extension Alert.Content: Presentable {

    internal var present: (AlertContentPresenters) -> Disposable? {
        return { [weak self] presenters in
            guard let sself = self else { return nil }
            let disposable = CompositeDisposable()
            disposable += presenters.title.present(sself.title)
            disposable += presenters.text.present(sself.text)
            return disposable
        }
    }
}
// swiftlint:enable line_length
// sourcery:end

// sourcery:inline:AlertAction.Presentable
// swiftlint:disable line_length
extension AlertAction: Presentable {

    internal var present: (AlertActionPresenters) -> Disposable? {
        return { [weak self] presenters in
            guard let sself = self else { return nil }
            let disposable = CompositeDisposable()
            disposable += presenters.title.present(sself.title)
            disposable += presenters.style.present(sself.style)
            disposable += presenters.action.present(sself.action)
            return disposable
        }
    }
}
// swiftlint:enable line_length
// sourcery:end

// sourcery:inline:AlertActions.Presentable
// swiftlint:disable line_length
extension AlertActions: Presentable {

    internal var present: (AlertActionsPresenters) -> Disposable? {
        return { [weak self] presenters in
            guard let sself = self else { return nil }
            let disposable = CompositeDisposable()
            disposable += presenters.primary.present(sself.primary.map { FraktalSimplified.AnyPresentable<AlertActionPresenters>($0) })
            disposable += presenters.secondary.present(sself.secondary.map { FraktalSimplified.AnyPresentable<AlertActionPresenters>($0) })
            disposable += presenters.cancel.present(sself.cancel.map { FraktalSimplified.AnyPresentable<AlertActionPresenters>($0) })
            return disposable
        }
    }
}
// swiftlint:enable line_length
// sourcery:end


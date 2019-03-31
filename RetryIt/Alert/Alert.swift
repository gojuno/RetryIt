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

    let content: Content
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
    final class Content {

        let title: String?
        let text: String?

        init(title: String?, text: String?) {
            self.title = title
            self.text = text
        }
    }
}

final class AlertActions {

    let primary: AlertAction?
    let secondary: [AlertAction]
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

final class AlertAction {

    let title: String
    let style: AlertActionStyle
    let action: Action<Void, Void, NoError>

    init(
        title: String,
        style: AlertActionStyle,
        action: Action<Void, Void, NoError>
    ) {
        self.title = title
        self.style = style
        self.action = action
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

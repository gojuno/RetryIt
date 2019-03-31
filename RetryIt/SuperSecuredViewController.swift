//
//  ViewController.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import UIKit
import FraktalSimplified

final class SuperSecuredViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.view.addSubview(self.loadingView)
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentLabel)
        self.contentLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.loadingView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loadingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            self.contentLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.contentLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.contentLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8)
        ])
    }

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    private let loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.color = .black
        return view
    }()
}

extension SuperSecuredViewController {

    var presenter: Presenter<AnyPresentable<SuperSecuredScreenPresenters>> {
        return Presenter.UI { [weak self] presentable in
            guard let someSelf = self else {
                return nil
            }
            return presentable.present(
                SuperSecuredScreenPresenters(
                    child: someSelf.childPresenter,
                    alert: someSelf.alertPresenter
                )
            )
        }
    }

    private var childPresenter: Presenter<SuperSecuredScreenChildAnyPresentable> {
        return Presenter.UI { [weak self] presentable in
            guard let someSelf = self else {
                return nil
            }
            switch presentable {
            case let .content(biography):
                someSelf.loadingView.isHidden = true
                return someSelf.contentLabel.textPresenter.present(biography)
            case .loading:
                someSelf.loadingView.startAnimating()
                someSelf.loadingView.isHidden = false
                return nil
            case let .error(text):
                someSelf.loadingView.isHidden = true
                return someSelf.contentLabel.textPresenter.present(text)
            }
        }
    }

    private var alertPresenter: Presenter<Alert> {
        return Presenter.UI { [weak self] presentable in
            guard let someSelf = self else {
                return nil
            }
            someSelf.dismissAlert()
            someSelf.present(alert: presentable)
            return nil
        }
    }
}

private extension SuperSecuredViewController {

    func present(alert: Alert) {
        let alertController = UIAlertController(title: alert.content.title, message: alert.content.text, preferredStyle: .alert)
        if let primary = alert.actions.primary {
            alertController.addAction(UIAlertAction(primary))
        }
        if let cancel = alert.actions.cancel {
            alertController.addAction(UIAlertAction(cancel))
        }
        self.present(alertController, animated: true, completion: nil)
    }

    func dismissAlert() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}

private extension UIAlertAction {

    convenience init(_ alertAction: AlertAction) {
        self.init(title: alertAction.title, style: alertAction.style.uiStyle, handler: { _ in alertAction.action.apply().start() })
    }
}

private extension AlertActionStyle {

    var uiStyle: UIAlertAction.Style {
        switch self {
        case .destructive: return .destructive
        case .highlighted: return .default
        case .normal: return .default
        }
    }
}

//
//  AppDelegate.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 3/27/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import UIKit
import ReactiveSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = SuperSecuredViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window

        let screen = SuperSecuredScreen()
        self.superSecuredScreen = screen

        self.disposable = viewController.presenter.present(screen)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        disposable?.dispose()
    }

    private var superSecuredScreen: SuperSecuredScreen?
    private var disposable: Disposable?
}


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
        let viewController = ViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window

        let screen = LoginScreen()
        self.loginScreen = screen

        self.disposable = viewController.presenter.present(screen)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        disposable?.dispose()
    }

    private var loginScreen: LoginScreen?
    private var disposable: Disposable?
}


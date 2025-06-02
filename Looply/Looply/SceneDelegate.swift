//
//  SceneDelegate.swift
//  Looply
//
//  Created by 주지혜 on 6/2/25.
//

import UIKit
import SpotifyiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
    }


    func sceneDidDisconnect(_ scene: UIScene) {
        }

    func sceneDidBecomeActive(_ scene: UIScene) {
        }

    func sceneWillResignActive(_ scene: UIScene) {
        }

    func sceneWillEnterForeground(_ scene: UIScene) {
        }

    func sceneDidEnterBackground(_ scene: UIScene) {
        }


    // SceneDelegate 클래스 안에 이 함수 추가
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // ViewController에 있는 sessionManager로 전달
        if let rootVC = window?.rootViewController as? ViewController {
            rootVC.sessionManager.application(UIApplication.shared, open: url, options: [:])
        }
    }

}


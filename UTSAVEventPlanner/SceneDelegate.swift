//
//  SceneDelegate.swift
//  UTSAVEventPlanner
//
//  Created by Prince Rana on 08/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {


    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        // ✅ IMPORTANT:
        // Do NOT create a window here.
        // Do NOT set rootViewController.
        // The storyboard (Main.storyboard) will handle all of this.

        guard (scene as? UIWindowScene) != nil else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}

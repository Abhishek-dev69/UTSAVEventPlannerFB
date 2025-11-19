import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        let hasEvent = UserDefaults.standard.bool(forKey: "hasActiveEvent")

        if hasEvent {
            // 👉 User already created an event → directly open DashboardListViewController

            let dashboardVC = DashboardListViewController()
            let nav = UINavigationController(rootViewController: dashboardVC)

            let tab = UITabBarController()
            tab.viewControllers = [nav]

            window?.rootViewController = tab
        } else {
            // 👉 First time → load Main.storyboard entry (HomeScene)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootVC = storyboard.instantiateInitialViewController()!
            window?.rootViewController = rootVC
        }

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}


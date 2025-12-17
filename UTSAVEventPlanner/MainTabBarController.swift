//
//  MainTabBarController.swift
//  UTSAV
//
//  Created by Abhishek on 16/12/25.
//

import UIKit

final class MainTabBarController {

    static func make() -> UITabBarController {
        let tabBar = UITabBarController()

        let dashboard = DashboardListViewController()
        let dashNav = UINavigationController(rootViewController: dashboard)
        dashNav.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let payments = PaymentsRootController()
        let payNav = UINavigationController(rootViewController: payments)
        payNav.tabBarItem = UITabBarItem(
            title: "Payments",
            image: UIImage(systemName: "creditcard"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )

        let services = ServicesViewController()
        let svcNav = UINavigationController(rootViewController: services)
        svcNav.tabBarItem = UITabBarItem(
            title: "Services",
            image: UIImage(systemName: "storefront"),
            selectedImage: UIImage(systemName: "storefront.fill")
        )

        let inventory = InventoryRootController()
        let invNav = UINavigationController(rootViewController: inventory)
        invNav.tabBarItem = UITabBarItem(
            title: "Inventory",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )

        tabBar.viewControllers = [dashNav, payNav, svcNav, invNav]
        tabBar.tabBar.tintColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)

        return tabBar
    }
}

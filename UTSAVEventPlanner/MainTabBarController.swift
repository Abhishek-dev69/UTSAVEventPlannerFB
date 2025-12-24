import UIKit

final class MainTabBarController {

    static func make() -> UITabBarController {
        let tabBar = UITabBarController()

        // Dashboard
        let dashboard = DashboardListViewController()
        let dashNav = UINavigationController(rootViewController: dashboard)
        dashNav.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Payments
        let payments = PaymentsRootController()
        let payNav = UINavigationController(rootViewController: payments)
        payNav.tabBarItem = UITabBarItem(
            title: "Payments",
            image: UIImage(systemName: "creditcard"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )

        // Services
        let services = ServicesListViewController()
        let svcNav = UINavigationController(rootViewController: services)
        svcNav.tabBarItem = UITabBarItem(
            title: "Services",
            image: UIImage(systemName: "storefront"),
            selectedImage: UIImage(systemName: "storefront.fill")
        )

        // Inventory
        let inventory = InventoryRootController()
        let invNav = UINavigationController(rootViewController: inventory)
        invNav.tabBarItem = UITabBarItem(
            title: "Inventory",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )

        // Vendors
        let vendors = VendorMarketplaceViewController()
        let vendorNav = UINavigationController(rootViewController: vendors)
        vendorNav.tabBarItem = UITabBarItem(
            title: "Vendors",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )

        tabBar.viewControllers = [
            dashNav,
            payNav,
            svcNav,
            invNav,
            vendorNav
        ]

        tabBar.tabBar.tintColor = UIColor(
            red: 139/255,
            green: 59/255,
            blue: 240/255,
            alpha: 1
        )

        return tabBar
    }
}


import UIKit

final class MainTabBarController: UITabBarController {

    static func make() -> UITabBarController {

        let tabBar = MainTabBarController()

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

    // MARK: - Show Hint

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showServicesHint()
    }

    private func showServicesHint() {

        let alreadySeen = UserDefaults.standard.bool(forKey: "services_hint_seen")
        if alreadySeen { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {

            guard let items = self.tabBar.items,
                  items.count > 2 else { return }

            // Services tab index
            let index = 2

            let tabBarWidth = self.tabBar.frame.width
            let itemWidth = tabBarWidth / CGFloat(items.count)

            let xPosition = itemWidth * CGFloat(index) + itemWidth / 2

            let hint = TabBarHintView(
                message: "Add all your services here\n(Chairs, Tables, Decoration etc)"
            )
            
            self.view.addSubview(hint)

            NSLayoutConstraint.activate([
                hint.bottomAnchor.constraint(
                    equalTo: self.tabBar.topAnchor,
                    constant: -12
                ),
                hint.centerXAnchor.constraint(
                    equalTo: self.view.leadingAnchor,
                    constant: xPosition
                ),
                hint.widthAnchor.constraint(lessThanOrEqualToConstant: 220)
            ])

            UserDefaults.standard.set(true, forKey: "services_hint_seen")
        }
    }
}

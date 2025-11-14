import UIKit

final class BusinessViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var businessTitle: UILabel!
    @IBOutlet private weak var businessSubtitle: UILabel!

    @IBOutlet private weak var businessNameLabel: UILabel!
    @IBOutlet private weak var businessNameTextField: UITextField!

    @IBOutlet private weak var businessAddressLabel: UILabel!
    @IBOutlet private weak var businessAddressTextField: UITextField!

    @IBOutlet private weak var websiteLabel: UILabel!
    @IBOutlet private weak var websiteTextField: UITextField!

    @IBOutlet private weak var aboutUsLabel: UILabel!
    @IBOutlet private weak var aboutUsTextField: UITextField!

    @IBOutlet private weak var nextButton: UIButton!

    // Connect your vertical stack view from IB to this outlet (optional but used)
    @IBOutlet private weak var contentStackView: UIStackView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Make nav bar opaque and match view background
        navigationController?.navigationBar.isTranslucent = false
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label // back button color

        // iOS 13+ appearance (opaque background, no blur)
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 20, weight: .bold)
            ]
            appearance.shadowColor = .clear

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.compactAppearance  = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 20, weight: .bold)
            ]
            navigationController?.navigationBar.shadowImage = UIImage()
        }

        // Also remove any leftover shadow image
        navigationController?.navigationBar.shadowImage = UIImage()

        // 2) Place the header text inside the nav bar (so it aligns with back button)
        let navTitleLabel = UILabel()
        navTitleLabel.text = "Create Your Business Profile"
        navTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        navTitleLabel.textColor = .label
        navTitleLabel.numberOfLines = 1
        navTitleLabel.textAlignment = .center
        navTitleLabel.adjustsFontSizeToFitWidth = true
        navTitleLabel.minimumScaleFactor = 0.7
        navTitleLabel.sizeToFit()
        navigationItem.titleView = navTitleLabel

        // 3) Hide the in-content title label so you don't have two titles
        businessTitle?.isHidden = true

        // 4) Prevent view content from extending under bars (extra safety)
        edgesForExtendedLayout = []

        // --- CUSTOM STACK SPACING ADJUSTMENTS ---
        if let stack = contentStackView {
            // Reduce space between (hidden) title and subtitle
            stack.setCustomSpacing(0, after: businessTitle)
            stack.setCustomSpacing(2, after: businessSubtitle)

            // Keep good spacing before Continue button
            stack.setCustomSpacing(32, after: aboutUsTextField)

            stack.layoutIfNeeded()
        }

        // Keep existing styling and setup
        styleUI()
        nextButton.setTitle("Continue", for: .normal)
    }

    // MARK: - Actions
    @IBAction private func nextButtonTapped(_ sender: UIButton) {
        let name    = businessNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let address = businessAddressTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let website = websiteTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let about   = aboutUsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Required: name, address, about
        guard !name.isEmpty, !address.isEmpty, !about.isEmpty else {
            showAlert(title: "Missing Information",
                      message: "Please fill Business Name, Address, and About Us.")
            return
        }

        // Website optional; validate if present
        if !website.isEmpty, !isValidWebsite(website) {
            showAlert(title: "Invalid Website",
                      message: "Please enter a valid URL, e.g. example.com or https://example.com.")
            return
        }

        // Present the tab bar controller (built in code)
        presentMainTabBarAsRoot()
    }

    // MARK: - Build & present tab bar (in-code; no MyTabBarController file required)
    private func makeMainTabBar() -> UITabBarController {
        let tabBar = UITabBarController()

        // Your SF Symbols
        let symbols: [(String, String)] = [
            ("house", "house.fill"),
            ("creditcard", "creditcard.fill"),
            ("storefront", "storefront.fill"),
            ("cart", "cart.fill")
        ]

        // Home (XIB-backed HomeSceneViewController)
        let homeVC = HomeSceneViewController() // loadView() will load XIB
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home",
                                          image: UIImage(systemName: symbols[0].0),
                                          selectedImage: UIImage(systemName: symbols[0].1))

        // Payments (replace init with nib/storyboard if required)
        let paymentsVC = PaymentsViewController()
        let paymentsNav = UINavigationController(rootViewController: paymentsVC)
        paymentsNav.tabBarItem = UITabBarItem(title: "Payments",
                                              image: UIImage(systemName: symbols[1].0),
                                              selectedImage: UIImage(systemName: symbols[1].1))

        // Services
        let servicesVC = ServicesViewController()
        let servicesNav = UINavigationController(rootViewController: servicesVC)
        servicesNav.tabBarItem = UITabBarItem(title: "Services",
                                              image: UIImage(systemName: symbols[2].0),
                                              selectedImage: UIImage(systemName: symbols[2].1))

        // Inventory
        let inventoryVC = InventoryViewController()
        let inventoryNav = UINavigationController(rootViewController: inventoryVC)
        inventoryNav.tabBarItem = UITabBarItem(title: "Inventory",
                                               image: UIImage(systemName: symbols[3].0),
                                               selectedImage: UIImage(systemName: symbols[3].1))

        tabBar.viewControllers = [homeNav, paymentsNav, servicesNav, inventoryNav]

        // Appearance
        tabBar.tabBar.tintColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1) // purple
        tabBar.tabBar.isTranslucent = false
        tabBar.selectedIndex = 0

        return tabBar
    }

    private func presentMainTabBarAsRoot() {
        let tabBar = makeMainTabBar()

        // Replace window root (scene-safe). Use soft fade; remove transition block for instant switch.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()

            // Gentle fade; remove if you want instant.
            UIView.transition(with: window, duration: 0.20, options: .transitionCrossDissolve, animations: nil)
        } else {
            // Fallback: present modally full screen
            tabBar.modalPresentationStyle = .fullScreen
            present(tabBar, animated: true)
        }
    }

    // MARK: - UI Styling
    private func styleUI() {
        [
            businessNameTextField,
            businessAddressTextField,
            websiteTextField,
            aboutUsTextField
        ].forEach { styleTextField($0) }

        styleButton(nextButton)

        // keep subtitle visible below nav bar if you want
        businessSubtitle?.isHidden = false
    }

    /// iOS-native filled text field: visible on light/dark, no glass, no shadows.
    private func styleTextField(_ tf: UITextField?) {
        guard let tf = tf else { return }

        tf.borderStyle = .none
        tf.backgroundColor = .secondarySystemBackground   // filled style
        tf.layer.cornerRadius = 12
        tf.layer.masksToBounds = true

        // subtle 1pt border for contrast on very light backgrounds
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray4.cgColor

        // default blue caret & selection (iOS look)
        tf.tintColor = .systemBlue

        // left padding
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always

        // placeholders & keyboards
        if tf == businessNameTextField    { tf.placeholder = "Business Name" }
        if tf == businessAddressTextField { tf.placeholder = "Business Address" }
        if tf == websiteTextField {
            tf.placeholder = "Website URL (optional)"
            tf.keyboardType = .URL
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        if tf == aboutUsTextField         { tf.placeholder = "About Us" }
    }

    private func styleButton(_ button: UIButton) {
        button.layer.cornerRadius = 22
        button.backgroundColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1) // #8B3BF0
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - Helpers
    private func isValidWebsite(_ text: String) -> Bool {
        let normalized = normalizedURLString(from: text)
        guard let url = URL(string: normalized) else { return false }
        return ["http", "https"].contains(url.scheme) && url.host != nil
    }

    private func normalizedURLString(from text: String) -> String {
        let lower = text.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return text }
        return "https://\(text)"
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

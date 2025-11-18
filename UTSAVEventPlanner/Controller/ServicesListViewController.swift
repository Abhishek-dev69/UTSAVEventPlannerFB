import UIKit
import Supabase

final class ServicesListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let saveButton = UIButton(type: .system)

    // MARK: - Data
    private var services: [Service] = [] {
        didSet { tableView.reloadData() }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "All Services"
        setupNavBar()
        setupTableView()
        setupSaveButton()
        setupLayout()

        Task { await fetchAllServices() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await fetchAllServices() }
    }

    // MARK: - Setup UI
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addServiceTapped)
        )
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServiceCell.self, forCellReuseIdentifier: ServiceCell.reuseID)
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }

    private func setupSaveButton() {
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        saveButton.backgroundColor = UIColor(red: 138/255, green: 73/255, blue: 246/255, alpha: 1)
        saveButton.layer.cornerRadius = 24
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveEventTapped), for: .touchUpInside)
        view.addSubview(saveButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Fetch from Supabase
    func fetchAllServices() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()

            let mapped: [Service] = records.map { rec in
                let subModels = (rec.subservices ?? []).map { sub in
                    Subservice(
                        id: sub.id,
                        name: sub.name,
                        rate: sub.rate,
                        unit: sub.unit,
                        image: nil
                    )
                }

                return Service(
                    name: rec.name,
                    subservices: subModels
                )
            }

            await MainActor.run { self.services = mapped }

        } catch {
            print("❌ Fetch failed:", error)
        }
    }

    // MARK: - Actions
    @objc private func addServiceTapped() {
        let vc = ServiceAddingViewController(nibName: "ServiceAddingViewController", bundle: .main)
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        vc.onServiceSave = { [weak self] _ in
            Task { await self?.fetchAllServices() }
        }

        present(vc, animated: true)
    }

    // MARK: - NEW: build main tab bar
    private func makeMainTabBar() -> UITabBarController {
        let tabBar = UITabBarController()

        let symbols: [(String, String)] = [
            ("house", "house.fill"),
            ("creditcard", "creditcard.fill"),
            ("storefront", "storefront.fill"),
            ("cart", "cart.fill")
        ]

        // HOME
        let homeVC = OnboardingWelcomeViewController(nibName: "OnboardingWelcomeViewController", bundle: .main)
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home",
                                          image: UIImage(systemName: symbols[0].0),
                                          selectedImage: UIImage(systemName: symbols[0].1))

        // PAYMENTS (IMPORTANT FIX)
        let paymentsVC = PaymentsRootController()   // ✔ Correct screen
        let paymentsNav = UINavigationController(rootViewController: paymentsVC)
        paymentsNav.tabBarItem = UITabBarItem(title: "Payments",
                                              image: UIImage(systemName: symbols[1].0),
                                              selectedImage: UIImage(systemName: symbols[1].1))

        // SERVICES
        let servicesVC = ServicesViewController()
        let servicesNav = UINavigationController(rootViewController: servicesVC)
        servicesNav.tabBarItem = UITabBarItem(title: "Services",
                                              image: UIImage(systemName: symbols[2].0),
                                              selectedImage: UIImage(systemName: symbols[2].1))

        // INVENTORY
        let inventoryVC = InventoryRootController()
        let inventoryNav = UINavigationController(rootViewController: inventoryVC)
        inventoryNav.tabBarItem = UITabBarItem(title: "Inventory",
                                               image: UIImage(systemName: symbols[3].0),
                                               selectedImage: UIImage(systemName: symbols[3].1))

        tabBar.viewControllers = [homeNav, paymentsNav, servicesNav, inventoryNav]

        tabBar.tabBar.tintColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        tabBar.tabBar.isTranslucent = false

        return tabBar
    }

    @objc private func saveEventTapped() {

        if services.isEmpty {
            let alert = UIAlertController(title: "No Services", message: "Add at least one service first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let tabBar = makeMainTabBar()

        // Replace window root
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        } else {
            tabBar.modalPresentationStyle = .fullScreen
            present(tabBar, animated: true)
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    func setServices(_ list: [Service]) {
        self.services = list
    }
}

// MARK: - TableView
extension ServicesListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceCell.reuseID, for: indexPath)
        let svc = services[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = svc.name
        config.secondaryText = "\(svc.subservices.count) sub-services"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = services[indexPath.row]
        let vc = SubservicesListViewController(service: selected)

        vc.onSubservicesChanged = { [weak self] updatedList in
            self?.services[indexPath.row].subservices = updatedList
            Task { await self?.fetchAllServices() }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}


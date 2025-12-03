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
        title = "My Services"
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

    // MARK: - Fetch Services
    func fetchAllServices() async {
        do {
            let records = try await SupabaseManager.shared.fetchServices()

            let mapped: [Service] = records.map { rec in
                // Map subservice records to UI Subservice model.
                // If your server returns an `is_fixed` field in SubserviceRecord,
                // replace the `isFixed: true` below with `isFixed: $0.is_fixed ?? true`
                let subs = (rec.subservices ?? []).map {
                    Subservice(
                        id: $0.id,
                        name: $0.name,
                        rate: $0.rate,
                        unit: $0.unit,
                        image: nil,
                        isFixed: true
                    )
                }
                // Provide the service id as well (Service has id: String?)
                return Service(id: rec.id, name: rec.name, subservices: subs)
            }

            await MainActor.run { self.services = mapped }

        } catch {
            print("❌ Fetch failed:", error)
        }
    }

    // MARK: - Open Add Service Sheet
    @objc private func addServiceTapped() {
        let vc = ServiceAddingViewController()
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        vc.onServiceSave = { [weak self] _ in
            Task { await self?.fetchAllServices() }
        }

        present(vc, animated: true)
    }

    // MARK: - Save -> Go to Dashboard
    @objc private func saveEventTapped() {

        if services.isEmpty {
            let alert = UIAlertController(title: "No Services", message: "Please add at least one service.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        goToMainDashboard()
    }

    private func goToMainDashboard() {
        let tabBar = makeMainTabBar()

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        } else {
            tabBar.modalPresentationStyle = .fullScreen
            present(tabBar, animated: true)
        }
    }

    // MARK: - Tab Bar Builder
    private func makeMainTabBar() -> UITabBarController {
        let tabBar = UITabBarController()

        let homeVC = OnboardingWelcomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        let paymentsVC = PaymentsRootController()
        let paymentsNav = UINavigationController(rootViewController: paymentsVC)
        paymentsNav.tabBarItem = UITabBarItem(title: "Payments", image: UIImage(systemName: "creditcard"), selectedImage: UIImage(systemName: "creditcard.fill"))

        let servicesVC = ServicesViewController()
        let servicesNav = UINavigationController(rootViewController: servicesVC)
        servicesNav.tabBarItem = UITabBarItem(title: "Services", image: UIImage(systemName: "storefront"), selectedImage: UIImage(systemName: "storefront.fill"))

        let inventoryVC = InventoryRootController()
        let inventoryNav = UINavigationController(rootViewController: inventoryVC)
        inventoryNav.tabBarItem = UITabBarItem(title: "Inventory", image: UIImage(systemName: "cart"), selectedImage: UIImage(systemName: "cart.fill"))

        tabBar.viewControllers = [homeNav, paymentsNav, servicesNav, inventoryNav]
        tabBar.tabBar.tintColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)

        return tabBar
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - TableView

extension ServicesListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ t: UITableView, numberOfRowsInSection section: Int) -> Int { services.count }

    func tableView(_ t: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = t.dequeueReusableCell(withIdentifier: ServiceCell.reuseID, for: indexPath)
        let svc = services[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = svc.name
        config.secondaryText = "\(svc.subservices.count) sub-services"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ t: UITableView, didSelectRowAt indexPath: IndexPath) {
        t.deselectRow(at: indexPath, animated: true)
        let svc = services[indexPath.row]
        let vc = SubservicesListViewController(service: svc)

        vc.onSubservicesChanged = { [weak self] list in
            self?.services[indexPath.row].subservices = list
            Task { await self?.fetchAllServices() }
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}


import UIKit

final class InventoryRootController: UIViewController {

    // MARK: - UI
    private let headerView = UIView()
    private let titleLabel = UILabel()

    private let emptyVC = InventoryEmptyViewController()
    private var listVC: InventoryEventsListViewController?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide nav bar only on Inventory root
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // 🔥 Re-enable nav bar for pushed screens
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Header (MATCHES Dashboard & Payments)
    private func setupHeader() {
        headerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.text = "Inventory"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
    }

    // MARK: - Reload
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load / Show
    private func loadEvents() async {
        do {
            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                if events.isEmpty {
                    show(emptyVC)
                } else {
                    if listVC == nil {
                        listVC = InventoryEventsListViewController()
                    }
                    show(listVC!)
                    Task { await listVC?.refreshEvents() }
                }
            }
        } catch {
            print("Inventory load error:", error)
            await MainActor.run { show(emptyVC) }
        }
    }

    private func show(_ vc: UIViewController) {

        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }
}


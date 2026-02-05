import UIKit

final class InventoryRootController: UIViewController {

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let searchBar = UISearchBar()

    private let emptyVC = InventoryEmptyViewController()
    private var listVC: InventoryEventsListViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupSearchBar()
        setupKeyboardDismissTap()

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
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.text = "Inventory"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
    }

    // MARK: - Search
    private func setupSearchBar() {
        searchBar.placeholder = "Search events"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Keyboard
    private func setupKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    // MARK: - Reload
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load
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
            vc.view.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }
}

// MARK: - Search forwarding
extension InventoryRootController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        (children.first as? EventSearchable)?.updateSearch(text: searchText)
    }
}


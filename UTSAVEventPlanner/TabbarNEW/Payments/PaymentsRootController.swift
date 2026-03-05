import UIKit

// MARK: - Protocols
protocol EventSearchable: AnyObject {
    func updateSearch(text: String)
}

protocol VendorSearchable: AnyObject {
    func updateVendorSearch(text: String)
}

final class PaymentsRootController: UIViewController {

    // MARK: - UI
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let segmented = UISegmentedControl(items: ["Client Payments", "Vendor Payments"])
    private let searchBar = UISearchBar()

    // MARK: - Child VCs
    private let emptyVC = PaymentsEmptyViewController()
    private var clientListVC: PaymentsEventsListViewController?
    private let vendorListVC = VendorPaymentsListViewController()

    // MARK: - State
    private var hasEvents = false
    private var currentChild: UIViewController?

    // MARK: - Theme
    private let utsavPurple = UIColor(red: 136/255, green: 71/255, blue: 246/255, alpha: 1)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupSegmented()
        setupSearchBar()
        setupKeyboardDismissTap()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: Notification.Name("ReloadEventsDashboard"),
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

        titleLabel.text = "Payments"
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

    // MARK: - Segmented Control
    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = utsavPurple
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Search Bar
    private func setupSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Keyboard Dismiss
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

    // MARK: - Load Events
    private func loadEvents() async {

        // 1️⃣ Load cached events first
        if PaymentsEventStore.shared.hasCache {

            let cached = PaymentsEventStore.shared.cachedEvents

            await MainActor.run {
                hasEvents = !cached.isEmpty

                if hasEvents, clientListVC == nil {
                    clientListVC = PaymentsEventsListViewController()
                }

                showCurrentSegment()
            }

            // 🔴 IMPORTANT: refresh list using cached data
            if hasEvents {
                await clientListVC?.refreshEvents()
            }

            return
        }

        // 2️⃣ If no cache → call API
        do {

            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            PaymentsEventStore.shared.set(events)

            await MainActor.run {

                hasEvents = !events.isEmpty

                if hasEvents, clientListVC == nil {
                    clientListVC = PaymentsEventsListViewController()
                }

                showCurrentSegment()
            }

            if hasEvents {
                await clientListVC?.refreshEvents()
            }

        } catch {

            await MainActor.run {
                hasEvents = false
                showCurrentSegment()
            }
        }
    }
    // MARK: - Segment Switch
    @objc private func segmentChanged() {
        showCurrentSegment()
    }

    private func showCurrentSegment() {

        if segmented.selectedSegmentIndex == 0 {
            // Client Payments
            searchBar.placeholder = "Search events"

            if hasEvents, let clientVC = clientListVC {
                show(clientVC)
            } else {
                show(emptyVC)
            }

        } else {
            // Vendor Payments
            searchBar.placeholder = "Search vendors"
            show(vendorListVC)
        }
    }

    // MARK: - Child Handling
    private func show(_ vc: UIViewController) {
        if currentChild === vc { return }

        currentChild?.willMove(toParent: nil)
        currentChild?.view.removeFromSuperview()
        currentChild?.removeFromParent()

        currentChild = vc
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

// MARK: - Search Routing
extension PaymentsRootController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if segmented.selectedSegmentIndex == 0 {
            (currentChild as? EventSearchable)?.updateSearch(text: searchText)
        } else {
            (currentChild as? VendorSearchable)?.updateVendorSearch(text: searchText)
        }
    }
}


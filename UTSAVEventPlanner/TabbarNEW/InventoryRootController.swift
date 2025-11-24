import UIKit

final class InventoryRootController: UIViewController {

    private let emptyVC = InventoryEmptyViewController()
    private var listVC: InventoryEventsListViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Root controller title (default)
        self.navigationItem.title = "Inventory"
        navigationItem.largeTitleDisplayMode = .always

        // Listen for external event creations so this screen refreshes immediately
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )

        Task { await loadEvents() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make sure nav bar is visible
        navigationController?.navigationBar.isHidden = false

        // Refresh list if it exists (keeps UI fresh when returning)
        if let listVC = listVC {
            Task { await listVC.refreshEvents() }
        }
    }

    // MARK: - Notification handler

    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load / Show

    /// Loads events for the current user and shows either the empty screen or the events list.
    private func loadEvents() async {
        do {
            // Use unified fetch used by Dashboard to avoid mismatch with other fetch variants.
            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                if events.isEmpty {
                    show(emptyVC)
                } else {
                    if listVC == nil {
                        let list = InventoryEventsListViewController()
                        listVC = list
                        show(list)
                    }
                    // Ask the list VC to refresh its own internal data (it will fetch events as needed)
                    Task { await listVC?.refreshEvents() }
                }
            }

        } catch {
            // Log error for easier debugging and show empty view
            print("InventoryRootController.loadEvents error:", error)
            await MainActor.run { show(emptyVC) }
        }
    }

    private func show(_ vc: UIViewController) {

        // Remove old child
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        // Add new child
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)

        // Set appropriate navigation bar title based on which screen is visible
        if vc is InventoryEventsListViewController {
            self.navigationItem.title = "All Events Allocated Inventory"
        } else {
            self.navigationItem.title = "Inventory"
        }
    }
}


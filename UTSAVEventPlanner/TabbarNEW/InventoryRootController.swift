import UIKit

final class InventoryRootController: UIViewController {

    private let emptyVC = InventoryEmptyViewController()
    private var listVC: InventoryEventsListViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Root controller title (default)
        self.navigationItem.title = "Inventory"
        navigationItem.largeTitleDisplayMode = .always

        Task { await loadEvents() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make sure nav bar is visible
        navigationController?.navigationBar.isHidden = false

        if let listVC = listVC {
            Task { await listVC.refreshEvents() }
        }
    }

    private func loadEvents() async {
        do {
            let uid = try await SupabaseManager.shared.ensureUserId()
            let events = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)

            await MainActor.run {
                if events.isEmpty {
                    show(emptyVC)
                } else {
                    if listVC == nil {
                        let list = InventoryEventsListViewController()
                        listVC = list
                        show(list)
                    }
                    Task { await listVC?.refreshEvents() }
                }
            }

        } catch {
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

        // 🔥 FIX: Set correct navigation bar title based on which screen is visible
        if vc is InventoryEventsListViewController {
            self.navigationItem.title = "All Events Allocated Inventory"
        } else {
            self.navigationItem.title = "Inventory"
        }
    }
}


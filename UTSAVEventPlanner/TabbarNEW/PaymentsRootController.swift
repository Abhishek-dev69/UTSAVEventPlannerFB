import UIKit

final class PaymentsRootController: UIViewController {
    
    private let emptyVC = PaymentsEmptyViewController()
    private var listVC: PaymentsEventsListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Root title
        self.navigationItem.title = "Payments"
        navigationItem.largeTitleDisplayMode = .always
        
        // 🔥 Listen for event creation to refresh instantly
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
    // MARK: - Instant refresh when event is added
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }
    
    // MARK: - Load Events (uses unified fetch used by Dashboard)
    private func loadEvents() async {
        do {
            // Use unified fetch used by Dashboard to avoid mismatch with other fetch variants.
            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()
            
            await MainActor.run {
                if events.isEmpty {
                    show(emptyVC)
                } else {
                    if listVC == nil {
                        let list = PaymentsEventsListViewController()
                        listVC = list
                        show(list)
                    }
                    
                    // Ask child to refresh its own data
                    Task { await listVC?.refreshEvents() }
                }
            }
            
        } catch {
            print("PaymentsRootController.loadEvents error:", error)
            await MainActor.run { show(emptyVC) }
        }
    }
    
    // MARK: - Swap between empty + list screens
    private func show(_ vc: UIViewController) {
        
        // Remove old child VC
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        // Add new child VC
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        // Update title based on visible screen
        if vc is PaymentsEventsListViewController {
            self.navigationItem.title = "Payments"
        } else {
            self.navigationItem.title = "Payments"
        }
    }
}


import UIKit

final class PaymentsRootController: UIViewController {
    
    private let emptyVC = PaymentsEmptyViewController()
    private var listVC: PaymentsEventsListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // FIX: Set title here (root controller)
        self.navigationItem.title = "Payments"
        navigationItem.largeTitleDisplayMode = .always
        
        Task { await loadEvents() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // FIX: Make sure nav bar is visible
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
                        let list = PaymentsEventsListViewController()
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
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        // 🔥 FIX: Set navigation bar title based on which VC is visible
        if vc is PaymentsEventsListViewController {
            self.navigationItem.title = "All Events Payments Tracks"
        } else {
            self.navigationItem.title = "Payments"
        }
    }
}


import UIKit

final class PaymentsRootController: UIViewController {

    // MARK: - UI
    private let segmented = UISegmentedControl(items: ["Client Payments", "Vendor Payments"])

    // MARK: - Child VCs
    private let emptyVC = PaymentsEmptyViewController()
    private var clientListVC: PaymentsEventsListViewController?
    private let vendorListVC = VendorPaymentsListViewController()

    // MARK: - State
    private var hasEvents = false
    private var currentChild: UIViewController?
    
    private let utsavPurple = UIColor(
        red: 136/255,
        green: 71/255,
        blue: 246/255,
        alpha: 1
    )


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNav()
        setupSegmented()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEventsNow),
            name: Notification.Name("ReloadEventsDashboard"),
            object: nil
        )

        Task { await loadEvents() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation
    private func setupNav() {
        navigationItem.title = "Payments"
        navigationItem.largeTitleDisplayMode = .always
    }

    // MARK: - Segmented Control (FIXED)
    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0

        // ✅ MATCH DASHBOARD STYLE
        segmented.selectedSegmentTintColor = utsavPurple
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.gray],
            for: .normal
        )

        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Reload when event added
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load Events (Client Payments only)
    private func loadEvents() async {
        do {
            let events = try await EventSupabaseManager.shared.fetchAllEventsForUser()

            await MainActor.run {
                self.hasEvents = !events.isEmpty

                if self.clientListVC == nil {
                    self.clientListVC = PaymentsEventsListViewController()
                }

                self.showCurrentSegment()
                Task { await self.clientListVC?.refreshEvents() }
            }
        } catch {
            print("PaymentsRootController.loadEvents error:", error)
            await MainActor.run {
                self.hasEvents = false
                self.showCurrentSegment()
            }
        }
    }

    // MARK: - Segment Switch
    @objc private func segmentChanged() {
        showCurrentSegment()
    }

    private func showCurrentSegment() {
        if segmented.selectedSegmentIndex == 0 {
            if hasEvents, let clientVC = clientListVC {
                show(clientVC)
            } else {
                show(emptyVC)
            }
        } else {
            show(vendorListVC)
        }
    }

    // MARK: - Child VC Handling (FIXED)
    private func show(_ vc: UIViewController) {

        // Avoid re-adding same VC
        if currentChild === vc { return }

        // Remove old child
        if let current = currentChild {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        currentChild = vc

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }
}


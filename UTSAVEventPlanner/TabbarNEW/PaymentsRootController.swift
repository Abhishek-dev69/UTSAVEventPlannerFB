import UIKit

final class PaymentsRootController: UIViewController {

    // MARK: - UI
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let segmented = UISegmentedControl(items: ["Client Payments", "Vendor Payments"])

    // MARK: - Child VCs
    private let emptyVC = PaymentsEmptyViewController()
    private var clientListVC: PaymentsEventsListViewController?
    private let vendorListVC = VendorPaymentsListViewController()

    // MARK: - State
    private var hasEvents = false
    private var currentChild: UIViewController?

    // MARK: - Theme
    private let utsavPurple = UIColor(
        red: 136/255,
        green: 71/255,
        blue: 246/255,
        alpha: 1
    )

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        setupHeader()
        setupSegmented()

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

    // MARK: - Header (Dashboard Style)
    private func setupHeader() {
        headerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.text = "Payments"
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

    // MARK: - Segmented Control
    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
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
            segmented.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Reload Events
    @objc private func reloadEventsNow() {
        Task { await loadEvents() }
    }

    // MARK: - Load Events (Client Payments)
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
            print("❌ Payments load error:", error)
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

    // MARK: - Child VC Handling
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


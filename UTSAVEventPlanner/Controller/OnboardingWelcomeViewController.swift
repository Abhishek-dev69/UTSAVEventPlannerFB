import UIKit

final class OnboardingWelcomeViewController: UIViewController {

    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var onboardingImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainStack: UIStackView!

    private var dashboardVC: DashboardListViewController?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadState),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        Task { await loadState() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Reload
    @objc private func reloadState() {
        Task { await loadState() }
    }

    // MARK: - Main Logic
    /// Decides whether to show onboarding or dashboard
    private func loadState() async {
        do {
            // Ensure user session exists
            _ = try await EventSupabaseManager.shared.ensureUserId()

            // Check if user has added any services
            let services = try await SupabaseManager.shared.fetchServices()

            await MainActor.run {
                if services.isEmpty {
                    showOnboarding()
                } else {
                    showDashboard()
                }
            }
        } catch {
            await MainActor.run {
                showOnboarding()
            }
        }
    }

    // MARK: - Show Onboarding
    private func showOnboarding() {
        mainStack.isHidden = false

        if let dash = dashboardVC {
            dash.willMove(toParent: nil)
            dash.view.removeFromSuperview()
            dash.removeFromParent()
            dashboardVC = nil
        }
    }

    // MARK: - Show Dashboard
    private func showDashboard() {
        mainStack.isHidden = true

        // Dashboard already shown → do nothing
        if dashboardVC != nil { return }

        let dash = DashboardListViewController()
        dashboardVC = dash

        addChild(dash)
        dash.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dash.view)

        NSLayoutConstraint.activate([
            dash.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dash.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dash.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dash.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        dash.didMove(toParent: self)
    }

    // MARK: - CTA (Add Services)
    @IBAction func createEventTapped(_ sender: Any) {
        let vc = ServiceAddingViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Styling
    private func styleUI() {

        titleLabel.text = "Add your services"
        headlineLabel.text = "Start by adding the services you offer"
        bodyLabel.text = "Once you add services, you can create events from your dashboard."

        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Add Services"
            cfg.baseBackgroundColor = UIColor(
                red: 0x8B/255,
                green: 0x3B/255,
                blue: 0xF0/255,
                alpha: 1
            )
            cfg.baseForegroundColor = .white
            cfg.cornerStyle = .large
            cfg.contentInsets = NSDirectionalEdgeInsets(
                top: 14,
                leading: 20,
                bottom: 14,
                trailing: 20
            )
            ctaButton.configuration = cfg
        } else {
            ctaButton.backgroundColor = UIColor(
                red: 0x8B/255,
                green: 0x3B/255,
                blue: 0xF0/255,
                alpha: 1
            )
            ctaButton.setTitle("Add Services", for: .normal)
            ctaButton.setTitleColor(.white, for: .normal)
        }

        ctaButton.layer.cornerRadius = 28
        ctaButton.layer.masksToBounds = true

        titleLabel.textColor = .label
        headlineLabel.textColor = .label
        bodyLabel.textColor = .secondaryLabel
        onboardingImage.contentMode = .scaleAspectFit
    }
}


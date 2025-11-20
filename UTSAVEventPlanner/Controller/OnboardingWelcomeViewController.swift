import UIKit

final class OnboardingWelcomeViewController: UIViewController {
    
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var onboardingImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainStack: UIStackView!
    
    private var dashboardVC: DashboardListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadEvents),
            name: NSNotification.Name("ReloadEventsDashboard"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        Task { await loadState() }
    }
    
    // MARK: - Reload
    @objc private func reloadEvents() {
        Task { await loadState() }
    }
    
    // MARK: - Main Logic (Services → Events → Dashboard)
    private func loadState() async {
        do {
            let uid = try await EventSupabaseManager.shared.ensureUserId()
            
            // 1️⃣ Check if user has services
            let services = try await SupabaseManager.shared.fetchServices()
            
            await MainActor.run {
                if services.isEmpty {
                    // No services → show onboarding
                    showOnboarding()
                } else {
                    // 2️⃣ Services exist → load events → show dashboard
                    Task {
                        let events = try await EventSupabaseManager.shared.fetchUserEvents(userId: uid)
                        await MainActor.run { self.showDashboard(events) }
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                showOnboarding()
            }
        }
    }
    
    // MARK: - Show onboarding
    private func showOnboarding() {
        mainStack.isHidden = false
        
        dashboardVC?.willMove(toParent: nil)
        dashboardVC?.view.removeFromSuperview()
        dashboardVC?.removeFromParent()
        dashboardVC = nil
    }
    
    // MARK: - Show dashboard
    private func showDashboard(_ events: [EventRecord]) {
        
        mainStack.isHidden = true
        
        if let dash = dashboardVC {
            dash.setEvents(events)
            return
        }
        
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
        dash.setEvents(events)
    }
    
    // MARK: - CTA (Add Services)
    @IBAction func createEventTapped(_ sender: Any) {
        let vc = ServiceAddingViewController()       // OPEN SERVICES SCREEN
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Styling
    private func styleUI() {
        
        // Update titles for Add Services onboarding
        titleLabel.text = "Add your services"
        headlineLabel.text = "Start by adding the services you offer"
        bodyLabel.text = "Once you add services, you can create events from your dashboard."
        
        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Add Services"
            cfg.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
            cfg.baseForegroundColor = .white
            cfg.cornerStyle = .large
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            ctaButton.configuration = cfg
        } else {
            ctaButton.backgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
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

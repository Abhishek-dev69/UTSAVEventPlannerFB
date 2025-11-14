import UIKit

final class OnboardingWelcomeViewController: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var onboardingImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainStack: UIStackView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()

        // optional: set a tab bar item if you want (can also be done when creating tab bar)
        tabBarItem = UITabBarItem(title: "Home",
                                  image: UIImage(systemName: "house"),
                                  selectedImage: UIImage(systemName: "house.fill"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide nav bar when this screen appears (works when embedded in a nav controller)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // restore nav bar for next controllers if they expect a visible nav bar
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Actions
    @IBAction func createEventTapped(_ sender: Any) {
        let vc = EventTypeViewController()

        // PRESENT event type INSIDE a nav controller so it has navigation bar & back button
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.prefersLargeTitles = false
        nav.setNavigationBarHidden(false, animated: false)

        present(nav, animated: true)
    }




    // MARK: - Private
    private func styleUI() {
        // Guard the outlet in case storyboards/nib not connected while previewing
        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()
            cfg.title = ctaButton?.title(for: .normal) ?? "Create your first event"
            cfg.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1) // #8B3BF0
            cfg.baseForegroundColor = .white
            cfg.cornerStyle = .large
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            ctaButton?.configuration = cfg
            ctaButton?.layer.cornerRadius = 28
            ctaButton?.layer.masksToBounds = true
        } else {
            ctaButton?.backgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
            ctaButton?.setTitleColor(.white, for: .normal)
            ctaButton?.layer.cornerRadius = 28
        }

        headlineLabel?.textColor = .label
        bodyLabel?.textColor = .secondaryLabel
        titleLabel?.textColor = .label

        onboardingImage?.contentMode = .scaleAspectFit

        // accessibility
        ctaButton?.accessibilityLabel = "Create your first event"
    }
}

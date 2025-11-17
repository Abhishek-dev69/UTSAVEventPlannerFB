import UIKit

final class HomeSceneViewController: UIViewController {

    @IBOutlet private weak var ctaButton: UIButton!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var heroImageView: UIImageView!
    @IBOutlet private weak var imageCardView: UIView!
    @IBOutlet private weak var welcomeLabel: UILabel!
    @IBOutlet private weak var mainStackView: UIStackView!
    
    static let identifier = "HomeScene"

    override func loadView() {
        let nib = UINib(nibName: "HomeSceneViewController", bundle: .main)
        guard let root = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("HomeSceneViewController.xib must have a top-level UIView")
        }
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""
        navigationController?.navigationBar.topItem?.title = ""

        ctaButton.addTarget(self, action: #selector(ctaTapped(_:)), for: .touchUpInside)

        setupUI()
    }

    private func setupUI() {
        mainStackView.alignment = .center
        mainStackView.spacing = 12

        welcomeLabel.text = "Welcome, Event Planner!"
        welcomeLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        welcomeLabel.textAlignment = .left

        headlineLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        headlineLabel?.textAlignment = .center

        bodyLabel?.font = UIFont.systemFont(ofSize: 16)
        bodyLabel?.textAlignment = .center
    }

    // Only CTA navigation — no dashboard logic here.
    @objc private func ctaTapped(_ sender: UIButton) {
        let addVC = ServiceAddingViewController(
            nibName: "ServiceAddingViewController",
            bundle: .main
        )
        addVC.originTabIndex = tabBarController?.selectedIndex ?? 0
        addVC.hidesBottomBarWhenPushed = true

        if let nav = navigationController {
            nav.pushViewController(addVC, animated: true)
        } else {
            addVC.modalPresentationStyle = .fullScreen
            present(addVC, animated: true)
        }
    }
}


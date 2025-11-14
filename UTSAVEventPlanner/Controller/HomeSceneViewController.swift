import UIKit

final class HomeSceneViewController: UIViewController {

    @IBOutlet private weak var ctaButton: UIButton!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var heroImageView: UIImageView!
    @IBOutlet private weak var imageCardView: UIView!
    @IBOutlet private weak var welcomeLabel: UILabel!
    @IBOutlet private weak var mainStackView: UIStackView!

    // Load from XIB
    override func loadView() {
        let nib = UINib(nibName: "HomeSceneViewController", bundle: .main)
        guard let root = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("HomeSceneViewController.xib must have a top-level UIView")
        }
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ctaButton.addTarget(self, action: #selector(ctaTapped(_:)), for: .touchUpInside)

        // --- Hide nav title (no "Home" at top) ---
        navigationItem.title = ""
        navigationController?.navigationBar.topItem?.title = ""
        
        
        

        // --- STACK: make children centered, but welcomeLabel will still be left-aligned text ---
        // Center arranged subviews horizontally (image, headline, body, button)
        mainStackView?.alignment = .center
        mainStackView?.distribution = .fill
        mainStackView?.spacing = 12 // global spacing (we'll fine tune per item below)

        // Make welcomeLabel stretch to full stack width so its text appears flush-left,
        // while other children remain centered.
        if let welcome = welcomeLabel, let stack = mainStackView {
            welcome.text = "Welcome, Event Planner!"
            welcome.font = UIFont.systemFont(ofSize: 26, weight: .bold)
            welcome.textColor = .label
            welcome.numberOfLines = 2
            welcome.textAlignment = .left

            // ensure welcome label matches stack width (so it looks left-aligned)
            welcome.translatesAutoresizingMaskIntoConstraints = false
            // Activate width constraint only once
            if welcome.constraints.first(where: { $0.identifier == "welcomeFullWidth" }) == nil {
                let wC = welcome.widthAnchor.constraint(equalTo: stack.widthAnchor)
                wC.identifier = "welcomeFullWidth"
                wC.isActive = true
            }
        }

        // --- Center headline and body text and make sizes comfortable ---
        headlineLabel?.textAlignment = .center
        headlineLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        headlineLabel?.numberOfLines = 2

        bodyLabel?.textAlignment = .center
        bodyLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        bodyLabel?.numberOfLines = 0

        // --- CTA button: compact pill, centered, fixed width (keeps it visually balanced) ---
        ctaButton?.contentEdgeInsets = UIEdgeInsets(top: 12, left: 28, bottom: 12, right: 28)
        ctaButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        ctaButton?.layer.cornerRadius = 20
        ctaButton?.clipsToBounds = true

        // Give the CTA a consistent width so it centers nicely
        if let cta = ctaButton, let stack = mainStackView {
            cta.translatesAutoresizingMaskIntoConstraints = false
            if cta.constraints.first(where: { $0.identifier == "ctaFixedWidth" }) == nil {
                let w = min(UIScreen.main.bounds.width - 120, 320) // adapt to screen width
                let wC = cta.widthAnchor.constraint(equalToConstant: w)
                wC.identifier = "ctaFixedWidth"
                wC.isActive = true
            }
        }

        // --- Custom spacing between specific items (smaller distances) ---
        // Order in your XIB stack: [welcomeLabel, imageCardView, headlineLabel, bodyLabel, ctaButton]
        // Tweak after each arranged subview if present
        if let stack = mainStackView {
            // after welcome -> image small gap
            if let welcome = welcomeLabel { stack.setCustomSpacing(10, after: welcome) }

            // after image -> headline smaller gap
            if let img = imageCardView { stack.setCustomSpacing(8, after: img) }

            // after headline -> body (tight)
            if let head = headlineLabel { stack.setCustomSpacing(6, after: head) }

            // after body -> CTA (a bit larger so button breathes)
            if let body = bodyLabel { stack.setCustomSpacing(16, after: body) }
        }

        // --- Reduce top spacing if XIB left large top gap: find stack top constraint and reduce it ---
        // This searches constraints on the stack's superview (safe area constraint) and reduces constant.
        if let stack = mainStackView, let superC = stack.superview {
            for constraint in superC.constraints {
                if (constraint.firstItem as AnyObject) === stack && constraint.firstAttribute == .top {
                    // adjust to a comfortable top margin (16-28)
                    constraint.constant = max(12, min(28, constraint.constant)) // keep in reasonable bounds
                }
            }
            // Also look at constraints defined on the stack itself (rare)
            for constraint in stack.constraints {
                if constraint.firstAttribute == .top {
                    constraint.constant = max(12, min(28, constraint.constant))
                }
            }
        }

        // final layout pass
        mainStackView?.setNeedsLayout()
        mainStackView?.layoutIfNeeded()
    }


    // MARK: - CTA
    @objc @IBAction private func ctaTapped(_ sender: UIButton) {
        let addVC = ServiceAddingViewController(nibName: "ServiceAddingViewController", bundle: .main)

        // Set the origin tab index so close can return properly
        if let tab = self.tabBarController {
            addVC.originTabIndex = tab.selectedIndex
        } else {
            // fallback: if no tabBarController, assume 0
            addVC.originTabIndex = 0
        }

        // hide tab when pushed (if you want)
        addVC.hidesBottomBarWhenPushed = true

        if let nav = navigationController {
            nav.pushViewController(addVC, animated: true)
        } else {
            addVC.modalPresentationStyle = .fullScreen
            present(addVC, animated: true)
        }
    }


}

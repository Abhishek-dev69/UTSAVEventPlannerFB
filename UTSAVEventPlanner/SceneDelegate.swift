import UIKit

// ---------------------------------------------------------------
// MARK: - Inline Splash View Controller (no external file needed)
// ---------------------------------------------------------------
final class InlineSplashViewController: UIViewController {

    var onAnimationCompleted: (() -> Void)?

    private var hasAnimated = false
    private var hasCompleted = false

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "UTSΛV"
        l.font = .systemFont(ofSize: 44, weight: .bold)
        l.textAlignment = .center
        l.alpha = 0
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Where Events Flow, Not Fail"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .center
        l.alpha = 0
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Solid purple background (#8A2BE2)
        view.backgroundColor = UIColor(red: 138/255, green: 43/255, blue: 226/255, alpha: 1.0)

        let stack = UIStackView(arrangedSubviews: [logoLabel, taglineLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimated else { return }
        hasAnimated = true

        animate()
    }

    private func animate() {

        logoLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: 8)

        UIView.animate(withDuration: 0.6,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.7,
                       options: .curveEaseOut,
                       animations: {
            self.logoLabel.alpha = 1
            self.logoLabel.transform = .identity
        }, completion: { _ in

            UIView.animate(withDuration: 0.4, animations: {
                self.taglineLabel.alpha = 1
            }, completion: { _ in

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.finish()
                }
            })
        })
    }

    private func finish() {
        guard !hasCompleted else { return }
        hasCompleted = true

        onAnimationCompleted?()
    }
}


// ---------------------------------------------------------------
// MARK: - SceneDelegate (clean, no SplashViewController references)
// ---------------------------------------------------------------
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let w = UIWindow(windowScene: windowScene)
        window = w

        // Create inline splash VC
        let splash = InlineSplashViewController()

        // Define what happens AFTER splash animation completes
        splash.onAnimationCompleted = { [weak self] in
            guard let self = self else { return }

            let hasEvent = UserDefaults.standard.bool(forKey: "hasActiveEvent")

            let nextRoot: UIViewController

            if hasEvent {
                // Dashboard flow
                let dashboardVC = DashboardListViewController()
                nextRoot = UINavigationController(rootViewController: dashboardVC)
            } else {
                // Load initial VC from Main.storyboard
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                nextRoot = storyboard.instantiateInitialViewController() ?? UIViewController()
            }

            // Transition
            UIView.transition(with: w,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: {
                self.window?.rootViewController = nextRoot
            })
        }

        // Show splash immediately
        w.rootViewController = splash
        w.makeKeyAndVisible()
    }
}

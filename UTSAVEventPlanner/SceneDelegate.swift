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
// MARK: - SceneDelegate (with OAuth callback handling)
// ---------------------------------------------------------------
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let w = UIWindow(windowScene: windowScene)
        self.window = w

        // Create inline splash VC
        let splash = InlineSplashViewController()

        // Define what happens AFTER splash animation completes
        splash.onAnimationCompleted = { [weak self] in
            guard let self = self else { return }

            // Example logic: check a simple UserDefaults flag to decide where to go.
            // Replace this logic with your real onboarding / dashboard routing.
            let hasEvent = UserDefaults.standard.bool(forKey: "hasActiveEvent")

            let nextRoot: UIViewController

            if hasEvent {
                // Dashboard flow — replace with your real dashboard controller
                if let dashboard = tryInstantiateDashboard() {
                    nextRoot = UINavigationController(rootViewController: dashboard)
                } else {
                    nextRoot = fallbackInitialController()
                }
            } else {
                // Load initial VC from Main.storyboard (or create programmatically)
                nextRoot = fallbackInitialController()
            }

            // Cross-dissolve transition to the main UI
            UIView.transition(with: w,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: {
                w.rootViewController = nextRoot
            }, completion: nil)
        }

        // Show splash immediately
        w.rootViewController = splash
        w.makeKeyAndVisible()

        // If app was opened via URL while cold-starting, forward to auth handler here as well.
        // This covers the case where the OAuth callback arrives before the app finishes launching.
        if !connectionOptions.urlContexts.isEmpty {
            for ctx in connectionOptions.urlContexts {
                handleIncomingURL(ctx.url)
            }
        }
    }

    // Called when the app receives an incoming URL while running (or in background)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard !URLContexts.isEmpty else { return }
        for ctx in URLContexts {
            handleIncomingURL(ctx.url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        NSLog("SceneDelegate: received URL -> %@", url.absoluteString)

        // Forward the callback URL to SupabaseManager which will parse and complete the session.
        Task { @MainActor in
            do {
                try await SupabaseManager.shared.handleAuthCallback(url)
                NSLog("SceneDelegate: successfully handed callback to SupabaseManager")
            } catch {
                NSLog("SceneDelegate: failed to handle auth callback: %@", String(describing: error))
                // Present a small alert so you notice the problem while debugging
                presentAuthError(error)
            }
        }
    }

    // Present a brief alert on the visible root VC (useful while debugging auth)
    private func presentAuthError(_ error: Error) {
        guard let window = self.window, let root = window.rootViewController else {
            return
        }
        let message = String(describing: error)
        let alert = UIAlertController(title: "Auth callback failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        // Present on main thread
        DispatchQueue.main.async {
            // If splash is visible (and animation not finished) this will still present.
            root.present(alert, animated: true, completion: nil)
        }
    }

    // Helper: instantiate DashboardListViewController safely (if you have that class)
    private func tryInstantiateDashboard() -> UIViewController? {
        // If you have a DashboardListViewController class in your project, return it.
        // Otherwise fallback to storyboard initial controller below.
        if let cls = NSClassFromString("DashboardListViewController") as? UIViewController.Type {
            return cls.init()
        }
        // If the class is in the module (Swift namespaced), try constructing directly:
        if let dashboard = tryCreateSwiftDashboard() {
            return dashboard
        }
        return nil
    }

    private func tryCreateSwiftDashboard() -> UIViewController? {
        // If you can import or reference the Swift type directly, construct it here.
        // For safety, we keep this a no-op if the symbol isn't present.
        // Example: return DashboardListViewController()
        return nil
    }

    // Helper: fallback initial controller from Main.storyboard (or blank VC)
    private func fallbackInitialController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let initial = storyboard.instantiateInitialViewController() {
            return initial
        }
        // As a last resort return a blank controller so app doesn't crash
        let blank = UIViewController()
        blank.view.backgroundColor = .systemBackground
        return blank
    }

    // Optional: other lifecycle hooks you might use
    func sceneDidDisconnect(_ scene: UIScene) { /* no-op */ }
    func sceneDidBecomeActive(_ scene: UIScene) { /* no-op */ }
    func sceneWillResignActive(_ scene: UIScene) { /* no-op */ }
    func sceneWillEnterForeground(_ scene: UIScene) { /* no-op */ }
    func sceneDidEnterBackground(_ scene: UIScene) { /* no-op */ }
}


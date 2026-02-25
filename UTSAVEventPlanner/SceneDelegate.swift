
import UIKit
internal import Auth
import Supabase

// ---------------------------------------------------------------
// MARK: - Inline Splash View Controller
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
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Where Events Flow, Not Fail"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .center
        l.alpha = 0
        l.textColor = .white
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(
            red: 138/255,
            green: 43/255,
            blue: 226/255,
            alpha: 1
        )

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
        logoLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            .translatedBy(x: 0, y: 8)

        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.7,
            options: .curveEaseOut,
            animations: {
                self.logoLabel.alpha = 1
                self.logoLabel.transform = .identity
            },
            completion: { _ in
                UIView.animate(withDuration: 0.4, animations: {
                    self.taglineLabel.alpha = 1
                }, completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        self.finish()
                    }
                })
            }
        )
    }

    private func finish() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onAnimationCompleted?()
    }
}

// ---------------------------------------------------------------
// MARK: - SceneDelegate (FIXED)
// ---------------------------------------------------------------
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        self.window = window

        let splashVC = InlineSplashViewController()

        splashVC.onAnimationCompleted = { [weak self] in
            guard let self = self else { return }
            self.restoreSessionAndSetRoot(window: window)
        }

        window.rootViewController = splashVC
        window.makeKeyAndVisible()

        // Handle OAuth callback on cold start
        if !connectionOptions.urlContexts.isEmpty {
            for ctx in connectionOptions.urlContexts {
                handleIncomingURL(ctx.url)
            }
        }
    }

    // ---------------------------------------------------------------
    // MARK: - 🔥 SESSION RESTORATION (THE REAL FIX)
    // ---------------------------------------------------------------
    private func restoreSessionAndSetRoot(window: UIWindow) {

        Task {
            do {
                // 🔥 Force Supabase to restore saved session
                let session = try await SupabaseManager.shared.client.auth.session

                print("✅ Session restored for user:", session.user.id)

                await MainActor.run {
                    UIView.transition(
                        with: window,
                        duration: 0.35,
                        options: .transitionCrossDissolve,
                        animations: {
                            window.rootViewController = MainTabBarController.make()
                        }
                    )
                }

            } catch {

                print("❌ No valid session found. Showing Login.")

                await MainActor.run {
                    UIView.transition(
                        with: window,
                        duration: 0.35,
                        options: .transitionCrossDissolve,
                        animations: {
                            window.rootViewController = UINavigationController(
                                rootViewController: LoginViewController()
                            )
                        }
                    )
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // MARK: - OAuth Handling
    // ---------------------------------------------------------------
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for ctx in URLContexts {
            handleIncomingURL(ctx.url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        Task { @MainActor in
            do {
                try await SupabaseManager.shared.handleAuthCallback(url)
            } catch {
                presentAuthError(error)
            }
        }
    }

    private func presentAuthError(_ error: Error) {
        guard let window = window,
              let root = window.rootViewController else { return }

        let alert = UIAlertController(
            title: "Authentication Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        root.present(alert, animated: true)
    }
}

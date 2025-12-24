// LoginViewController.swift
// UTSAV
//
// (Full file; password fields now have eye icons to toggle visibility — fixed so typing works.)

import UIKit
import AVFoundation
import AuthenticationServices

final class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Video playlist & UI (same as your original)
    private let videoNames = ["event2_bg", "event1_bg"]
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?

    private let heroView = UIView()
    private let heroDim = CAGradientLayer()
    private let bottomCover = UIView()
    private let brandLabel = UILabel()
    private let videoCenterGuide = UILayoutGuide()
    private let cardView = UIView()
    private let titleLabel = UILabel()

    // Replaced phoneRow with a form-style stack (email + password + confirmPassword)
    private let formStack = UIStackView()
    private let emailTextField = UITextField()

    // PASSWORD FIELDS (with eye buttons)
    private let passwordTextField = UITextField()
    private let confirmPasswordTextField = UITextField() // shown only in sign-up mode

    // Forgot password button (visible in log in mode)
    private let forgotPasswordButton = UIButton(type: .system)

    // keep countryButton for backwards compatibility in layout/state but hide it
    private let countryButton = UIButton(type: .system)

    private let continueButton = UIButton(type: .system)
    private let continueActivity = UIActivityIndicatorView(style: .medium)

    // NEW: signup toggle below the separator (placed above social buttons)
    private let signupToggleButton = UIButton(type: .system)

    private let sepRow = UIStackView()
    private let leftLine = UIView()
    private let orLabel = UILabel()
    private let rightLine = UIView()
    private let socialStack = UIStackView()
    private let googleButton = UIButton(type: .system)
    private let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    private let footerLabel = UILabel()

    // small activity indicator for Google button
    private let googleActivity = UIActivityIndicatorView(style: .medium)

    // layout
    private let corner: CGFloat = 28
    private let edge: CGFloat = 20
    private var fieldH: CGFloat = 50

    // state
    private var nextVideoIndex: Int = 0

    // NEW: signing up state — toggles the title and button text
    private var isSigningUp: Bool = false {
        didSet { updateForSignUpState() }
    }

    // keep strong ref to ASWebAuthenticationSession
    private var currentAuthSession: ASWebAuthenticationSession?

    // keyboard state
    private var keyboardIsVisible = false
    private var cardBottomConstraint: NSLayoutConstraint!

    // IMPORTANT: the scheme you registered in Info.plist URL Types
    // MUST match this value. (e.g. "utsav")
    private let callbackScheme = "utsav"
    private var appCallbackURLString: String { "\(callbackScheme)://callback" }

    // optional timeout work item (cancels session if takes too long)
    private var authTimeoutWorkItem: DispatchWorkItem?

    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        buildUI()
        layoutUI()
        styleUI()
        hookEvents()
        updateContinueEnabled(isValid: false)

        // set initial title based on sign-up state
        updateForSignUpState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startVideoPlaylist()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = heroView.bounds
        heroDim.frame = heroView.bounds
        heroView.bringSubviewToFront(brandLabel)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        authTimeoutWorkItem?.cancel()
    }

    // MARK: - UI builder
    private func buildUI() {
        [heroView, cardView, bottomCover].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(brandLabel)
        view.addLayoutGuide(videoCenterGuide)

        // include signupToggleButton in card's subviews
        [titleLabel, formStack, forgotPasswordButton, continueButton, sepRow, signupToggleButton, socialStack, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        // Form stack (vertical) for email + password + confirmPassword
        formStack.axis = .vertical
        formStack.spacing = 12
        formStack.alignment = .fill
        formStack.distribution = .fill
        formStack.addArrangedSubview(emailTextField)
        formStack.addArrangedSubview(passwordTextField)
        formStack.addArrangedSubview(confirmPasswordTextField)

        confirmPasswordTextField.isHidden = true

        // Keep country button but hidden (keeps previous layout code simple)
        countryButton.isHidden = true

        // Forgot password default hidden/shown handled by updateForSignUpState
        forgotPasswordButton.isHidden = false

        sepRow.axis = .horizontal
        sepRow.alignment = .center
        sepRow.spacing = 12
        sepRow.addArrangedSubview(leftLine)
        sepRow.addArrangedSubview(orLabel)
        sepRow.addArrangedSubview(rightLine)

        socialStack.axis = .vertical
        socialStack.alignment = .fill
        socialStack.distribution = .fill
        socialStack.spacing = 12
        socialStack.addArrangedSubview(googleButton)
        socialStack.addArrangedSubview(appleButton)

        // add activity indicator to google button
        googleActivity.translatesAutoresizingMaskIntoConstraints = false
        googleButton.addSubview(googleActivity)
        // center the spinner within googleButton
        NSLayoutConstraint.activate([
            googleActivity.centerYAnchor.constraint(equalTo: googleButton.centerYAnchor),
            googleActivity.trailingAnchor.constraint(equalTo: googleButton.trailingAnchor, constant: -16)
        ])

        // Add continue activity to continue button (spinner at trailing)
        continueActivity.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(continueActivity)
        NSLayoutConstraint.activate([
            continueActivity.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            continueActivity.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -16)
        ])
        continueActivity.hidesWhenStopped = true
    }

    private func layoutUI() {
        NSLayoutConstraint.activate([
            heroView.topAnchor.constraint(equalTo: view.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            videoCenterGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoCenterGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoCenterGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoCenterGuide.bottomAnchor.constraint(equalTo: cardView.topAnchor),

            brandLabel.centerXAnchor.constraint(equalTo: videoCenterGuide.centerXAnchor),
            brandLabel.centerYAnchor.constraint(equalTo: videoCenterGuide.centerYAnchor)
        ])

        // reduced card height so it doesn't cover most of the screen
        cardBottomConstraint = cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        cardBottomConstraint.isActive = true

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // smaller minimum height (was ~320/340) -> reduce to ~240 so background video remains visible
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),

            bottomCover.topAnchor.constraint(equalTo: cardView.bottomAnchor),
            bottomCover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCover.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            formStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            formStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            formStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            // forgot button sits under the form and aligned to right
            forgotPasswordButton.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            // keep a left anchor so it doesn't expand too wide on large screens
            forgotPasswordButton.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: edge),

            continueButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 8),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            continueButton.heightAnchor.constraint(equalToConstant: fieldH),

            sepRow.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 14),
            sepRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            sepRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            signupToggleButton.topAnchor.constraint(equalTo: sepRow.bottomAnchor, constant: 8),
            signupToggleButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            signupToggleButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            socialStack.topAnchor.constraint(equalTo: signupToggleButton.bottomAnchor, constant: 12),
            socialStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            socialStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),

            footerLabel.topAnchor.constraint(equalTo: socialStack.bottomAnchor, constant: 10),
            footerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            footerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            footerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])

        emailTextField.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
        confirmPasswordTextField.heightAnchor.constraint(equalToConstant: fieldH).isActive = true

        // keep forgot button modest height
        forgotPasswordButton.heightAnchor.constraint(equalToConstant: 28).isActive = true

        leftLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        rightLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        leftLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        orLabel.setContentHuggingPriority(.required, for: .horizontal)
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.translatesAutoresizingMaskIntoConstraints = false
        leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor).isActive = true
    }

    private func styleUI() {
        heroDim.colors = [UIColor.black.withAlphaComponent(0.35).cgColor, UIColor.clear.cgColor]
        heroDim.startPoint = CGPoint(x: 0.5, y: 0)
        heroDim.endPoint = CGPoint(x: 0.5, y: 1)
        heroView.layer.addSublayer(heroDim)

        brandLabel.text = "UTSΛV"
        brandLabel.textColor = .white
        brandLabel.font = .systemFont(ofSize: 44, weight: .bold)
        brandLabel.textAlignment = .center

        bottomCover.backgroundColor = .systemBackground
        bottomCover.isUserInteractionEnabled = false

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = corner
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: -2)

        // Set default title (updateForSignUpState will override)
        titleLabel.text = "Log in or sign up"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .label

        // primary purple color used across interactive items
        let primaryPurple = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)

        // countryButton kept but hidden
        var c = UIButton.Configuration.filled()
        c.title = "🇮🇳  +91 ▾"
        c.baseBackgroundColor = .secondarySystemBackground
        c.baseForegroundColor = .label
        c.cornerStyle = .large
        c.contentInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 12)
        countryButton.configuration = c
        countryButton.isHidden = true

        // EMAIL FIELD
        emailTextField.placeholder = "Email address"
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .username
        emailTextField.delegate = self
        emailTextField.backgroundColor = .secondarySystemBackground
        emailTextField.layer.cornerRadius = 12
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        emailTextField.leftViewMode = .always
        emailTextField.clearButtonMode = .whileEditing
        emailTextField.font = .systemFont(ofSize: 16)
        emailTextField.keyboardAppearance = .light
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .next

        // PASSWORD FIELD
        passwordTextField.placeholder = "Password (min 6 characters)"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.delegate = self
        passwordTextField.backgroundColor = .secondarySystemBackground
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        passwordTextField.leftViewMode = .always
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.font = .systemFont(ofSize: 16)
        passwordTextField.keyboardAppearance = .light
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.returnKeyType = .next

        // CONFIRM PASSWORD FIELD
        confirmPasswordTextField.placeholder = "Confirm password"
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.textContentType = .newPassword
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.backgroundColor = .secondarySystemBackground
        confirmPasswordTextField.layer.cornerRadius = 12
        confirmPasswordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        confirmPasswordTextField.leftViewMode = .always
        confirmPasswordTextField.clearButtonMode = .whileEditing
        confirmPasswordTextField.font = .systemFont(ofSize: 16)
        confirmPasswordTextField.keyboardAppearance = .light
        confirmPasswordTextField.autocapitalizationType = .none
        confirmPasswordTextField.autocorrectionType = .no
        confirmPasswordTextField.returnKeyType = .go
        confirmPasswordTextField.isHidden = true

        // --- REPLACED: add eye toggle buttons to password fields (safe, touch-friendly) ---
        addPasswordVisibilityToggle(to: passwordTextField, selector: #selector(togglePasswordVisibility(_:)))
        addPasswordVisibilityToggle(to: confirmPasswordTextField, selector: #selector(toggleConfirmPasswordVisibility(_:)))
        // ----------------------------------------------------------------

        var cont = UIButton.Configuration.filled()
        cont.title = "Continue"
        cont.baseBackgroundColor = primaryPurple
        cont.baseForegroundColor = .white
        cont.cornerStyle = .large
        cont.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
        continueButton.configuration = cont
        continueButton.layer.cornerRadius = 12
        continueButton.layer.masksToBounds = true

        // FORGOT PASSWORD BUTTON - align right and purple color to match primary
        forgotPasswordButton.setTitle("Forgot password?", for: .normal)
        forgotPasswordButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        forgotPasswordButton.contentHorizontalAlignment = .right
        forgotPasswordButton.setTitleColor(primaryPurple, for: .normal)
        forgotPasswordButton.setTitleColor(primaryPurple.withAlphaComponent(0.5), for: .disabled)

        // signup toggle (link-style) placed below the separator
        signupToggleButton.setTitle("Don't have an account? Sign up", for: .normal)
        signupToggleButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        signupToggleButton.contentHorizontalAlignment = .center
        // MATCH signup color to the forgot password primary purple
        signupToggleButton.setTitleColor(primaryPurple, for: .normal)
        signupToggleButton.setTitleColor(primaryPurple.withAlphaComponent(0.5), for: .disabled)

        leftLine.backgroundColor = .tertiaryLabel
        rightLine.backgroundColor = .tertiaryLabel
        orLabel.text = "or"
        orLabel.textColor = .secondaryLabel
        orLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        styleGoogleButton()

        appleButton.cornerRadius = 12
        appleButton.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
        appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)

        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 0
        footerLabel.font = .systemFont(ofSize: 12)
        footerLabel.textColor = .secondaryLabel
        footerLabel.text = "By continuing, you agree to our Terms of Service • Privacy Policy • Content Policies"
    }

    private func styleGoogleButton() {
        googleButton.configuration = nil
        googleButton.backgroundColor = .systemBackground
        googleButton.layer.cornerRadius = 12
        googleButton.layer.borderWidth = 1
        googleButton.layer.borderColor = UIColor.systemGray3.cgColor
        googleButton.heightAnchor.constraint(equalToConstant: fieldH).isActive = true

        googleButton.subviews.forEach { if $0 is UIStackView || $0 is UIImageView || $0 is UILabel { $0.removeFromSuperview() } }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let label = UILabel()
        label.text = "Sign in with Google"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        googleButton.addSubview(row)
        NSLayoutConstraint.activate([row.centerXAnchor.constraint(equalTo: googleButton.centerXAnchor),
                                     row.centerYAnchor.constraint(equalTo: googleButton.centerYAnchor)])

        // ensure activity indicator is visible to the right (already added in buildUI)
        googleActivity.hidesWhenStopped = true

        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
    }

    // MARK: - events
    private func hookEvents() {
        emailTextField.addTarget(self, action: #selector(credentialsChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(credentialsChanged), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(credentialsChanged), for: .editingChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        signupToggleButton.addTarget(self, action: #selector(toggleSignUpMode), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    @objc private func credentialsChanged() {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        if isSigningUp {
            let confirm = confirmPasswordTextField.text ?? ""
            updateContinueEnabled(isValid: validateEmail(email) && password.count >= 6 && confirm == password)
        } else {
            updateContinueEnabled(isValid: validateEmail(email) && password.count >= 6)
        }
    }

    private func updateContinueEnabled(isValid: Bool) {
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.6
    }

    // MARK: - Continue action (go to BusinessViewController without OTP)
    // Replace your existing continueTapped() with this:
    @objc private func continueTapped() {
        view.endEditing(true)
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard validateEmail(email) else {
            presentAuthErrorAlert("Invalid email", error: nil)
            return
        }
        guard password.count >= 6 else {
            presentAuthErrorAlert("Password must be at least 6 characters", error: nil)
            return
        }

        // Kick off async work inside a Task; UI updates are done on main queue (no await in @objc selector)
        setContinueInProgress(true)
        Task {
            do {
                if isSigningUp {
                    let confirm = confirmPasswordTextField.text ?? ""
                    guard confirm == password else {
                        // immediate UI revert on main thread
                        DispatchQueue.main.async {
                            self.setContinueInProgress(false)
                            self.presentAuthErrorAlert("Passwords do not match", error: nil)
                        }
                        return
                    }

                    // Call Supabase signUp (async)
                    let uid = try await SupabaseManager.shared.signUp(email: email, password: password, fullName: nil)
                    NSLog("Email sign-up success - uid: %@", uid)

                    // Back to main to update UI / navigate
                    DispatchQueue.main.async {
                        self.setContinueInProgress(false)
                        self.navigateToMainTabBar()

                    }
                } else {
                    // LOGIN flow - call Supabase signIn (async)
                    let uid = try await SupabaseManager.shared.signIn(email: email, password: password)
                    NSLog("Email sign-in success - uid: %@", uid)

                    DispatchQueue.main.async {
                        self.setContinueInProgress(false)
                        self.navigateToMainTabBar()

                    }
                }
            } catch {
                NSLog("Email auth error: %@", String(describing: error))
                DispatchQueue.main.async {
                    self.setContinueInProgress(false)
                    self.presentAuthErrorAlert("Authentication failed", error: error as? Error)
                }
            }
        }
    }
    // MARK: - Navigate to Main Dashboard (FINAL DESTINATION)
    private func navigateToMainTabBar() {
        let tabBar = MainTabBarController.make()

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {

            window.rootViewController = tabBar
            window.makeKeyAndVisible()

            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: nil
            )
        }
    }


    // helper to toggle continue spinner & disable UI
    // Replace your async setContinueInProgress(_:) with this synchronous helper:
    private func setContinueInProgress(_ inProgress: Bool) {
        DispatchQueue.main.async {
            self.continueButton.isEnabled = !inProgress
            if inProgress {
                self.continueActivity.startAnimating()
                self.continueButton.alpha = 0.7
            } else {
                self.continueActivity.stopAnimating()
                self.continueButton.alpha = 1.0
            }
        }
    }
    // MARK: - Forgot password
    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        // make sure the pushed VC has a title (back button will show previous VC title)
        vc.navigationItem.title = "Reset password"

        if let nav = navigationController {
            // ensure nav bar is visible, then push (Back button appears automatically)
            nav.setNavigationBarHidden(false, animated: true)
            nav.pushViewController(vc, animated: true)
        } else {
            // fallback: present inside nav so there is a nav bar and a close button
            let nav = UINavigationController(rootViewController: vc)
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissPresentedNav))
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    @objc private func dismissPresentedNav() {
        dismiss(animated: true)
    }


    // MARK: - Google Sign-in via Supabase + ASWebAuthenticationSession
    @objc private func googleTapped() {
        let callbackScheme = self.callbackScheme

        // Build the Supabase authorize URL (requesting PKCE/code flow)
        let authURL: URL
        do {
            // UPDATED CALL: manager now expects only providerName
            authURL = try SupabaseManager.shared.getOAuthSignInURL(providerName: "google")
        } catch {
            presentAuthErrorAlert("Failed to build auth URL", error: error)
            return
        }

        // Debugging: Print the URL the app will open.
        NSLog("==> Opening authURL: %@", authURL.absoluteString)

        // show spinner & disable UI to prevent double-tap
        setAuthInProgress(true)

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            guard let self = self else { return }

            // cancel timeout
            self.authTimeoutWorkItem?.cancel()
            self.authTimeoutWorkItem = nil

            // Always log completion for debugging
            NSLog("ASWebAuthenticationSession completion - callbackURL: %@", callbackURL?.absoluteString ?? "nil")
            if let err = error {
                NSLog("ASWebAuthenticationSession completion - error: %@", String(describing: err))
                DispatchQueue.main.async {
                    self.setAuthInProgress(false)
                    self.presentAuthErrorAlert("Google auth error", error: err)
                }
                return
            }

            guard let callbackURL = callbackURL else {
                DispatchQueue.main.async {
                    self.setAuthInProgress(false)
                    self.presentAuthErrorAlert("No callback URL returned", error: nil)
                }
                return
            }

            // Debug: what was returned before we hand it to SupabaseManager
            NSLog("ASWebAuth returned URL (raw): %@", callbackURL.absoluteString)

            Task {
                do {
                    try await SupabaseManager.shared.handleAuthCallback(callbackURL)
                    if let uid = await SupabaseManager.shared.getCurrentUserId() {
                        NSLog("Signed in user id: %@", uid)
                        DispatchQueue.main.async {
                            self.setAuthInProgress(false)
                            self.navigateToMainTabBar()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setAuthInProgress(false)
                            self.presentAuthErrorAlert("Sign-in succeeded but no user returned", error: nil)
                        }
                    }
                } catch {
                    NSLog("handleAuthCallback error: %@", String(describing: error))
                    DispatchQueue.main.async {
                        self.setAuthInProgress(false)
                        self.presentAuthErrorAlert("Failed to finish sign-in", error: error)
                    }
                }
            }
        }

        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        currentAuthSession = session

        // timeout work item
        let wi = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            NSLog("Auth timeout triggered - cancelling session")
            self.currentAuthSession?.cancel()
            self.currentAuthSession = nil
            DispatchQueue.main.async {
                self.setAuthInProgress(false)
                self.presentAuthErrorAlert("Authentication timed out", error: nil)
            }
        }
        authTimeoutWorkItem = wi
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: wi)

        let started = session.start()
        NSLog("ASWebAuthenticationSession started: %d", started ? 1 : 0)
    }

    // set UI state during auth
    private func setAuthInProgress(_ inProgress: Bool) {
        DispatchQueue.main.async {
            self.googleButton.isEnabled = !inProgress
            self.appleButton.isEnabled = !inProgress
            self.countryButton.isEnabled = !inProgress
            self.continueButton.isEnabled = !inProgress
            if inProgress {
                self.googleActivity.startAnimating()
            } else {
                self.googleActivity.stopAnimating()
            }
        }
    }

    // MARK: - Apple Sign-in (unchanged)
    @objc private func appleTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - helpers
    private func showAuthSuccess(provider: String, idTokenOrCode: String) {
        let alert = UIAlertController(title: "\(provider) sign-in", message: "Received code/token:\n\(idTokenOrCode)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentAuthErrorAlert(_ title: String = "Authentication Failed", error: Error?) {
        let msg: String
        if let err = error as NSError? {
            msg = "Code: \(err.code)\nDomain: \(err.domain)\n\(err.localizedDescription)"
        } else {
            msg = title
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }

    // MARK: - TextField delegate
    // Allow normal typing for email/password and handle return chain
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField && isSigningUp {
            confirmPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            continueTapped()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    // MARK: - Keyboard handling
    @objc private func keyboardWillShow(_ note: Notification) {
        guard !keyboardIsVisible, let info = note.userInfo else { return }
        keyboardIsVisible = true
        let kbFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let kbHeight = kbFrame.height - view.safeAreaInsets.bottom
        let dur = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
        cardBottomConstraint.constant = -kbHeight
        UIView.animate(withDuration: dur, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        guard keyboardIsVisible, let info = note.userInfo else { return }
        keyboardIsVisible = false
        let dur = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
        cardBottomConstraint.constant = 0
        UIView.animate(withDuration: dur, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func appBecameActive() { player?.play() }
    @objc private func appEnteredBackground() { player?.pause() }

    // MARK: - Called after successful sign-in
    private func onAuthSuccess(userId: String) {
        NSLog("onAuthSuccess -> user id: %@", userId)
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Signed in", message: "User id: \(userId)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                // navigate to dashboard if you have one.
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: - sign-up toggle handling
    @objc private func toggleSignUpMode() {
        isSigningUp.toggle()
    }

    private func updateForSignUpState() {
        DispatchQueue.main.async {
            if self.isSigningUp {
                self.titleLabel.text = "Sign up"
                self.signupToggleButton.setTitle("Already have an account? Log in", for: .normal)

                self.confirmPasswordTextField.isHidden = false
                self.forgotPasswordButton.isHidden = true

                // 🔥 CRITICAL FIX
                self.passwordTextField.textContentType = .newPassword
                self.confirmPasswordTextField.textContentType = .newPassword
                self.passwordTextField.passwordRules =
                    UITextInputPasswordRules(descriptor: "minlength: 6;")

            } else {
                self.titleLabel.text = "Log in"
                self.signupToggleButton.setTitle("Don't have an account? Sign up", for: .normal)

                self.confirmPasswordTextField.isHidden = true
                self.forgotPasswordButton.isHidden = false

                // 🔥 CRITICAL FIX
                self.passwordTextField.textContentType = .password
                self.confirmPasswordTextField.textContentType = nil
                self.passwordTextField.passwordRules = nil
            }

            self.passwordTextField.reloadInputViews()
            self.confirmPasswordTextField.reloadInputViews()

            if var cfg = self.continueButton.configuration {
                cfg.title = self.isSigningUp ? "Sign up" : "Continue"
                self.continueButton.configuration = cfg
            }

            self.credentialsChanged()
        }
    }


    // MARK: - email validation
    private func validateEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: email.utf16.count)
        return re?.firstMatch(in: email, options: [], range: range) != nil
    }

    // MARK: - Password visibility helpers (FIXED)
    // This implementation places a UIButton directly as the textField.rightView (no wrapper),
    // uses .custom button so it won't intercept typing, and preserves caret/selection.
    private func addPasswordVisibilityToggle(to field: UITextField, selector: Selector) {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 0, y: 0, width: 44, height: 30) // touch-friendly size
        btn.contentMode = .center
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "eye")?.withRenderingMode(.alwaysTemplate)
            btn.setImage(image, for: .normal)
        } else {
            btn.setTitle("Show", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        }
        btn.tintColor = .secondaryLabel
        btn.addTarget(self, action: selector, for: .touchUpInside)
        btn.accessibilityLabel = "Toggle password visibility"

        // assign directly as rightView (no container) — avoids touch-blocking layout issues
        field.rightView = btn
        field.rightViewMode = .always
        field.isUserInteractionEnabled = true
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        toggleSecureEntry(for: passwordTextField, button: sender)
    }

    @objc private func toggleConfirmPasswordVisibility(_ sender: UIButton) {
        toggleSecureEntry(for: confirmPasswordTextField, button: sender)
    }

    private func toggleSecureEntry(for field: UITextField, button: UIButton) {
        // Save current responder & selection
        let wasFirstResponder = field.isFirstResponder
        let selectedRange = field.selectedTextRange

        // Toggle secure text entry
        field.isSecureTextEntry.toggle()

        // Update button image/title
        if #available(iOS 13.0, *) {
            let name = field.isSecureTextEntry ? "eye" : "eye.slash"
            button.setImage(UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            button.setTitle(field.isSecureTextEntry ? "Show" : "Hide", for: .normal)
        }

        // Workaround to force refresh of secure entry display without losing text
        let current = field.text
        field.text = nil
        field.text = current

        // Restore first responder and selection (restore on next runloop for safety)
        if wasFirstResponder {
            field.becomeFirstResponder()
            DispatchQueue.main.async {
                field.selectedTextRange = selectedRange
            }
        } else {
            field.selectedTextRange = selectedRange
        }
    }
}

// MARK: - Video helpers (same as original)
private extension LoginViewController {
    var videoURLs: [URL] { videoNames.compactMap { Bundle.main.url(forResource: $0, withExtension: "mp4") } }

    func startVideoPlaylist() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let urls = videoURLs
        guard !urls.isEmpty else { return }
        if player != nil { player?.play(); return }
        nextVideoIndex = 1 % urls.count
        let firstItem = AVPlayerItem(url: urls[0])
        let q = AVQueuePlayer(items: [firstItem])
        q.isMuted = true
        let layer = AVPlayerLayer(player: q)
        layer.videoGravity = .resizeAspectFill
        layer.frame = heroView.bounds
        heroView.layer.insertSublayer(layer, at: 0)
        heroView.bringSubviewToFront(brandLabel)
        if heroView.layer.sublayers?.contains(where: { $0 === heroDim }) == false {
            heroView.layer.addSublayer(heroDim)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinish(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player = q
        playerLayer = layer
        q.play()
    }

    @objc func itemDidFinish(_ note: Notification) {
        guard let q = player else { return }
        let urls = videoURLs
        guard !urls.isEmpty else { return }
        let item = AVPlayerItem(url: urls[nextVideoIndex])
        nextVideoIndex = (nextVideoIndex + 1) % urls.count
        q.insert(item, after: nil)
    }
}

// MARK: - Presentation Context / Apple Auth delegate
extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                DispatchQueue.main.async { self.showAuthSuccess(provider: "Apple", idTokenOrCode: tokenString) }
            } else {
                DispatchQueue.main.async { self.showAuthSuccess(provider: "Apple", idTokenOrCode: "received-credentials") }
            }
        } else {
            presentAuthErrorAlert("Apple: unexpected credential", error: nil)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        presentAuthErrorAlert("Apple sign-in error", error: error as? Error)
    }
}

extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSLog("🔵 presentationAnchor called - returning window")
        guard let window = self.view.window else {
            NSLog("🔴 view.window is nil!")
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                NSLog("🟡 Using key window from connectedScenes")
                return window
            }
            NSLog("🔴 No window available!")
            return ASPresentationAnchor()
        }
        NSLog("🟢 Using self.view.window")
        return window
    }
}


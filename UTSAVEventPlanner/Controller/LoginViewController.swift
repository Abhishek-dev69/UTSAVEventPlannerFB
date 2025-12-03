//
// LoginViewController.swift
// UTSAV
//
// Full updated LoginViewController with improved Google OAuth UX & debug logging.
// Replace your existing LoginViewController.swift with this file.
//

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
    private let phoneRow = UIStackView()
    private let countryButton = UIButton(type: .system)
    private let phoneTextField = UITextField()
    private let continueButton = UIButton(type: .system)
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
    private let fieldH: CGFloat = 52

    // state
    private let requiredDigitsForIN = 10
    private var nextVideoIndex: Int = 0

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

    // MARK: - UI builder (same structure as before)
    private func buildUI() {
        [heroView, cardView, bottomCover].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(brandLabel)
        view.addLayoutGuide(videoCenterGuide)

        [titleLabel, phoneRow, continueButton, sepRow, socialStack, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        phoneRow.axis = .horizontal
        phoneRow.spacing = 12
        phoneRow.alignment = .fill
        phoneRow.distribution = .fill
        phoneRow.addArrangedSubview(countryButton)
        phoneRow.addArrangedSubview(phoneTextField)

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

        cardBottomConstraint = cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        cardBottomConstraint.isActive = true

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
            bottomCover.topAnchor.constraint(equalTo: cardView.bottomAnchor),
            bottomCover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            phoneRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            phoneRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            phoneRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            phoneRow.heightAnchor.constraint(equalToConstant: fieldH),
            countryButton.widthAnchor.constraint(equalToConstant: 110),
            continueButton.topAnchor.constraint(equalTo: phoneRow.bottomAnchor, constant: 14),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            continueButton.heightAnchor.constraint(equalToConstant: fieldH),
            sepRow.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 16),
            sepRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            sepRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            socialStack.topAnchor.constraint(equalTo: sepRow.bottomAnchor, constant: 12),
            socialStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            socialStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            footerLabel.topAnchor.constraint(equalTo: socialStack.bottomAnchor, constant: 10),
            footerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: edge),
            footerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -edge),
            footerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])

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

        titleLabel.text = "Log in or sign up"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        var c = UIButton.Configuration.filled()
        c.title = "🇮🇳  +91 ▾"
        c.baseBackgroundColor = .secondarySystemBackground
        c.baseForegroundColor = .label
        c.cornerStyle = .large
        c.contentInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 12)
        countryButton.configuration = c

        phoneTextField.placeholder = "Enter Mobile Number"
        phoneTextField.keyboardType = .numberPad
        phoneTextField.textContentType = .telephoneNumber
        phoneTextField.delegate = self
        phoneTextField.backgroundColor = .secondarySystemBackground
        phoneTextField.layer.cornerRadius = 14
        phoneTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        phoneTextField.leftViewMode = .always
        phoneTextField.clearButtonMode = .whileEditing
        phoneTextField.font = .systemFont(ofSize: 17)
        phoneTextField.keyboardAppearance = .light
        phoneTextField.inputAccessoryView = {
            let accessory = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 8))
            accessory.backgroundColor = .systemBackground
            return accessory
        }()

        var cont = UIButton.Configuration.filled()
        cont.title = "Continue"
        cont.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
        cont.baseForegroundColor = .white
        cont.cornerStyle = .large
        cont.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
        continueButton.configuration = cont
        continueButton.layer.cornerRadius = 14
        continueButton.layer.masksToBounds = true

        leftLine.backgroundColor = .tertiaryLabel
        rightLine.backgroundColor = .tertiaryLabel
        orLabel.text = "or"
        orLabel.textColor = .secondaryLabel
        orLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        styleGoogleButton()

        appleButton.cornerRadius = 14
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
        googleButton.layer.cornerRadius = 14
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
        icon.widthAnchor.constraint(equalToConstant: 32).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let label = UILabel()
        label.text = "Sign in with Google"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
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
        phoneTextField.addTarget(self, action: #selector(phoneChanged), for: .editingChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

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

    @objc private func phoneChanged() {
        let digits = phoneTextField.text?.filter(\.isNumber) ?? ""
        let limited = String(digits.prefix(requiredDigitsForIN))
        if limited != phoneTextField.text?.filter(\.isNumber) { phoneTextField.text = limited }
        updateContinueEnabled(isValid: limited.count == requiredDigitsForIN)
    }

    private func updateContinueEnabled(isValid: Bool) {
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.6
    }

    @objc private func continueTapped() {
        view.endEditing(true)
        let digits = phoneTextField.text?.filter(\.isNumber) ?? ""
        guard digits.count == requiredDigitsForIN else { return }
        let otpVC = OtpViewController(countryCode: "+91", phone: digits)
        navigationController?.pushViewController(otpVC, animated: true)
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
                            self.onAuthSuccess(userId: uid)
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
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) else { return false }
        let current = textField.text ?? ""
        if let r = Range(range, in: current) {
            let new = current.replacingCharacters(in: r, with: string)
            return new.filter(\.isNumber).count <= requiredDigitsForIN
        }
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

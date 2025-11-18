import UIKit
import AVFoundation
import AuthenticationServices

final class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Video playlist
    private let videoNames = ["event2_bg", "event1_bg"]      // add .mp4 in bundle
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?

    // MARK: - UI
    private let heroView = UIView()
    private let heroDim  = CAGradientLayer()
    private let bottomCover = UIView()
    private let brandLabel = UILabel()
    private let videoCenterGuide = UILayoutGuide()

    // card anchored directly (no scrollview) for predictable keyboard lifting
    private let cardView = UIView()

    private let titleLabel = UILabel()

    private let phoneRow = UIStackView()
    private let countryButton = UIButton(type: .system)
    private let phoneTextField = UITextField()

    private let continueButton = UIButton(type: .system)

    private let sepRow = UIStackView()
    private let leftLine = UIView()
    private let orLabel  = UILabel()
    private let rightLine = UIView()

    private let socialStack = UIStackView()
    private let googleButton = UIButton(type: .system)
    private let appleButton  = ASAuthorizationAppleIDButton(type: .signIn, style: .black)

    private let footerLabel = UILabel()

    // MARK: - Layout constants
    private let corner: CGFloat = 28
    private let edge: CGFloat = 20
    private let fieldH: CGFloat = 52
    private let maxCardWidth: CGFloat = 480

    // MARK: - State
    private let requiredDigitsForIN = 10
    private var nextVideoIndex: Int = 0

    // Keep reference to web auth session to keep it alive
    private var currentAuthSession: ASWebAuthenticationSession?

    // Keep keyboard state & card constraint
    private var keyboardIsVisible = false
    private var cardBottomConstraint: NSLayoutConstraint!

    // MARK: - Google OAuth placeholders — REPLACE with your values
    private let googleClientID = "GOOGLE_CLIENT_ID"     // <- replace
    private let googleRedirectURI = "YOUR_REDIRECT_URI" // <- replace
    private let googleScopes = "openid%20email%20profile" // URL-encoded scopes

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        buildUI()
        layoutUI()
        styleUI()
        hookEvents()
        updateContinueEnabled(isValid: false)

        // Ensure brand label is bold & on top when screen loads
        brandLabel.font = .systemFont(ofSize: 44, weight: .bold)
        brandLabel.layer.zPosition = 1000
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // start video once layout is stable
        startVideoPlaylist()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = heroView.bounds
        heroDim.frame      = heroView.bounds
        heroView.bringSubviewToFront(brandLabel)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Build UI
    private func buildUI() {
        // add hero first so it's behind everything
        [heroView, cardView, bottomCover].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
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
    }

    // MARK: - Layout
    private func layoutUI() {
        // heroView fills entire view so video plays behind everything (including card).
        NSLayoutConstraint.activate([
            heroView.topAnchor.constraint(equalTo: view.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            videoCenterGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoCenterGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoCenterGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoCenterGuide.bottomAnchor.constraint(equalTo: cardView.topAnchor)
        ])

        NSLayoutConstraint.activate([
            brandLabel.centerXAnchor.constraint(equalTo: videoCenterGuide.centerXAnchor),
            brandLabel.centerYAnchor.constraint(equalTo: videoCenterGuide.centerYAnchor)
        ])

        // Card anchored to safe area bottom — we'll store this constraint to animate with keyboard
        cardBottomConstraint = cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        cardBottomConstraint.isActive = true

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // minimum height so card displays content comfortably
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        // IMPORTANT: bottomCover's top is pinned to the card's bottom.
        // This makes bottomCover always cover the area underneath the card (so when the card moves up,
        // bottomCover follows and covers the area behind the keyboard).
        NSLayoutConstraint.activate([
            bottomCover.topAnchor.constraint(equalTo: cardView.bottomAnchor),
            bottomCover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCover.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // internal layout — Continue full width per your example
        NSLayoutConstraint.activate([
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

        // Separator / lines
        leftLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        rightLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        leftLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        orLabel.setContentHuggingPriority(.required, for: .horizontal)
        leftLine.translatesAutoresizingMaskIntoConstraints = false
        rightLine.translatesAutoresizingMaskIntoConstraints = false

        // important: make left and right lines equal width so "or" centers
        leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor).isActive = true
    }

    // MARK: - Style
    private func styleUI() {
        // Dim the top of the hero so status items are readable
        heroDim.colors = [UIColor.black.withAlphaComponent(0.35).cgColor, UIColor.clear.cgColor]
        heroDim.startPoint = CGPoint(x: 0.5, y: 0)
        heroDim.endPoint   = CGPoint(x: 0.5, y: 1)
        heroView.layer.addSublayer(heroDim)

        brandLabel.text = "UTSΛV"
        brandLabel.textColor = .white
        brandLabel.font = .systemFont(ofSize: 44, weight: .bold)
        brandLabel.textAlignment = .center
        brandLabel.numberOfLines = 1
        brandLabel.adjustsFontSizeToFitWidth = true
        brandLabel.minimumScaleFactor = 0.6

        // bottomCover must match card background so it hides the video region under the card/keyboard
        bottomCover.backgroundColor = .systemBackground
        bottomCover.isUserInteractionEnabled = false

        // Card: only top corners rounded, crisp iOS spacing
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = corner
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.layer.masksToBounds = false
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

        // Make system keyboard light (white keys/background)
        phoneTextField.keyboardAppearance = .light
        // Small white accessory view right above the keyboard to visually match the card
        let accessory = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 8))
        accessory.backgroundColor = .systemBackground
        phoneTextField.inputAccessoryView = accessory

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

        // Clean row content
        googleButton.subviews.forEach {
            if $0 is UIStackView || $0 is UIImageView || $0 is UILabel { $0.removeFromSuperview() }
        }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        // Slightly bigger Google icon to better match Apple button weight
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
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: googleButton.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: googleButton.centerYAnchor)
        ])
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
    }

    // MARK: - Events
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

        // Keyboard observers to animate card upward
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

    // MARK: - Google Sign In (ASWebAuthenticationSession OAuth2)
    @objc private func googleTapped() {
        // Build the authorization URL (replace placeholders with real values)
        guard let encodedRedirect = googleRedirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            presentAuthErrorAlert("Bad redirect URI", error: nil)
            return
        }
        let authURLString =
        "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(googleClientID)&response_type=code&scope=\(googleScopes)&redirect_uri=\(encodedRedirect)&prompt=select_account"
        guard let authURL = URL(string: authURLString) else {
            presentAuthErrorAlert("Bad authorization URL", error: nil)
            return
        }

        // ASWebAuthenticationSession requires the callback scheme (scheme portion of redirect URI)
        let callbackScheme = URL(string: googleRedirectURI)?.scheme

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            if let error = error {
                print("Google auth error: \(error.localizedDescription)")
                self?.presentAuthErrorAlert("Google auth error", error: error)
                return
            }
            guard let callbackURL = callbackURL else {
                self?.presentAuthErrorAlert("No callback URL returned", error: nil)
                return
            }
            // Example callback: com.example.app:/oauth2callback?code=AUTH_CODE&scope=...
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                // You have authorization code — exchange it on your server for tokens.
                print("Google auth code: \(code)")
                DispatchQueue.main.async {
                    self?.showAuthSuccess(provider: "Google", idTokenOrCode: code)
                }
            } else if let errorDesc = components?.queryItems?.first(where: { $0.name == "error" })?.value {
                print("Google auth error from callback: \(errorDesc)")
                self?.presentAuthErrorAlert("Google callback error: \(errorDesc)", error: nil)
            } else {
                print("Google callback received without code")
                self?.presentAuthErrorAlert("Google callback received without code", error: nil)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        currentAuthSession = session // keep strong reference
    }

    // MARK: - Apple Sign In
    @objc private func appleTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Helpers: UI feedback for debugging
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

    // MARK: - TextField delegate (unchanged)
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

    // MARK: - Keyboard handling (animate card)
    @objc private func keyboardWillShow(_ note: Notification) {
        guard !keyboardIsVisible, let info = note.userInfo else { return }
        keyboardIsVisible = true
        // get keyboard frame in view coordinates
        let kbFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let kbHeight = kbFrame.height - view.safeAreaInsets.bottom

        // animate card up by keyboard height
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

    // MARK: - App lifecycle helpers
    @objc private func appBecameActive()      { player?.play() }
    @objc private func appEnteredBackground() { player?.pause() }
}

// MARK: - Video (alternate two files forever; safe queueing)
private extension LoginViewController {
    var videoURLs: [URL] { videoNames.compactMap { Bundle.main.url(forResource: $0, withExtension: "mp4") } }

    func startVideoPlaylist() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let urls = videoURLs
        guard !urls.isEmpty else { return }

        // prevent multiple starts
        if player != nil { player?.play(); return }

        // Start with the first item and keep appending on finish
        nextVideoIndex = 1 % urls.count
        let firstItem = AVPlayerItem(url: urls[0])
        let q = AVQueuePlayer(items: [firstItem])
        q.isMuted = true

        let layer = AVPlayerLayer(player: q)
        layer.videoGravity = .resizeAspectFill
        layer.frame = heroView.bounds
        // insert video behind everything in heroView
        heroView.layer.insertSublayer(layer, at: 0)

        // keep brand label above video
        heroView.bringSubviewToFront(brandLabel)

        // add the same dim layer (ensure single add)
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

// MARK: - ASAuthorizationControllerDelegate & PresentationContextProviding (iOS 17+ signatures)
extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    // presentation anchor for Apple authorization
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    // NEW (iOS 17+) delegate method signature:
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                print("Apple identity token: \(tokenString.prefix(80))...") // truncated in log
                DispatchQueue.main.async {
                    self.showAuthSuccess(provider: "Apple", idTokenOrCode: tokenString)
                }
            } else {
                print("No identity token from Apple — possible first-time sign-in: returning basic info")
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                print("Apple user email: \(email ?? "nil"), name: \(fullName?.givenName ?? "nil")")
                DispatchQueue.main.async {
                    self.showAuthSuccess(provider: "Apple", idTokenOrCode: "received-credentials")
                }
            }
        } else {
            presentAuthErrorAlert("Apple: unexpected credential", error: nil)
        }
    }

    // NEW (iOS 17+) error signature using `any Error`
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: any Error) {
        print("Apple sign-in error: \(error)")
        // convert to Error for presenting details
        presentAuthErrorAlert("Apple sign-in error", error: error as? Error)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding for Google session
extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

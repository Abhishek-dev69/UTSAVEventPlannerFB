import UIKit

// MARK: - UTSAV Design System
struct UTSAVDesign {
    
    // Core Brand Color (Verified Purple)
    static let purple = UIColor(red: 136.0/255.0, green: 71.0/255.0, blue: 246.0/255.0, alpha: 1.0)
    
    // Aesthetic Secondary Tints
    static let lightPurple = purple.withAlphaComponent(0.08)
    static let midPurple   = purple.withAlphaComponent(0.30)
    
    // Card styling constants
    static let cardCornerRadius: CGFloat = 14
    static let cardAlpha: CGFloat = 0.85
}

// MARK: - UIViewController Gradient Extension
extension UIViewController {
    
    private struct AssociatedKeys {
        static var gradientLayer = "UTSAV_GradientLayer"
    }
    
    /// Applies the standard brand purple gradient to the background of the view.
    /// Inset at index 0 so it stays behind all other content.
    func applyBrandGradient() {
        // Remove existing if any to avoid duplication
        removeBrandGradient()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UTSAVDesign.midPurple.cgColor,
            UTSAVDesign.lightPurple.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0, 1.0]
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        view.backgroundColor = .systemBackground // Base color for safety
        
        // Store reference for resizing in viewDidLayoutSubviews if needed
        objc_setAssociatedObject(self, &AssociatedKeys.gradientLayer, gradientLayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func removeBrandGradient() {
        if let existing = objc_getAssociatedObject(self, &AssociatedKeys.gradientLayer) as? CAGradientLayer {
            existing.removeFromSuperlayer()
            objc_setAssociatedObject(self, &AssociatedKeys.gradientLayer, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Helper to update gradient frame when view bounds change (e.g., orientation or layout)
    func updateGradientFrame() {
        if let gradientLayer = objc_getAssociatedObject(self, &AssociatedKeys.gradientLayer) as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    /// Standardizes a transparent/glassy navbar appearance that lets the background gradient show through.
    func setupUTSAVNavbar(title: String, isTranslucent: Bool = true) {
        let appearance = UINavigationBarAppearance()
        if isTranslucent {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithOpaqueBackground()
        }
        
        // Dashboard style: Black titles and tints
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
        navigationItem.title = title
    }
    
    /// Global Primary Button Style (UTSAV Purple Gradient)
    func setupUTSAVPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        
        // Shadow for premium feel
        button.layer.shadowColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1).cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.masksToBounds = false
    }
}

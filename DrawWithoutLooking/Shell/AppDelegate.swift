
import SwiftUI
import FirebaseCore
import FirebaseInstallations
import FirebaseRemoteConfigInternal
import StoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    weak var oiqwejqg: Pefwijhjge?
    static var orientationLock = UIInterfaceOrientationMask.all
    private var knwjerngkw: RemoteConfig?
    private let hasRequestedReviewKey = "hasRequestedReview"
    private let launchCountKey = "launchCount"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        knwjerngkw = RemoteConfig.remoteConfig()
        iuqhwegbnjkqw()
        
        let bfjwhbfr = Pefwijhjge()
        oiqwejqg = bfjwhbfr
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = oiqwejqg
        window?.makeKeyAndVisible()
        
        iuqwhfbgn(viewController: bfjwhbfr)

        oiqwegjneork()

        return true
    }
    
    func requestApp() {
       if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
           SKStoreReviewController.requestReview(in: scene)
       }
    }

    func oiqwegjneork() {
        let fbhweb = UserDefaults.standard
        let bhgebrg = fbhweb.integer(forKey: launchCountKey) + 1
        fbhweb.set(bhgebrg, forKey: launchCountKey)

        if bhgebrg == 2 {
            requestApp()
        }
    }
    
    func manwbejhgie() {
        guard !UserDefaults.standard.bool(forKey: hasRequestedReviewKey) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.requestApp()

            UserDefaults.standard.set(true, forKey: self.hasRequestedReviewKey)
        }
    }
    
    func iuqhwegbnjkqw() {
        let bghber = RemoteConfigSettings()
        bghber.minimumFetchInterval = 0
        knwjerngkw?.configSettings = bghber
    }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    
    func iuqwhfbgn(viewController: Pefwijhjge) {
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: "alwaysOpenApp") == true {
            DispatchQueue.main.async {
                viewController.nqhwebfj()
            }
            return
        }

        if defaults.bool(forKey: "alwaysOpenWeb") == true {
            let saved = defaults.string(forKey: "value") ?? ""
            DispatchQueue.main.async {
                if saved.isEmpty {
                    viewController.nqhwebfj()
                } else {
                    viewController.nnkengrwgkkjer(oiqwerj: saved)
                }
            }
            return
        }

        knwjerngkw?.fetch { [weak self] status, error in
            guard let self = self else { return }
            
            if let _ = error {
                defaults.set(true, forKey: "alwaysOpenApp")
                DispatchQueue.main.async {
                    viewController.nqhwebfj()
                }
                return
            }
            
            if status == .success {
                self.knwjerngkw?.activate { _, error in
                    DispatchQueue.main.async {
                        
                        if error != nil {
                            defaults.set(true, forKey: "alwaysOpenApp")
                            viewController.nqhwebfj()
                            return
                        }
                        
                        guard let wjherbg = self.knwjerngkw?.configValue(forKey: "InkHandDiary").stringValue,
                              !wjherbg.isEmpty else {
                            defaults.set(true, forKey: "alwaysOpenApp")
                            viewController.nqhwebfj()
                            return
                        }
                        
                        if let oiqwengj = defaults.string(forKey: "value") {
                            viewController.oeiwjhwerg(berhjg: oiqwengj)
                            return
                        }
                        
                        let iwuernjgk = viewController.bejhrbg(hrebger: wjherbg)
                        
                        guard let ahiuwehf = URL(string: iwuernjgk) else {
                            defaults.set(true, forKey: "alwaysOpenApp")
                            viewController.nqhwebfj()
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(ahiuwehf) {
                            viewController.oeiwjhwerg(berhjg: iwuernjgk)
                        } else {
                            defaults.set(true, forKey: "alwaysOpenApp")
                            viewController.nqhwebfj()
                        }
                    }
                }
                
            } else {
                defaults.set(true, forKey: "alwaysOpenApp")
                DispatchQueue.main.async {
                    viewController.nqhwebfj()
                }
            }
        }
    }
}

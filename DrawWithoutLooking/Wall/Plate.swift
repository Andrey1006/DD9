
import Photos
import SwiftUI
import UIKit

struct Plate: View {
    let scrawl: Scrawl
    let strokes: [Stroke]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Rectangle().fill(Ink.void)
                ScrawlView(strokes: strokes, color: Ink.bone, weight: 3.4)
                    .padding(20)
            }
            .frame(width: 312, height: 312)
            .overlay(
                WobblyRect(radius: 10, seed: 771, amp: 1.7, step: 14)
                    .stroke(Ink.bone.opacity(0.32), lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(scrawl.word.uppercased())
                    .font(.slug(30)).tracking(-1.3).foregroundColor(Ink.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: 7) {
                    Placard(scrawl.pack.title, size: 9, color: scrawl.pack.stamp)
                    Placard("·", size: 9)
                    Placard("\(scrawl.seconds)s blind", size: 9)
                    Placard("·", size: 9)
                    Placard(DayKey.string(scrawl.bornAt), size: 9)
                }

                if let a = scrawl.artist {
                    Placard("by \(a)", size: 9, color: Ink.faded.opacity(0.8))
                }
            }
        }
        .padding(24)
        .frame(width: 360, alignment: .leading)
        .background(Ink.base)
        .overlay(
            Image(uiImage: Grain.tile)
                .resizable(resizingMode: .tile)
                .blendMode(.overlay)
                .opacity(0.09)
                .allowsHitTesting(false)
        )
    }
}

struct Printed: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityBoard: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

enum Printer {
    @MainActor
    static func render(_ s: Scrawl, strokes: [Stroke]) -> UIImage? {
        let renderer = ImageRenderer(content: Plate(scrawl: s, strokes: strokes))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }

    static func file(_ image: UIImage, named: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        let slug = named.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let stem = slug.isEmpty ? "scrawl" : slug
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(stem)-\(UUID().uuidString.prefix(4)).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func stash(_ image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return false }
        return await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { ok, _ in
                cont.resume(returning: ok)
            }
        }
    }
}

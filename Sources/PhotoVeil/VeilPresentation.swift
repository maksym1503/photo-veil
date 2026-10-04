import SwiftUI

// Public links live here. Leave unset until the owner supplies real destinations.
enum VeilPublicLinks {
    static let privacyPolicy: URL? = nil
    static let terms: URL? = nil
    static let support: URL? = nil
}

struct VeilActionStyle: ViewModifier {
    var prominent = false
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if prominent { content.buttonStyle(.glassProminent) }
            else { content.buttonStyle(.glass) }
        } else {
            if prominent { content.buttonStyle(.borderedProminent).buttonBorderShape(.capsule) }
            else { content.buttonStyle(.bordered).buttonBorderShape(.capsule) }
        }
    }
}

struct VeilGlassSurface: ViewModifier {
    var panel = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: panel ? 28 : 1000))
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: panel ? 28 : 1000))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: panel ? 28 : 1000))
        }
    }
}

struct VeilModePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 1.045 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// A code-native photographic illustration: no stock photo, network or generated asset.
struct VeilDemonstration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var concealed = false
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    LinearGradient(colors: [Color(red: 0.35, green: 0.53, blue: 0.60), Color(red: 0.76, green: 0.79, blue: 0.69)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(.white.opacity(0.6)).frame(width: 70).position(x: size.width * 0.78, y: size.height * 0.22)
                    Ellipse().fill(Color(red: 0.24, green: 0.40, blue: 0.41)).frame(width: size.width * 1.5, height: size.height * 0.6).position(x: size.width * 0.3, y: size.height * 0.85)
                    Ellipse().fill(Color(red: 0.16, green: 0.29, blue: 0.32)).frame(width: size.width * 1.4, height: size.height * 0.5).position(x: size.width * 0.9, y: size.height)
                    RoundedRectangle(cornerRadius: 50).fill(Color(red: 0.17, green: 0.23, blue: 0.27)).frame(width: size.width * 0.42, height: size.height * 0.60).position(x: size.width * 0.48, y: size.height * 0.91)
                    ZStack {
                        Capsule().fill(Color(red: 0.82, green: 0.65, blue: 0.51))
                        VStack(spacing: 15) {
                            HStack(spacing: 22) { Circle().frame(width: 5); Circle().frame(width: 5) }
                            Capsule().frame(width: 18, height: 3)
                        }.foregroundStyle(Color(red: 0.27, green: 0.21, blue: 0.18))
                    }
                    .frame(width: size.width * 0.23, height: size.height * 0.32)
                    .blur(radius: concealed || reduceMotion ? 13 : 0)
                    .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.75), lineWidth: 1) }
                    .position(x: size.width * 0.48, y: size.height * 0.47)
                }
            }
            Label("Private details, veiled", systemImage: "eye.slash")
                .font(.caption.weight(.medium)).foregroundStyle(.white)
                .padding(12).background(.black.opacity(0.45), in: Capsule()).padding(16)
        }
        .aspectRatio(1.12, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Illustration of a portrait with its face blurred")
        .task(id: reduceMotion) {
            concealed = reduceMotion
            guard !reduceMotion else { return }
            do {
                try await Task.sleep(for: .seconds(1.2))
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 2.2)) { concealed = true }
                    // Finish the transition, then hold the result briefly.
                    try await Task.sleep(for: .seconds(3.6))
                    withAnimation(.easeInOut(duration: 2.2)) { concealed = false }
                    try await Task.sleep(for: .seconds(3.6))
                }
            } catch {
                // Leaving the landing screen or changing Reduce Motion cancels the loop.
            }
        }
    }
}

struct VeilSettings: View {
    @Environment(\.dismiss) private var dismiss
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "—") (\(info["CFBundleVersion"] as? String ?? "—"))"
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Veil") {
                    NavigationLink("About Veil") {
                        VeilInformation(title: "About Veil", symbol: "photo", paragraphs: ["Share the moment. Keep the details.", "Veil helps you blur backgrounds, faces, plates and areas you select before sharing a photo. No account needed."])
                    }
                    LabeledContent("Version / Build", value: version)
                }
                Section("Privacy") {
                    NavigationLink("How Veil handles photos") { photoPrivacy }
                        .accessibilityIdentifier("photoPrivacy")
                    if let url = VeilPublicLinks.privacyPolicy { Link("Privacy Policy", destination: url) }
                    if let url = VeilPublicLinks.terms { Link("Terms of Use", destination: url) }
                }
                Section("Support") {
                    NavigationLink("Help / Support") {
                        VeilInformation(title: "Help / Support", symbol: "questionmark.circle", paragraphs: ["Choose a photo, then select Background, Faces, Plates or Manual. Faces and Plates blur detected regions immediately; tap a region to toggle it.", "In Manual, switch between rectangle and brush. Use two fingers to zoom; switch to Move photo to pan. Undo reverses your last edit.", "Choose Done to review, then Export to open the share sheet. Always check the whole photo: automatic detection can miss details, and blur does not guarantee anonymity."])
                    }
                    if let url = VeilPublicLinks.support { Link("Contact Support", destination: url) }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
    private var photoPrivacy: some View {
        VeilInformation(title: "Your photos", symbol: "iphone", paragraphs: ["Photo processing happens entirely on this iPhone. Photos are not uploaded to Veil servers.", "Veil receives only the photo you choose through the system picker. It has no account, analytics, advertising or tracking.", "Edits stay in memory while the photo is open. Export creates a new JPEG in temporary storage and opens the system share sheet. Your original is unchanged. Exported images omit the original photo’s metadata.", "You choose where to share the result. The receiving app or service handles that copy under its own privacy policy."])
    }
}

private struct VeilInformation: View {
    let title: String
    let symbol: String
    let paragraphs: [String]
    var body: some View {
        List {
            Section {
                Label(title, systemImage: symbol).font(.title2.weight(.semibold)).padding(.vertical, 8)
                ForEach(paragraphs, id: \.self) { Text($0).padding(.vertical, 4) }
            }
        }.navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

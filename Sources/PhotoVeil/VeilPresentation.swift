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
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .overlay {
            LinearGradient(stops: [
                .init(color: Color(uiColor: .systemBackground), location: 0),
                .init(color: .clear, location: 0.22),
                .init(color: .clear, location: 0.58),
                .init(color: Color(uiColor: .systemBackground), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Portrait privacy demonstration")
        .accessibilityValue(reduceMotion ? "Static blurred portrait" : concealed ? "Blurred portrait" : "Clear portrait")
        .accessibilityIdentifier("privacyDemonstration")
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
    @EnvironmentObject private var library: VeilLibrary
    @EnvironmentObject private var account: VeilAccount
    @State private var deletesHistory = false
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
                Section("Private Gallery") {
                    LabeledContent("Photos on this iPhone", value: "\(library.items.count)")
                    LabeledContent("Storage used", value: ByteCountFormatter.string(fromByteCount: Int64(library.items.reduce(0) { $0 + $1.byteCount }), countStyle: .file))
                    Button("Delete local history", role: .destructive) { deletesHistory = true }.disabled(library.items.isEmpty)
                }
                Section("Account & Sync") {
                    NavigationLink(account.identity == nil ? "Account" : "Account & Sync") { VeilAccountView() }.accessibilityIdentifier("account")
                    Text(account.syncEnabled ? account.syncStatus : "Cloud sync is off").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    NavigationLink("How Veil handles photos") { photoPrivacy }
                        .accessibilityIdentifier("photoPrivacy")
                    if let url = VeilPublicLinks.privacyPolicy { Link("Privacy Policy", destination: url) }
                    if let url = VeilPublicLinks.terms { Link("Terms of Use", destination: url) }
                }
                Section("Support") {
                    NavigationLink("Help / Support") {
                        VeilInformation(title: "Help / Support", symbol: "questionmark.circle", paragraphs: ["Choose a photo, then select Background, Faces, Plates or Manual. Faces and Plates blur detected regions immediately; tap a region to toggle it.", "In Manual, choose rectangle, ellipse or brush. Choose Blur, Pixelate or Redact for your selection. Use two fingers to zoom; switch to Move photo to pan. Undo reverses your last edit.", "Choose Done to review, then Share, Save to Veil or Save to Photos. Documents proposes text regions; hiding the entire document offers broader coverage. Always check the whole photo: automatic detection can miss details, and blur does not guarantee anonymity."])
                    }
                    if let url = VeilPublicLinks.support { Link("Contact Support", destination: url) }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.task { await library.reload() }
        .confirmationDialog("Delete local history? Cloud copies stay in your account and may download again if sync is enabled.", isPresented: $deletesHistory, titleVisibility: .visible) {
            Button("Delete local history", role: .destructive) {
                Task { await account.setSync(false); await library.delete(Set(library.items.map(\.id)), localOnly: true) }
            }
        }
    }
    private var photoPrivacy: some View {
        VeilInformation(title: "Your photos", symbol: "iphone", paragraphs: ["Photo processing happens on this iPhone. The system picker shares only photos you select; Save to Photos asks only to add your chosen output.", "Original photos and recognized text are never uploaded. Save to Veil stores processed outputs and thumbnails in protected local files, excluded from device backups. Removing the app removes local history.", "Accounts are optional. Only when you enable cloud sync do processed gallery images, thumbnails and edit metadata upload to private account storage. Authentication providers and the cloud operator also process account information. This is not end-to-end encryption.", "Signing out keeps local history. Account deletion removes your account and cloud gallery; local history is a separate Settings action. Provider/cloud backup retention needs the published policy.", "Share creates a temporary processed JPEG, cleaned up after sharing or on the next launch. Your original is unchanged; source EXIF/GPS metadata is not copied. Receiving apps handle shared copies under their own policies. No analytics or tracking is added."])
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

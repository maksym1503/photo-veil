import SwiftUI

// Public links live here. Leave unset until the owner supplies real destinations.
enum VeilPublicLinks {
    static let privacyPolicy = publishedURL("VeilPrivacyPolicyURL")
    static let terms: URL? = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    static let support = publishedURL("VeilSupportURL")
    // Build-time public destinations only. Never substitute a draft or a development URL.
    private static func publishedURL(_ key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value), ContextualAdvertisingConfiguration.isApprovedHTTPSURL(url) else { return nil }
        return url
    }
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
    @State private var stage = 0
    private var concealed: Bool { stage > 0 || reduceMotion }
    private var demonstrationValue: String {
        if reduceMotion { return "Privacy tools preview" }
        return concealed ? "Visual privacy" : "Original preview"
    }
    @State private var userControlled = false
    var body: some View {
        GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    RadialGradient(colors: [Color.cyan.opacity(0.38), Color.indigo.opacity(0.18), .clear],
                                   center: .center, startRadius: 8, endRadius: size.width * 0.66)
                    ZStack {
                        LinearGradient(colors: [Color(red: 0.14, green: 0.40, blue: 0.55), Color(red: 0.62, green: 0.79, blue: 0.76)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Ellipse().fill(Color(red: 0.16, green: 0.43, blue: 0.42))
                            .frame(width: size.width, height: size.height * 0.48)
                            .offset(x: -size.width * 0.18, y: size.height * 0.34)
                        Ellipse().fill(Color(red: 0.10, green: 0.25, blue: 0.30))
                            .frame(width: size.width, height: size.height * 0.40)
                            .offset(x: size.width * 0.25, y: size.height * 0.40)
                        RoundedRectangle(cornerRadius: 65)
                            .fill(LinearGradient(colors: [Color(red: 0.14, green: 0.22, blue: 0.38), Color(red: 0.28, green: 0.40, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: size.width * 0.45, height: size.height * 0.55)
                            .offset(y: size.height * 0.35)
                        VeilPortrait().frame(width: size.width * 0.24, height: size.height * 0.34)
                            .blur(radius: concealed ? 14 : 0)
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.cyan.opacity(concealed ? 0.12 : 0))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 24).strokeBorder(
                                            LinearGradient(colors: [.white.opacity(0.85), .cyan.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: concealed ? 2 : 0)
                                    }
                                    .shadow(color: .cyan.opacity(concealed ? 0.65 : 0), radius: 14)
                                    .padding(-8)
                            }.offset(x: -size.width * 0.04, y: size.height * 0.01)
                    }.frame(width: size.width * 0.78, height: size.height * 0.76)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.25), lineWidth: 1) }
                        .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 16)
                        .rotationEffect(.degrees(concealed ? -3 : -7))
                        .rotation3DEffect(.degrees(concealed ? 0 : 5), axis: (x: 0, y: 1, z: 0))
                        .position(x: size.width * 0.46, y: size.height * 0.52)
                    VeilLocationIllustration(removed: concealed)
                        .frame(width: size.width * 0.39, height: size.height * 0.31)
                        .rotationEffect(.degrees(concealed ? 4 : 9))
                        .offset(y: concealed ? -4 : 0)
                        .position(x: size.width * 0.76, y: size.height * 0.25)
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
        .accessibilityLabel("Veil privacy tools demonstration")
        .accessibilityValue(demonstrationValue)
        .accessibilityHint(reduceMotion ? "A static example of redaction and metadata control." : "Double-tap to preview blur and location removal together. This does not change your photo.")
        .accessibilityIdentifier("privacyDemonstration")
        .accessibilityAction(named: Text("Toggle privacy preview")) { toggleDemonstration() }
        .contentShape(Rectangle())
        .onTapGesture { toggleDemonstration() }
        .task(id: reduceMotion) {
            userControlled = false
            stage = reduceMotion ? 1 : 0
            guard !reduceMotion else { return }
            do {
                try await Task.sleep(for: .seconds(0.9))
                while !Task.isCancelled && !userControlled {
                    withAnimation(.easeInOut(duration: 0.7)) { stage = 1 - stage }
                    try await Task.sleep(for: .seconds(2.2))
                }
            } catch { /* Leaving the scene cancels presentation animation. */ }
        }
    }

    private func toggleDemonstration() {
        guard !reduceMotion else { return }
        userControlled = true
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.4)) { stage = 1 - stage }
    }
}

/// A generic map fragment: no device location, coordinates or personal image data.
private struct VeilLocationIllustration: View {
    let removed: Bool
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(
                    LinearGradient(colors: [Color(red: 0.10, green: 0.25, blue: 0.39), Color(red: 0.10, green: 0.42, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Canvas { context, size in
                    var streets = Path()
                    streets.move(to: CGPoint(x: 0, y: size.height * 0.15)); streets.addLine(to: CGPoint(x: size.width, y: size.height * 0.8))
                    streets.move(to: CGPoint(x: size.width * 0.2, y: 0)); streets.addLine(to: CGPoint(x: size.width * 0.65, y: size.height))
                    streets.move(to: CGPoint(x: 0, y: size.height * 0.8)); streets.addLine(to: CGPoint(x: size.width, y: size.height * 0.3))
                    context.stroke(streets, with: .color(.white.opacity(0.3)), lineWidth: 4)
                }.clipShape(RoundedRectangle(cornerRadius: 18)).opacity(removed ? 0.25 : 1)
                Image(systemName: removed ? "location.slash.fill" : "mappin.and.ellipse")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(removed ? Color.cyan : Color(red: 1, green: 0.76, blue: 0.42))
                    .shadow(color: (removed ? Color.cyan : Color.orange).opacity(0.6), radius: 10)
                    .contentTransition(.opacity)
            }.overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.3), lineWidth: 1) }
                .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
            Text(removed ? "Location removed" : "Location attached")
                .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                .transaction { $0.animation = nil }
                .lineLimit(1).minimumScaleFactor(0.85)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule())
        }.accessibilityHidden(true)
    }
}

/// Sculpted portrait details are decorative; they never use a personal photograph.
private struct VeilPortrait: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            ZStack {
                // Neck and ears establish a natural silhouette instead of a floating capsule.
                Capsule().fill(Color(red: 0.67, green: 0.43, blue: 0.32))
                    .frame(width: w * 0.38, height: h * 0.38).position(x: w * 0.5, y: h * 0.94)
                Ellipse().fill(Color(red: 0.77, green: 0.54, blue: 0.40))
                    .frame(width: w * 0.20, height: h * 0.26).position(x: w * 0.12, y: h * 0.56)
                Ellipse().fill(Color(red: 0.71, green: 0.47, blue: 0.35))
                    .frame(width: w * 0.18, height: h * 0.25).position(x: w * 0.88, y: h * 0.56)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: h * 0.33))
                    path.addCurve(to: CGPoint(x: w * 0.85, y: h * 0.33), control1: CGPoint(x: w * 0.13, y: 0), control2: CGPoint(x: w * 0.87, y: 0))
                    path.addCurve(to: CGPoint(x: w * 0.51, y: h * 0.93), control1: CGPoint(x: w * 0.91, y: h * 0.74), control2: CGPoint(x: w * 0.72, y: h * 0.91))
                    path.addCurve(to: CGPoint(x: w * 0.15, y: h * 0.33), control1: CGPoint(x: w * 0.26, y: h * 0.91), control2: CGPoint(x: w * 0.10, y: h * 0.70))
                }.fill(LinearGradient(colors: [Color(red: 0.94, green: 0.76, blue: 0.60), Color(red: 0.76, green: 0.51, blue: 0.39)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.14, y: h * 0.49))
                    path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.23), control1: CGPoint(x: w * 0.14, y: h * 0.20), control2: CGPoint(x: w * 0.57, y: h * 0.31))
                    path.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.53), control1: CGPoint(x: w * 0.85, y: h * 0.33), control2: CGPoint(x: w * 0.80, y: h * 0.43))
                    path.addCurve(to: CGPoint(x: w * 0.07, y: h * 0.35), control1: CGPoint(x: w * 1.07, y: -h * 0.13), control2: CGPoint(x: -w * 0.12, y: -h * 0.12))
                    path.closeSubpath()
                }.fill(LinearGradient(colors: [Color(red: 0.26, green: 0.22, blue: 0.22), Color(red: 0.12, green: 0.13, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                // Restrained asymmetric features read as a portrait at small sizes.
                Path { path in
                    path.move(to: CGPoint(x: w * 0.25, y: h * 0.46))
                    path.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * 0.45), control: CGPoint(x: w * 0.31, y: h * 0.42))
                    path.move(to: CGPoint(x: w * 0.60, y: h * 0.45))
                    path.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.46), control: CGPoint(x: w * 0.68, y: h * 0.42))
                }.stroke(Color(red: 0.29, green: 0.21, blue: 0.20), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                HStack(spacing: w * 0.27) {
                    Ellipse().frame(width: w * 0.065, height: h * 0.028)
                    Ellipse().frame(width: w * 0.065, height: h * 0.028)
                }.foregroundStyle(Color(red: 0.21, green: 0.20, blue: 0.22)).position(x: w * 0.5, y: h * 0.52)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.51, y: h * 0.53))
                    path.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.67), control: CGPoint(x: w * 0.50, y: h * 0.63))
                    path.addQuadCurve(to: CGPoint(x: w * 0.47, y: h * 0.68), control: CGPoint(x: w * 0.50, y: h * 0.70))
                }.stroke(Color(red: 0.60, green: 0.37, blue: 0.29).opacity(0.55), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.38, y: h * 0.76))
                    path.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.75), control: CGPoint(x: w * 0.51, y: h * 0.80))
                }.stroke(Color(red: 0.51, green: 0.28, blue: 0.26), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
        }
    }
}

struct VeilSettings: View {
    @EnvironmentObject private var library: VeilLibrary
    @EnvironmentObject private var account: VeilAccount
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    @State private var deletesHistory = false
    @State private var localDeleteError: String?
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
        VeilInformation(title: "About Veil", symbol: "photo", paragraphs: ["Your photo. Your boundaries.", "Veil prepares photos for safer sharing with three tools: blur and redaction, metadata control, and text watermarks. Cover visible details, choose which hidden photo details travel, and give your copy a purpose.", "Detection and editing happen on your iPhone. Your original stays unchanged, and recognized text is not stored or uploaded. You decide what to keep and what to share.", "Add a custom watermark or start with a privacy-minded suggestion. Drag it into place, choose a style, or repeat it across the photo. Choose whether to keep or remove source metadata in the Metadata tool. After Done, review your edits and choice, then save or share a new copy. Save favorites to your Private Gallery. No account is needed for local editing; cloud sync is a separate, optional choice."])
                    }
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
                if subscriptions.isConfigured {
                    Section {
                        NavigationLink("Veil Pro") { VeilSubscriptionView() }
                    }
                }
                Section("Privacy") {
                    NavigationLink("How Veil handles photos") { photoPrivacy }
                        .accessibilityIdentifier("photoPrivacy")
                    if let url = VeilPublicLinks.privacyPolicy { Link("Privacy Policy", destination: url) }
                    if let url = VeilPublicLinks.terms { Link("Terms of Use", destination: url) }
                }
                Section("Support") {
                    NavigationLink("Help / Support") {
                        VeilHelpInformation()
                    }
                    if let url = VeilPublicLinks.support { Link("Contact Support", destination: url) }
                    Text("Version \(version)").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.task { await library.reload() }
        .confirmationDialog("Delete local history? Cloud copies stay in your account and may download again if sync is enabled.", isPresented: $deletesHistory, titleVisibility: .visible) {
            Button("Delete local history", role: .destructive) {
                Task {
                    guard await account.setSync(false) else {
                        localDeleteError = account.message ?? "Cloud sync could not be stopped. Local history was left unchanged."
                        return
                    }
                    guard await library.delete(Set(library.items.map(\.id)), localOnly: true) else {
                        localDeleteError = library.message ?? "Local history could not be deleted. Try again after unlocking this iPhone."
                        return
                    }
                }
            }
        }
        .alert("Local history", isPresented: Binding(get: { localDeleteError != nil }, set: { if !$0 { localDeleteError = nil } })) {
            Button("OK") { localDeleteError = nil }
        } message: { Text(localDeleteError ?? "") }
    }
    private var photoPrivacy: some View {
        VeilInformation(title: "Your photos", symbol: "iphone", paragraphs: ["Photo processing happens on this iPhone. The system photo picker gives Veil access to the photo you select. Save to Photos requests add-only access when you choose that action.", "Original photos and recognized text are never uploaded. Recognized text is used only during detection and is not saved. Veil adds no analytics or tracking. Save to Veil keeps processed outputs and thumbnails in protected local files that are excluded from device backups. Removing the app removes this local history.", "Watermark text stays in the current editing session, including Undo, until you close or replace the photo. It is not saved as a reusable template or sent to a service. Saving or sharing deliberately embeds that visible text in the processed image and its thumbnails; optional cloud sync carries those finished copies. Avoid putting sensitive information in a watermark. A visible mark is a usage cue, not proof of authenticity or protection against removal.", "Choose Remove metadata or Keep metadata in the Metadata tool. Done reviews that choice before saving or sharing. Remove omits source location, capture date, camera/device details, descriptive metadata, comments and embedded previews. Keep preserves supported source metadata, including location when available. Your original stays unchanged; Photos or receiving apps may add their own dates or identifiers.", "The saved choice applies to Photos, Share, gallery exports and future cloud sync, including thumbnails. Keep cannot preserve every tag: JPEG conversion rebuilds orientation, dimensions and color information, and excludes original previews, auxiliary images, opaque application data and unsupported comments. Metadata already removed from older copies cannot be recovered. Older gallery entries use Remove; existing files and previously delivered copies are not rewritten. Gallery/cloud records retain operational dates and IDs.", "Accounts are optional. If you turn on cloud sync, processed gallery images, thumbnails and edit metadata are stored in your account's private cloud storage. Authentication providers and the cloud operator also process account information. Cloud storage is not end-to-end encrypted.", "Turning sync off stops future synchronization; copies already uploaded remain in your account. Signing out keeps local history. Account deletion removes your account and cloud gallery; delete local history separately in Settings. Cloud providers may retain backups under their own retention policies.", "Apple handles subscription payments. Veil checks verified Apple entitlements for Pro access. A device-only Keychain record stores the free allowance and successful export count without photo or account identifiers. New installations receive one free export; previously recorded allowances are preserved. The count is not synchronized and may survive app deletion; reinstall survival is not guaranteed. Deleting gallery photos does not reset it. No purchase data is uploaded to a Veil billing server.", "Sharing creates a temporary processed JPEG that Veil removes after sharing or on the next launch. The original photo remains unchanged. Receiving apps handle shared copies under their own policies."])
    }
}

private struct VeilInformation: View {
    let title: String
    let symbol: String
    let paragraphs: [String]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .accessibilityHidden(true)
                Text(title).font(.largeTitle.weight(.semibold)).accessibilityAddTraits(.isHeader)
                ForEach(paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(title == "About Veil" && paragraph == paragraphs.first ? .title3.weight(.medium) : .body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct VeilHelpInformation: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("Help / Support", systemImage: "questionmark.circle")
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Before you share").font(.headline)
                    Text("Choose Done to review the whole image. Detection can miss details. For sensitive text, use solid Redact and consider covering the whole document. Blur and pixelation do not guarantee anonymity.")
                        .font(.body)
                        .lineSpacing(4)
                }

                Divider()

                VStack(alignment: .leading, spacing: 0) {
                    helpDisclosure("How do I edit a photo?", answer: "Choose a photo, then use Redact, Metadata or Watermark. In Redact, choose Background, Faces, Plates, Documents or Manual. Veil suggests areas to cover for automatic tools; review the suggestions and tap a region to change its selection. In Manual, draw a rectangle, ellipse or brush stroke, then choose Blur, Pixelate or Redact. Use two fingers to zoom and pan, or switch to Move photo. Undo reverses your last edit. After review, Share, Save to Veil or Save to Photos.")
                    Divider()
                    helpDisclosure("How do watermarks work?", answer: "Open Watermark and choose Add watermark. Edit the text or use a suggestion, then drag on the photo to position it. Choose Light, Dark or Stamp, repeat the mark, or adjust size, opacity and rotation. Placement presets and VoiceOver actions are available. Undo reverses watermark edits independently of redaction. Saved and shared copies include the visible mark, regardless of the metadata choice. Text is kept only in the editing session; no reusable template or cloud text field is created. A watermark can be cropped or removed and cannot guarantee how someone uses a photo.")
                    helpDisclosure("Does Veil remove photo metadata?", answer: "Choose Remove metadata or Keep metadata in the Metadata tool. After Done, review your choice and save or share. Tap the metadata summary to change it. Remove omits source location, capture date, camera/device details, descriptive metadata, comments and embedded previews. Keep preserves supported details, including location when available; JPEG cannot keep every tag, original preview or auxiliary image. The choice follows the saved gallery copy and future cloud sync. Previously removed details cannot be recovered; older gallery entries use Remove. Originals stay unchanged. Photos and receiving apps may add their own dates or identifiers, and gallery/cloud operational records remain.")
                    Divider()
                    helpDisclosure("A photo is taking time to open", answer: "The system picker may need to download it from iCloud. Check your connection or try a photo already on your iPhone.")
                    Divider()
                    helpDisclosure("What is included free?", answer: "Edit and preview without an account. Your first successful save or share is free. Previously recorded two-export allowances are preserved. Failed or cancelled operations don’t count. Each successful output counts, even for the same photo. Veil Pro gives unlimited exports with a monthly or yearly subscription. Restore Purchases uses your Apple Account. Manage or cancel subscriptions in App Store account settings. Free exports are device-local and aren’t synchronized.")
                    helpDisclosure("I can’t save to Photos", answer: "Allow Veil to add photos in iPhone Settings. Share and Save to Veil remain available if permission is denied.")
                    Divider()
                    helpDisclosure("How can I contact support?", answer: "Use Contact Support in Settings when it is available. Include your iPhone model, iOS version, Veil version and the steps that failed. Do not include sensitive photos or recognized text.")
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Help / Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpDisclosure(_ title: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 16)
        } label: {
            Text(title)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 15)
        }
    }
}

/// Contextual, dismissible-by-inaction access messaging; purchases use the existing paywall.
struct PremiumPreviewNotice: View {
    let state: PremiumPreviewState
    let unlock: () -> Void
    var body: some View {
        if state.marked || state == .unavailable {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Text(state == .unavailable ? "Export access unavailable" : "Preview Mode").font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Button(action: unlock) {
                        Text("Unlock Clean Exports")
                            .font(.caption.weight(.semibold))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                        .modifier(VeilActionStyle(prominent: true))
                        .accessibilityIdentifier("unlockCleanExports")
                }
                Text(state == .exhausted
                     ? "Your free export allowance has been used. Upgrade to Pro to save or share clean photos."
                     : "Free-export access couldn’t be checked. Unlock this iPhone and try again, or restore Pro in the upgrade screen.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20).padding(.vertical, 6)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("premiumPreviewNotice")
        } else if state == .checking {
            ProgressView("Checking export access…").font(.caption).padding(8)
        }
    }
}

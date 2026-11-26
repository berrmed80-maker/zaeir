import SwiftUI

// MARK: - Theme

extension Color {
    init(hex: UInt) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0)
    }
    static let zDark = Color(hex: 0x0B3B2C)
    static let zGreen = Color(hex: 0x0F6B4F)
    static let zTerra = Color(hex: 0xB8431F)
    static let zGold = Color(hex: 0xD9A441)
    static let zBG = Color(hex: 0xFBF8F3)
    static let zInk = Color(hex: 0x1D1B18)
    static let zGrey = Color(hex: 0x5F5A52)
    static let zLine = Color(hex: 0xDAD3C6)
    static let zSand = Color(hex: 0xF1ECE3)
}

// MARK: - Localization

enum I18n {
    static let dict: [String: [String: String]] = {
        var out: [String: [String: String]] = [:]
        for name in ["i18n_a", "i18n_b"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]] else { continue }
            for (lang, entries) in obj { out[lang] = entries }
        }
        return out
    }()
}

func tr(_ s: String) -> String {
    let lang = UserDefaults.standard.string(forKey: "lang") ?? "en"
    if lang == "en" { return s }
    if let t = I18n.dict[lang]?[s], !t.isEmpty { return t }
    if let t = Extras.data.i18n[lang]?[s], !t.isEmpty { return t }
    return s
}

func ts(_ format: String, _ args: String...) -> String {
    var s = tr(format)
    for a in args {
        if let r = s.range(of: "%s") { s.replaceSubrange(r, with: a) }
    }
    return s
}

func tf(_ format: String, _ args: CVarArg...) -> String {
    String(format: tr(format), arguments: args)
}

// MARK: - Store

struct TripItem: Codable, Equatable, Identifiable {
    let cityId: String
    let sight: String
    var id: String { cityId + "|" + sight }
}

final class Store: ObservableObject {
    @Published var lang: String {
        didSet { UserDefaults.standard.set(lang, forKey: "lang") }
    }
    @Published var favs: Set<String> {
        didSet { UserDefaults.standard.set(Array(favs), forKey: "favs") }
    }
    @Published var trip: [TripItem] {
        didSet { if let d = try? JSONEncoder().encode(trip) { UserDefaults.standard.set(d, forKey: "trip") } }
    }
    @Published var notes: String {
        didSet { UserDefaults.standard.set(notes, forKey: "notes") }
    }
    @Published var packingDone: Set<String> {
        didSet { UserDefaults.standard.set(Array(packingDone), forKey: "packing") }
    }
    @Published var rates: [String: Double] {
        didSet { UserDefaults.standard.set(rates, forKey: "rates") }
    }

    init() {
        let ud = UserDefaults.standard
        lang = ud.string(forKey: "lang") ?? "en"
        favs = Set(ud.stringArray(forKey: "favs") ?? [])
        if let d = ud.data(forKey: "trip"), let t = try? JSONDecoder().decode([TripItem].self, from: d) {
            trip = t
        } else {
            trip = []
        }
        notes = ud.string(forKey: "notes") ?? ""
        packingDone = Set(ud.stringArray(forKey: "packing") ?? [])
        var r = (ud.dictionary(forKey: "rates") as? [String: Double]) ?? [:]
        for (k, v) in ["USD": 9.3, "EUR": 10.8, "GBP": 12.6] where r[k] == nil { r[k] = v }
        rates = r
    }

    func toggleFav(_ id: String) {
        if favs.contains(id) { favs.remove(id) } else { favs.insert(id) }
    }
    func inTrip(_ item: TripItem) -> Bool { trip.contains(item) }
    func toggleTrip(_ item: TripItem) {
        if let i = trip.firstIndex(of: item) { trip.remove(at: i) } else { trip.append(item) }
    }
    func clearTrip() { trip.removeAll() }
    func city(_ id: String) -> City? { DB.data.cities.first { $0.id == id } }
}

// MARK: - App

@main
struct ZaeirApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var showWelcome = !UserDefaults.standard.bool(forKey: "welcomed")
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "initialTab")

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(tr("Home"), systemImage: "house.fill") }
                .tag(0)
            ExploreView()
                .tabItem { Label(tr("Explore"), systemImage: "magnifyingglass") }
                .tag(1)
            TripView()
                .tabItem { Label(tr("Trips"), systemImage: "map.fill") }
                .tag(2)
            SavedView()
                .tabItem { Label(tr("Saved"), systemImage: "heart.fill") }
                .tag(3)
            GuideView()
                .tabItem { Label(tr("Guide"), systemImage: "book.fill") }
                .tag(4)
        }
        .tint(.zGreen)
        .environment(\.layoutDirection, store.lang == "ar" ? .rightToLeft : .leftToRight)
        .overlay {
            if let scr = UserDefaults.standard.string(forKey: "debugScreen"), !scr.isEmpty {
                NavigationStack {
                    switch scr {
                    case "phrasebook": PhrasebookView()
                    case "budget": BudgetView()
                    case "plan": PlanDayView()
                    case "safety": ScrollView { SafetyExtrasCard(city: DB.data.cities[0]).padding(16) }.background(Color.zBG.ignoresSafeArea())
                    case "darija": ScrollView { DarijaOrderCard().padding(16) }.background(Color.zBG.ignoresSafeArea())
                    default: EmptyView()
                    }
                }
                .background(Color.zBG.ignoresSafeArea())
            }
        }
        .overlay {
            if let id = UserDefaults.standard.string(forKey: "debugCity"), !id.isEmpty, let c = store.city(id) {
                NavigationStack { CityView(city: c) }
                    .background(Color.zBG.ignoresSafeArea())
            }
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView(show: $showWelcome)
        }
    }
}

// MARK: - Language menu

struct LanguageMenu: View {
    @EnvironmentObject var store: Store
    private let langs: [(String, String)] = [("en", "EN"), ("fr", "FR"), ("es", "ES"), ("ar", "AR")]
    var body: some View {
        Menu {
            ForEach(langs, id: \.0) { code, label in
                Button {
                    store.lang = code
                } label: {
                    if store.lang == code {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            Text(store.lang.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.zGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.zSand)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    @Binding var show: Bool
    private let icons = ["calendar", "fork.knife", "exclamationmark.shield.fill", "wifi.slash"]

    @ViewBuilder private var backdrop: some View {
        if let ui = bundleImage("marrakech") {
            Color.black
                .overlay(
                    Image(uiImage: ui).resizable().scaledToFill()
                )
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.75), .black.opacity(0.25)],
                                   startPoint: .bottom, endPoint: .top)
                )
        } else {
            LinearGradient(colors: [.zDark, .zTerra], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var isAR: Bool { (UserDefaults.standard.string(forKey: "lang") ?? "en") == "ar" }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 0)
            Text(tr("WELCOME TO"))
                .font(.system(size: 13, weight: .semibold))
                .tracking(isAR ? 0 : 3)
                .foregroundColor(.white.opacity(0.8))
            Text("Zaeir")
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(tf("An offline guide to %d destinations across Morocco.", DB.data.cities.count))
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(DB.content.welcome.enumerated()), id: \.offset) { i, f in
                    Label(tr(f), systemImage: icons[min(i, icons.count - 1)])
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 8)
            Button {
                UserDefaults.standard.set(true, forKey: "welcomed")
                show = false
            } label: {
                Text(tr("Get started"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.zDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 6)
        }
        .padding(28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(backdrop.ignoresSafeArea())
        .environment(\.layoutDirection, isAR ? .rightToLeft : .leftToRight)
    }
}

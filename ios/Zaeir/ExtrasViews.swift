import SwiftUI

// MARK: - Extra offline content (phrasebook etc.)

struct PBPhrase: Codable, Identifiable {
    let l: String
    let a: String
    let en: String
    let fr: String
    let es: String
    let ar: String
    let n: Int
    var id: String { l + "|" + en }
    func meaning(_ lang: String) -> String {
        switch lang {
        case "fr": return fr
        case "es": return es
        case "ar": return ar
        default: return en
        }
    }
}

struct PBCategory: Codable, Identifiable {
    let id: String
    let t: String
    let items: [PBPhrase]
}

struct ExtrasData: Codable {
    let phrasebook: [PBCategory]
    let i18n: [String: [String: String]]
}

enum Extras {
    static let data: ExtrasData = {
        guard let url = Bundle.main.url(forResource: "extras", withExtension: "json"),
              let d = try? Data(contentsOf: url),
              let obj = try? JSONDecoder().decode(ExtrasData.self, from: d) else {
            return ExtrasData(phrasebook: [], i18n: [:])
        }
        return obj
    }()
}

// MARK: - Phrasebook

struct PhrasebookView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var cat = "all"

    private var shown: [(PBCategory, [PBPhrase])] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return Extras.data.phrasebook.compactMap { c in
            if cat != "all" && c.id != cat { return nil }
            let items = c.items.filter { p in
                q.isEmpty || p.l.lowercased().contains(q) || p.a.contains(q)
                    || p.en.lowercased().contains(q) || p.meaning(store.lang).lowercased().contains(q)
            }
            return items.isEmpty ? nil : (c, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Darija phrasebook"), subtitle: tr("Offline phrases with sources"), height: 120)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.zGrey)
                    TextField(tr("Search phrases"), text: $query)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zLine, lineWidth: 1))
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("all", tr("All"))
                        ForEach(Extras.data.phrasebook) { c in chip(c.id, tr(c.t)) }
                    }
                    .padding(.horizontal, 16)
                }

                if shown.isEmpty {
                    Card { Text(tr("No phrase matches your search.")).foregroundColor(.zGrey) }
                }
                ForEach(shown, id: \.0.id) { pair in
                    SectionTitle(text: pair.0.t)
                    ForEach(pair.1) { p in
                        Card {
                            Text(p.meaning(store.lang))
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(.zGrey)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(alignment: .firstTextBaseline) {
                                Text(p.l)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.zInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Text(p.a)
                                    .font(.system(size: 17))
                                    .foregroundColor(.zGreen)
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Chip(text: tr(p.n >= 2 ? "Checked in 2 or more sources" : "Single source, less certain"),
                                 tint: p.n >= 2 ? .zGreen : .zGold)
                        }
                    }
                }
                Card {
                    Text(tr("Spelling varies between regions and sources. Phrases were written by the author from public sources and not checked by a native speaker. Meanings in your language are machine-translated."))
                        .font(.system(size: 12.5))
                        .foregroundColor(.zGrey)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(tr("Sources: Wikivoyage Moroccan Arabic phrasebook (CC BY-SA), moroccomag.com phrasebook, dailydarija.com bargaining guide, darijamarocain.com taxi guide."))
                        .font(.system(size: 12))
                        .foregroundColor(.zGrey)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Darija"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chip(_ id: String, _ title: String) -> some View {
        Button { cat = id } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(cat == id ? .white : .zInk)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(cat == id ? Color.zGreen : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.zLine, lineWidth: cat == id ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trip budget

struct BudgetView: View {
    @EnvironmentObject var store: Store
    @AppStorage("bud_days") private var days = "5"
    @AppStorage("bud_people") private var people = "2"
    @AppStorage("bud_stay") private var stay = ""
    @AppStorage("bud_food") private var food = ""
    @AppStorage("bud_transport") private var transport = ""
    @AppStorage("bud_activities") private var activities = ""
    @AppStorage("bud_other") private var other = ""

    private func num(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var totalMAD: Double {
        let d = max(num(days), 0), p = max(num(people), 0)
        return d * num(stay) + d * p * num(food) + d * num(transport) + d * p * num(activities) + num(other)
    }
    private var perPersonDay: Double {
        let d = num(days), p = num(people)
        return (d > 0 && p > 0) ? totalMAD / (d * p) : 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Hero(title: tr("Trip budget"), subtitle: tr("Plan what you expect to spend"), height: 120)
                Card {
                    Text(tr("Add your own numbers"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.zInk)
                    field(tr("Days"), $days)
                    field(tr("Travellers"), $people)
                    field(tr("Stay per night (MAD, whole room)"), $stay)
                    field(tr("Food per person per day (MAD)"), $food)
                    field(tr("Transport per day (MAD, total)"), $transport)
                    field(tr("Activities and tickets per person per day (MAD)"), $activities)
                    field(tr("Other costs for the whole trip (MAD)"), $other)
                }
                Card {
                    Text(tr("Total in dirham"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.zGrey)
                    Text(String(format: "%.0f MAD", totalMAD))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.zGreen)
                    HStack(spacing: 14) {
                        ForEach(["USD", "EUR", "GBP"], id: \.self) { c in
                            let r = store.rates[c] ?? 10
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c).font(.system(size: 12, weight: .semibold)).foregroundColor(.zGrey)
                                Text(String(format: "%.0f", r > 0 ? totalMAD / r : 0))
                                    .font(.system(size: 17, weight: .bold)).foregroundColor(.zInk)
                            }
                        }
                    }
                    Text(tr("Per person per day") + ": " + String(format: "%.0f MAD", perPersonDay))
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.zInk)
                    Text(tr("Converted with your rates from the Currency converter. Not live."))
                        .font(.system(size: 12))
                        .foregroundColor(.zGrey)
                }
                Card {
                    Text(tr("The app does not guess prices. Type your own figures. The Prices page lists sourced fares and ticket costs to help you."))
                        .font(.system(size: 13))
                        .foregroundColor(.zGrey)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Trip budget"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12.5, weight: .medium)).foregroundColor(.zGrey)
            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .font(.system(size: 18, weight: .semibold))
                .padding(10)
                .background(Color.zSand)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

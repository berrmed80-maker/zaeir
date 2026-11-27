import SwiftUI

// MARK: - Guide index

struct GuideView: View {
    private let groups: [(String, [(String, String)])] = [
        ("Plan your trip", [
            ("Entry & visa", "globe"),
            ("Money", "banknote"),
            ("Itineraries", "map"),
            ("Packing", "checklist"),
            ("Prices", "tag"),
            ("Tips", "lightbulb"),
            ("Darija", "bubble.left.and.bubble.right"),
            ("SIM and internet", "antenna.radiowaves.left.and.right"),
            ("Power and water", "bolt"),
        ]),
        ("On the ground", [
            ("Emergency", "phone.badge.plus"),
            ("Safety", "shield"),
            ("Laws to know", "building.columns"),
            ("Women travellers", "figure.stand.dress"),
            ("Scams", "exclamationmark.triangle"),
            ("Getting around", "tram"),
            ("Activities", "figure.hiking"),
            ("Map", "map"),
            ("First day", "sunrise"),
            ("Offline", "wifi.slash"),
            ("Photo credits", "camera"),
            ("About", "info.circle"),
        ]),
        ("Culture and heritage", [
            ("Etiquette", "hands.sparkles"),
            ("Food", "fork.knife"),
            ("UNESCO sites", "building.2"),
            ("Holidays", "calendar"),
            ("Ramadan", "moon.stars"),
        ]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Hero(title: tr("Travel guide"), subtitle: tr("Everything you need on the ground"), height: 130)
                    ForEach(Array(groups.enumerated()), id: \.offset) { _, g in
                        SectionTitle(text: g.0)
                        VStack(spacing: 0) {
                            ForEach(Array(g.1.enumerated()), id: \.offset) { i, item in
                                NavigationLink { destination(for: item.0) } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: item.1)
                                            .font(.system(size: 16))
                                            .foregroundColor(.zGreen)
                                            .frame(width: 30, height: 30)
                                            .background(Color.zSand)
                                            .clipShape(Circle())
                                        Text(tr(item.0))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.zInk)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.zGrey)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                                    .background(Color.white)
                                }
                                .buttonStyle(.plain)
                                if i < g.1.count - 1 {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zLine, lineWidth: 1))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.zBG.ignoresSafeArea())
            .navigationTitle(tr("Guide"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { LanguageMenu() }
            }
        }
    }

    @ViewBuilder
    private func destination(for name: String) -> some View {
        switch name {
        case "Itineraries": ItinerariesView()
        case "Packing": PackingView()
        case "Prices": PricesView()
        case "Tips": TipsView()
        case "Darija": PhrasebookView()
        case "Emergency": EmergencyView()
        case "Scams": ScamsView()
        case "Activities": ActivitiesView()
        case "Map": CityMapView()
        case "First day": FirstDayView()
        case "Offline": OfflineView()
        case "Photo credits": CreditsView()
        case "About": AboutView()
        case "UNESCO sites": UnescoView()
        default: InfoPageView(name: name)
        }
    }
}

// MARK: - Generic info page (sections of paragraphs from content.json)

struct InfoPageView: View {
    let name: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr(name), height: 110)
                let sections = DB.content.pages[name] ?? []
                ForEach(Array(sections.enumerated()), id: \.offset) { _, sec in
                    if let title = sec.first {
                        Card {
                            Text(tr(title))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.zInk)
                            ForEach(Array(sec.dropFirst().enumerated()), id: \.offset) { _, p in
                                Text(tr(p))
                                    .font(.system(size: 14))
                                    .foregroundColor(.zGrey)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr(name))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Emergency

struct EmergencyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Emergency"), subtitle: tr("Official numbers in Morocco"), height: 120)
                ForEach(Array(DB.content.emergency.enumerated()), id: \.offset) { _, row in
                    if row.count >= 3 {
                        Card {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tr(row[0]))
                                        .font(.system(size: 15.5, weight: .bold))
                                        .foregroundColor(.zInk)
                                    Text(tr(row[2]))
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.zGrey)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                if let url = URL(string: "tel:\(row[1])") {
                                    Link(destination: url) {
                                        Text(row[1])
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.zTerra)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Emergency"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Prices

struct PricesView: View {
    private func lvlColor(_ lvl: String) -> Color {
        switch lvl {
        case "verified": return .zGreen
        case "estimate": return .zGold
        default: return .zGrey
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Prices"), subtitle: tr("Fares and fees"), height: 120)
                ForEach(DB.data.general.prices) { p in
                    Card {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr(p.k))
                                    .font(.system(size: 14.5, weight: .semibold))
                                    .foregroundColor(.zInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                HStack(spacing: 6) {
                                    Chip(text: tr(p.lvl), tint: lvlColor(p.lvl))
                                }
                                Text(tr(p.src))
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.zGrey)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 10)
                            Text(p.v)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.zGreen)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Prices"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Phrases (Darija)

struct PhrasesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Darija"), subtitle: tr("Useful phrases"), height: 120)
                ForEach(Array(DB.data.general.phrases.enumerated()), id: \.offset) { _, ph in
                    if ph.count >= 3 {
                        Card {
                            Text(tr(ph[0]))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.zGrey)
                            HStack {
                                Text(ph[1])
                                    .font(.system(size: 16.5, weight: .bold))
                                    .foregroundColor(.zInk)
                                Spacer()
                                Text(ph[2])
                                    .font(.system(size: 16.5))
                                    .foregroundColor(.zGreen)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Darija"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tips

struct TipsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Tips"), subtitle: tr("Money, water, trains"), height: 120)
                Card {
                    ForEach(Array(DB.data.general.tips.enumerated()), id: \.offset) { _, t in
                        BulletRow(text: tr(t))
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Tips"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Scams

struct ScamsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Common scams"), subtitle: tr("Stay safe"), height: 120)
                ForEach(DB.data.general.scams) { s in
                    Card {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.zTerra)
                            Text(tr(s.t))
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(.zInk)
                        }
                        Text(tr(s.d))
                            .font(.system(size: 14))
                            .foregroundColor(.zGrey)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Scams"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Activities

struct ActivitiesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Activities"), subtitle: tr("Things to do"), height: 120)
                ForEach(Array(DB.content.activities.enumerated()), id: \.offset) { _, a in
                    if a.count >= 2 {
                        Card {
                            Text(tr(a[0]))
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(.zInk)
                            Text(tr(a[1]))
                                .font(.system(size: 14))
                                .foregroundColor(.zGrey)
                                .fixedSize(horizontal: false, vertical: true)
                            if a.count >= 3 {
                                Text(tr("Source") + ": " + a[2])
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.zGrey)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Activities"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UNESCO

struct UnescoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("UNESCO sites"), subtitle: tr("World Heritage in Morocco"), height: 120)
                ForEach(Array(DB.content.unesco.enumerated()), id: \.offset) { _, u in
                    if u.count >= 3 {
                        Card {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tr(u[0]))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.zInk)
                                    Text(tr(u[1]) + " \u{00B7} " + u[2])
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.zGrey)
                                }
                                Spacer()
                                if u.count >= 4, !u[3].isEmpty,
                                   let c = DB.data.cities.first(where: { $0.id == u[3] }) {
                                    NavigationLink { CityView(city: c) } label: {
                                        Text(c.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.zGreen)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.zGreen.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("UNESCO sites"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - First day

struct FirstDayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("First day"), subtitle: tr("What to do when you arrive"), height: 120)
                Card {
                    ForEach(Array(DB.content.firstDay.enumerated()), id: \.offset) { i, t in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.zGold)
                                .clipShape(Circle())
                            Text(tr(t))
                                .font(.system(size: 14.5))
                                .foregroundColor(.zInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("First day"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Packing checklist

struct PackingView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Packing"), subtitle: tr("Checklist"), height: 120)
                Card {
                    ForEach(Array(DB.content.packing.enumerated()), id: \.offset) { _, item in
                        Button {
                            if store.packingDone.contains(item) {
                                store.packingDone.remove(item)
                            } else {
                                store.packingDone.insert(item)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: store.packingDone.contains(item) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(store.packingDone.contains(item) ? .zGreen : .zGrey)
                                    .font(.system(size: 20))
                                Text(tr(item))
                                    .font(.system(size: 14.5))
                                    .foregroundColor(.zInk)
                                    .strikethrough(store.packingDone.contains(item))
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(tr("Your checklist stays on this phone."))
                    .font(.system(size: 12.5))
                    .foregroundColor(.zGrey)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Packing"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Offline

struct OfflineView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Offline"), subtitle: tr("How it works"), height: 120)
                Card {
                    BulletRow(text: tr("Every city, sight, price and phrase is inside the app. No internet needed."))
                    BulletRow(text: tr("Your trip, checklist and notes stay on this phone."))
                    BulletRow(text: tr("Only the Maps buttons and web links need internet."))
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Offline"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Photo credits

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Photo credits"), subtitle: tr("Image sources"), height: 120)
                Card {
                    Text(tr("City photos come from Wikimedia Commons and Flickr under Creative Commons licences. Cities without a photo are marked."))
                        .font(.system(size: 13.5))
                        .foregroundColor(.zGrey)
                }
                ForEach(DB.data.cities) { c in
                    if let cr = DB.credits[c.id] {
                        Card {
                            Text(c.name)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundColor(.zInk)
                            Text(cr.a)
                                .font(.system(size: 13))
                                .foregroundColor(.zGrey)
                            HStack(spacing: 6) {
                                Chip(text: cr.l, tint: .zGreen)
                                Text(cr.f)
                                    .font(.system(size: 11))
                                    .foregroundColor(.zGrey)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Photo credits"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("About"), subtitle: tr("Sources and limits"), height: 120)
                ForEach(Array(DB.data.general.sources.enumerated()), id: \.offset) { _, s in
                    if s.count >= 3 {
                        Card {
                            Text(tr(s[0]))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.zInk)
                            if s[1].count > 0, let url = URL(string: s[1]) {
                                Link(s[1], destination: url)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.zGreen)
                                    .lineLimit(1)
                            }
                            Text(tr(s[2]))
                                .font(.system(size: 13))
                                .foregroundColor(.zGrey)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Card {
                    Text(tr("Prices and opening hours change, so confirm on site. No hotel or restaurant prices are included. Map links open your Maps app and need internet."))
                        .font(.system(size: 13.5))
                        .foregroundColor(.zGrey)
                }
                Text("Zaeir 6.6.1 \u{00B7} " + tr("Data built") + " " + DB.data.built)
                    .font(.system(size: 12))
                    .foregroundColor(.zGrey)
                    .padding(.horizontal, 20)
                Text(tr("Menus, buttons and city guides are translated (machine translation, not reviewed by a native speaker)."))
                    .font(.system(size: 11.5))
                    .foregroundColor(.zGrey)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("About"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Itineraries list

struct ItinerariesView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Itineraries"), subtitle: tr("Ready-made routes"), height: 120)
                ForEach(Array(DB.content.itineraries.enumerated()), id: \.offset) { _, it in
                    if it.count >= 2 {
                        NavigationLink { ItineraryView(title: it[0], ids: it[1].split(separator: ",").map { String($0) }) } label: {
                            Card {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tr(it[0]))
                                            .font(.system(size: 15.5, weight: .bold))
                                            .foregroundColor(.zInk)
                                        Text(it[1].split(separator: ",").compactMap { store.city(String($0))?.name }.joined(separator: " \u{2192} "))
                                            .font(.system(size: 12.5))
                                            .foregroundColor(.zGrey)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.zGrey)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Itineraries"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

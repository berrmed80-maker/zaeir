import SwiftUI
import CoreLocation

// MARK: - Trip tab

struct TripView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Hero(title: tr("My trip"), subtitle: tr("YOUR TRIP"), height: 120)

                    if store.trip.isEmpty {
                        Card {
                            Text(tr("Your trip is empty. Open a city and tap Add to my trip on the sights you want."))
                                .font(.system(size: 14.5))
                                .foregroundColor(.zGrey)
                        }
                    } else {
                        tripContent
                    }

                    SectionTitle(text: "Itineraries")
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

                    SectionTitle(text: "Between cities")
                    ForEach(Array(DB.content.routes.enumerated()), id: \.offset) { _, r in
                        if r.count >= 3 {
                            Card {
                                Text(store.city(r[0])?.name ?? r[0]) .font(.system(size: 14.5, weight: .bold)).foregroundColor(.zInk)
                                + Text(" \u{2192} ").font(.system(size: 14.5, weight: .bold)).foregroundColor(.zTerra)
                                + Text(store.city(r[1])?.name ?? r[1]).font(.system(size: 14.5, weight: .bold)).foregroundColor(.zInk)
                                Text(tr(r[2]))
                                    .font(.system(size: 13.5))
                                    .foregroundColor(.zGrey)
                            }
                        }
                    }

                    SectionTitle(text: "Tools")
                    toolsCards
                }
                .padding(.vertical, 12)
            }
            .background(Color.zBG.ignoresSafeArea())
            .navigationTitle(tr("Trips"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tripContent: some View {
        VStack(spacing: 10) {
            ForEach(store.trip) { item in
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tr(item.sight))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.zInk)
                            Text(store.city(item.cityId)?.name ?? item.cityId)
                                .font(.system(size: 12.5))
                                .foregroundColor(.zGrey)
                        }
                        Spacer()
                        Button { store.toggleTrip(item) } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.zGrey)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 10) {
                ShareLink(item: tripText) {
                    Label(tr("Share"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.zGreen)
                        .clipShape(Capsule())
                }
                Button { store.clearTrip() } label: {
                    Text(tr("Clear trip"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.zTerra)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.zTerra.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
    }

    private var tripText: String {
        var lines = ["Zaeir - " + tr("My trip")]
        for item in store.trip {
            let cityName = store.city(item.cityId)?.name ?? item.cityId
            lines.append("- \(item.sight) (\(cityName))")
        }
        return lines.joined(separator: "\n")
    }

    private var toolsCards: some View {
        let tools: [(String, String, AnyView)] = [
            ("Between cities", "arrow.left.and.right", AnyView(BetweenView())),
            ("Currency converter", "banknote", AnyView(ConverterView())),
            ("Trip budget", "chart.pie", AnyView(BudgetView())),
            ("Quiz", "questionmark.circle", AnyView(QuizView())),
            ("Trip notes", "note.text", AnyView(NotesView())),
            ("Tip of the day", "lightbulb", AnyView(TipOfDayView())),
        ]
        return VStack(spacing: 10) {
            ForEach(Array(tools.enumerated()), id: \.offset) { _, t in
                NavigationLink { t.2 } label: {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: t.1)
                                .font(.system(size: 18))
                                .foregroundColor(.zGreen)
                                .frame(width: 26)
                            Text(tr(t.0))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.zInk)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.zGrey)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Itinerary detail

struct ItineraryView: View {
    @EnvironmentObject var store: Store
    let title: String
    let ids: [String]

    private func addTopSights() {
        for id in ids {
            guard let c = store.city(id) else { continue }
            var added = 0
            for pr in 1...3 where added < 2 {
                for sg in c.sights where sg.p == pr && added < 2 {
                    let item = TripItem(cityId: id, sight: sg.n)
                    if !store.inTrip(item) { store.toggleTrip(item); added += 1 }
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr(title), subtitle: tf("%d places", ids.count), height: 130)
                ForEach(Array(ids.enumerated()), id: \.offset) { i, id in
                    if let c = DB.data.cities.first(where: { $0.id == id }) {
                        NavigationLink { CityView(city: c) } label: {
                            Card {
                                HStack(spacing: 12) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Color.zGreen)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.name)
                                            .font(.system(size: 15.5, weight: .bold))
                                            .foregroundColor(.zInk)
                                        Text(tf("%d days", c.days))
                                            .font(.system(size: 12.5))
                                            .foregroundColor(.zGrey)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.zGrey)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    addTopSights()
                } label: {
                    Text(tr("Add to my trip"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.zTerra)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Itineraries"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Between cities

struct BetweenView: View {
    @EnvironmentObject var store: Store
    @State private var from = "marrakech"
    @State private var to = "fes"

    private var distanceKm: Int? {
        guard let a = store.city(from), let b = store.city(to), from != to else { return nil }
        let d = CLLocation(latitude: a.lat, longitude: a.lon)
            .distance(from: CLLocation(latitude: b.lat, longitude: b.lon))
        return Int((d / 1000).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Hero(title: tr("Between cities"), subtitle: tr("Distance and how to travel"), height: 130)
                Card {
                    Text(tr("From"))
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.zGrey)
                    Picker(tr("From"), selection: $from) {
                        ForEach(DB.data.cities) { c in Text(c.name).tag(c.id) }
                    }
                    .pickerStyle(.menu)
                    .tint(.zGreen)
                    Text(tr("To"))
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.zGrey)
                        .padding(.top, 6)
                    Picker(tr("To"), selection: $to) {
                        ForEach(DB.data.cities) { c in Text(c.name).tag(c.id) }
                    }
                    .pickerStyle(.menu)
                    .tint(.zGreen)
                }
                if let km = distanceKm, let a = store.city(from), let b = store.city(to) {
                    Card {
                        Text("\(a.name) - \(b.name)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.zGreen)
                        Text(tf("About %d km in a straight line. Roads are longer.", km))
                            .font(.system(size: 14))
                            .foregroundColor(.zInk)
                            .padding(.top, 2)
                    }
                    ForEach(Array(DB.content.routes.enumerated()), id: \.offset) { _, r in
                        if r.count >= 3, (r[0] == from && r[1] == to) || (r[1] == from && r[0] == to) {
                            Card {
                                Text(tr("Sourced trip info"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.zInk)
                                Text(tr(r[2]))
                                    .font(.system(size: 13.5))
                                    .foregroundColor(.zGrey)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    Card {
                        Text(tr("Train"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.zInk)
                        Text(tr("Trains are usually the best option between big cities. Buy tickets only on the official ONCF site, not on resellers that add a mark-up (Wikivoyage). Times and prices change."))
                            .font(.system(size: 13.5))
                            .foregroundColor(.zGrey)
                            .padding(.top, 2)
                        Link(destination: URL(string: "https://www.oncf-voyages.ma")!) {
                            Text(tr("ONCF tickets"))
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.zGreen)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 6)
                    }
                    Card {
                        Text(tr("Bus"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.zInk)
                        Text(tr("CTM and Supratours run intercity buses. Buy at the official ticket window, not from touts. Supratours links the train network to Essaouira and Atlantic coast towns (Wikivoyage)."))
                            .font(.system(size: 13.5))
                            .foregroundColor(.zGrey)
                            .padding(.top, 2)
                    }
                    Card {
                        Text(tr("Getting around in each city"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.zInk)
                        Text("\(a.name): \(tr(a.transport))")
                            .font(.system(size: 13.5))
                            .foregroundColor(.zGrey)
                            .padding(.top, 2)
                        Text("\(b.name): \(tr(b.transport))")
                            .font(.system(size: 13.5))
                            .foregroundColor(.zGrey)
                            .padding(.top, 2)
                    }
                    Text(tr("Live timetables and fares are not in this app. Check on site or on the operator site."))
                        .font(.system(size: 12))
                        .foregroundColor(.zGrey)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Between cities"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency converter

struct ConverterView: View {
    @EnvironmentObject var store: Store
    @State private var amount = "100"
    @State private var sel = "EUR"
    @State private var toMad = true
    @State private var editingRate = false
    @State private var rateText = ""

    private let currencies = ["USD", "EUR", "GBP"]

    private var rate: Double { store.rates[sel] ?? 10.0 }

    private var result: String {
        let a = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let value = toMad ? a * rate : (rate == 0 ? 0 : a / rate)
        return String(format: "%.0f", value)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Hero(title: tr("Currency converter"), subtitle: tr("Dirham and your currency"), height: 130)
                Card {
                    HStack(spacing: 8) {
                        ForEach(currencies, id: \.self) { c in
                            Button { sel = c } label: {
                                Text(c)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(sel == c ? .white : .zInk)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(sel == c ? Color.zGreen : Color.zSand)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 10) {
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.zInk)
                            .padding(10)
                            .background(Color.zSand)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Text(toMad ? sel : "MAD")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zGrey)
                    }
                    Button { withAnimation { toMad.toggle() } } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.zTerra)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    HStack {
                        Text(result)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.zGreen)
                        Text(toMad ? "MAD" : sel)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.zGrey)
                    }
                    Button {
                        rateText = String(format: "%.2f", rate)
                        editingRate = true
                    } label: {
                        Text(tr("Rate") + ": 1 \(sel) = \(String(format: "%.2f", rate)) MAD \u{00B7} " + tr("Edit"))
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.zGrey)
                    }
                    .buttonStyle(.plain)
                }
                Card {
                    Text(tr("Default rates as of August 2026 (Wikivoyage). Rates move. Check XE.com or your bank for today's rate."))
                        .font(.system(size: 13))
                        .foregroundColor(.zGrey)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Currency converter"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(tr("Rate") + ": 1 \(sel) = ? MAD", isPresented: $editingRate) {
            TextField("10.80", text: $rateText)
                .keyboardType(.decimalPad)
            Button(tr("Save")) {
                if let v = Double(rateText.replacingOccurrences(of: ",", with: ".")), v > 0 {
                    store.rates[sel] = v
                }
            }
            Button(tr("Cancel"), role: .cancel) {}
        }
    }
}

// MARK: - Trip notes

struct NotesView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $store.notes)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zLine, lineWidth: 1))
                .padding(16)
            Text(tr("Notes stay on this phone."))
                .font(.system(size: 12.5))
                .foregroundColor(.zGrey)
                .padding(.horizontal, 20)
            Spacer()
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Trip notes"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Quiz

struct QuizView: View {
    @State private var index = 0
    @State private var picked: Int? = nil
    @State private var score = 0

    private var questions: [[String]] { DB.content.quiz }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Hero(title: tr("Quiz"), subtitle: tr("How well do you know Morocco?"), height: 120)
                if index < questions.count {
                    let q = questions[index]
                    if q.count >= 7 {
                        Card {
                            Text(tr("Question") + " \(index + 1)/\(questions.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.zGrey)
                            Text(tr(q[0]))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.zInk)
                        }
                        ForEach(1...4, id: \.self) { i in
                            Button {
                                if picked == nil {
                                    picked = i
                                    if String(i - 1) == q[5] { score += 1 }
                                }
                            } label: {
                                HStack {
                                    Text(tr(q[i]))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.zInk)
                                    Spacer()
                                    if let p = picked, p == i {
                                        Image(systemName: String(i - 1) == q[5] ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(String(i - 1) == q[5] ? .zGreen : .zTerra)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor(for: i, q: q), lineWidth: 1.5))
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                        }
                        if picked != nil {
                            Card {
                                Text(tr(q[6]))
                                    .font(.system(size: 14))
                                    .foregroundColor(.zGrey)
                                Button {
                                    picked = nil
                                    index += 1
                                } label: {
                                    Text(tr(index + 1 < questions.count ? "Next" : "Finish"))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.zGreen)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    Card {
                        Text(tr("Your score"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.zGrey)
                        Text("\(score)/\(questions.count)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.zGreen)
                        Button {
                            index = 0
                            score = 0
                            picked = nil
                        } label: {
                            Text(tr("Restart"))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.zGreen)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Quiz"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func borderColor(for i: Int, q: [String]) -> Color {
        guard let p = picked else { return .zLine }
        if String(i - 1) == q[5] && p == i { return .zGreen }
        if p == i { return .zTerra }
        return .zLine
    }
}

// MARK: - Tip of the day

struct TipOfDayView: View {
    private var items: [(String, String, String)] {
        var out: [(String, String, String)] = []
        for s in DB.data.general.scams { out.append((tr("Scam alert"), s.t, s.d)) }
        for t in DB.data.general.tips { out.append((tr("Travel tip"), "", t)) }
        return out
    }

    var body: some View {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let all = items
        let pick = all.isEmpty ? nil : all[(day - 1) % all.count]
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Hero(title: tr("Tip of the day"), subtitle: tr("Scams and travel tips"), height: 120)
                if let pick = pick {
                    Card {
                        Chip(text: pick.0, tint: pick.0 == tr("Scam alert") ? .zTerra : .zGreen)
                        if !pick.1.isEmpty {
                            Text(tr(pick.1))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.zInk)
                        }
                        Text(tr(pick.2))
                            .font(.system(size: 14.5))
                            .foregroundColor(.zGrey)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Tip of the day"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

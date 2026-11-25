import SwiftUI
import MapKit

// MARK: - City detail

struct CityView: View {
    @EnvironmentObject var store: Store
    let city: City
    @State private var tab = 0

    private let tabs = ["What to see", "Where to stay", "Eat", "Safety", "Day trips", "Map"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    CityImage(id: city.id)
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                    LinearGradient(colors: [.black.opacity(0.65), .black.opacity(0.05)], startPoint: .bottom, endPoint: .top)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 10) {
                            Text(city.name)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(city.ar)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Text(tr(city.tagline))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(2)
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)

                HStack(spacing: 8) {
                    Chip(text: tr(city.region))
                    Chip(text: tf("%d days", city.days), tint: .zTerra)
                    Chip(text: tr("Best season") + ": " + tr(city.best), tint: .zGold)
                }
                .padding(.horizontal, 16)

                tabPicker
                tabContent

                VStack(alignment: .leading, spacing: 6) {
                    if let url = URL(string: city.wvsrc) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                Text(tr("Source") + ": Wikivoyage (CC BY-SA)")
                                    .font(.system(size: 12.5, weight: .medium))
                            }
                            .foregroundColor(.zGreen)
                        }
                    }
                    if let cr = DB.credits[city.id] {
                        Text(tr("Photo") + ": " + cr.a + " \u{00B7} " + cr.l)
                            .font(.system(size: 11.5))
                            .foregroundColor(.zGrey)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(city.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.toggleFav(city.id)
                } label: {
                    Image(systemName: store.favs.contains(city.id) ? "heart.fill" : "heart")
                        .foregroundColor(store.favs.contains(city.id) ? .zGold : .zGrey)
                }
            }
        }
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, t in
                    Button { tab = i } label: {
                        Text(tr(t))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(tab == i ? .white : .zInk)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(tab == i ? Color.zGreen : Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.zLine, lineWidth: tab == i ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case 0: sightsTab
        case 1: stringsCard(city.stay, icon: "bed.double.fill")
        case 2: stringsCard(city.food, icon: "fork.knife")
        case 3: stringsCard(city.scams, icon: "exclamationmark.triangle.fill", tint: .zTerra)
        case 4: stringsCard(city.daytrips, icon: "bus.fill")
        default: mapTab
        }
    }

    private var sightsTab: some View {
        VStack(spacing: 10) {
            Text(tr("Open %s in your Maps app, or a single place from the Sights tab."))
                .font(.system(size: 12))
                .foregroundColor(.zGrey)
                .padding(.horizontal, 20)
            ForEach(city.sights) { s in
                Card {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Text(tr(s.n))
                                    .font(.system(size: 15.5, weight: .bold))
                                    .foregroundColor(.zInk)
                                if s.p == 1 {
                                    Chip(text: tr("Must see"), tint: .zGold)
                                }
                            }
                            HStack(spacing: 6) {
                                Chip(text: tr(s.tag), tint: .zGreen)
                                Chip(text: tf("%d min", s.min), tint: .zGrey)
                            }
                            Text(tr(s.note))
                                .font(.system(size: 13.5))
                                .foregroundColor(.zGrey)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(tr("Price: not included (no verified data)"))
                                .font(.system(size: 11.5))
                                .foregroundColor(.zGrey)
                        }
                        Spacer(minLength: 8)
                    }
                    HStack(spacing: 10) {
                        let item = TripItem(cityId: city.id, sight: s.n)
                        Button {
                            store.toggleTrip(item)
                        } label: {
                            Label(store.inTrip(item) ? tr("Remove") : tr("Add to my trip"),
                                  systemImage: store.inTrip(item) ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(store.inTrip(item) ? .zGreen : .zTerra)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        if let url = mapsURL(query: s.n + ", " + city.name + ", Morocco") {
                            Link(destination: url) {
                                Label(tr("Open in Maps"), systemImage: "map")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.zGreen)
                            }
                        }
                    }
                }
            }
        }
    }

    private func stringsCard(_ items: [String], icon: String, tint: Color = .zGreen) -> some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.self) { t in
                Card {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 15))
                            .foregroundColor(tint)
                            .padding(.top, 2)
                        Text(tr(t))
                            .font(.system(size: 14.5))
                            .foregroundColor(.zInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var mapTab: some View {
        VStack(spacing: 10) {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: city.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))),
                annotationItems: [city]) { c in
                MapMarker(coordinate: c.coordinate, tint: .zTerra)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16)
            if let url = mapsURL(lat: city.lat, lon: city.lon, label: city.name) {
                Link(destination: url) {
                    Label(tr("Open in Maps"), systemImage: "map.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.zGreen)
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                }
            }
            Card {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "tram.fill").foregroundColor(.zGreen)
                    Text(tr(city.transport))
                        .font(.system(size: 14.5))
                        .foregroundColor(.zInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

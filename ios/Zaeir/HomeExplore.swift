import SwiftUI
import MapKit
import CoreLocation

// MARK: - City row

struct CityRow: View {
    @EnvironmentObject var store: Store
    let city: City
    var hit: String = ""

    private var metaLine: String {
        var s = tr(city.region) + " \u{00B7} " + tf("%d days", city.days) + " \u{00B7} " + tf("%d places", city.sights.count)
        if !hit.isEmpty { s += " \u{00B7} " + hit }
        return s
    }

    var body: some View {
        HStack(spacing: 0) {
            CityImage(id: city.id)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.leading, 14)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(city.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.zInk)
                    Text(city.ar)
                        .font(.system(size: 14))
                        .foregroundColor(.zGrey)
                }
                Text(tr(city.tagline))
                    .font(.system(size: 13))
                    .foregroundColor(.zGrey)
                    .lineLimit(2)
                Text(metaLine)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.zGreen)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            Spacer(minLength: 0)
            Button {
                store.toggleFav(city.id)
            } label: {
                Image(systemName: store.favs.contains(city.id) ? "heart.fill" : "heart")
                    .foregroundColor(store.favs.contains(city.id) ? .zGold : .zGrey)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zLine, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

struct SearchBox: View {
    @Binding var query: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.zGrey)
            TextField(tr("Search cities and places"), text: $query)
                .font(.system(size: 15))
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.zGrey)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.zLine, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

func searchResults(_ query: String) -> [(City, String)] {
    let q = query.lowercased().trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { return [] }
    var out: [(City, String)] = []
    for c in DB.data.cities {
        var match = c.name.lowercased().contains(q) || c.ar.contains(q)
        var hit = ""
        if !match {
            for s in c.sights where s.n.lowercased().contains(q) {
                match = true
                hit = s.n
                break
            }
        }
        if match { out.append((c, hit)) }
    }
    return out
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Hero(title: tr("Discover\nMorocco"),
                         subtitle: tf("An offline guide to %d destinations across Morocco.", DB.data.cities.count),
                         imageId: "marrakech", height: 180)
                    SearchBox(query: $query)
                    if query.isEmpty {
                        homeCards
                        SectionTitle(text: "Top destinations")
                        topScroll
                        SectionTitle(text: "All cities")
                        ForEach(DB.data.cities) { c in
                            NavigationLink { CityView(city: c) } label: { CityRow(city: c) }
                                .buttonStyle(.plain)
                        }
                    } else {
                        let results = searchResults(query)
                        if results.isEmpty {
                            Text(tr("No results."))
                                .foregroundColor(.zGrey)
                                .padding(20)
                        }
                        ForEach(results, id: \.0.id) { c, hit in
                            NavigationLink { CityView(city: c) } label: { CityRow(city: c, hit: hit) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.zBG.ignoresSafeArea())
            .navigationTitle("Zaeir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { LanguageMenu() }
            }
        }
    }

    private var homeCards: some View {
        let icons = ["phone.badge.plus", "figure.hiking", "map", "checklist"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(DB.content.homeCards.enumerated()), id: \.offset) { i, name in
                    NavigationLink {
                        homeDestination(name)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: icons[min(i, icons.count - 1)])
                                .font(.system(size: 20))
                                .foregroundColor(.zGreen)
                            Text(tr(name))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.zInk)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(width: 120, height: 90, alignment: .topLeading)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func homeDestination(_ name: String) -> some View {
        switch name {
        case "Emergency": EmergencyView()
        case "Activities": ActivitiesView()
        case "Itineraries": ItinerariesView()
        case "Packing": PackingView()
        default: InfoPageView(name: name)
        }
    }

    private var topScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DB.topIds, id: \.self) { id in
                    if let c = store.city(id) {
                        NavigationLink { CityView(city: c) } label: {
                            ZStack(alignment: .bottomLeading) {
                                CityImage(id: c.id)
                                    .frame(width: 160, height: 210)
                                    .clipped()
                                LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .bottom, endPoint: .center)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(c.ar)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding(12)
                            }
                            .frame(width: 160, height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Explore

struct ExploreView: View {
    @EnvironmentObject var store: Store
    @State private var region = "All"
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Hero(title: tr("Explore"), subtitle: tr("Browse by region"), height: 120)
                    SearchBox(query: $query)
                    regionChips
                    if query.isEmpty {
                        NavigationLink { NearMeView() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.zGreen)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tr("Near me"))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.zInk)
                                    Text(tr("Cities closest to you"))
                                        .font(.system(size: 13))
                                        .foregroundColor(.zGrey)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.zGrey)
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zLine, lineWidth: 1))
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                    let shown = visibleCities
                    if shown.isEmpty {
                        Text(tr("No results.")).foregroundColor(.zGrey).padding(20)
                    }
                    ForEach(shown) { c in
                        NavigationLink { CityView(city: c) } label: { CityRow(city: c) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.zBG.ignoresSafeArea())
            .navigationTitle(tr("Explore"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { LanguageMenu() }
            }
        }
    }

    private var visibleCities: [City] {
        if !query.isEmpty { return searchResults(query).map { $0.0 } }
        if region == "All" { return DB.data.cities }
        return DB.data.cities.filter { $0.region == region }
    }

    private var regionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DB.regions, id: \.self) { r in
                    Button {
                        region = r
                    } label: {
                        Text(tr(r))
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(region == r ? .white : .zInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(region == r ? Color.zGreen : Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.zLine, lineWidth: region == r ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Saved

struct SavedView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Hero(title: tr("Saved"), subtitle: tr("Your favourite cities"), height: 120)
                    let saved = DB.data.cities.filter { store.favs.contains($0.id) }
                    if saved.isEmpty {
                        Card {
                            Text(tr("Nothing saved yet. Tap the heart on a city to keep it here."))
                                .font(.system(size: 14.5))
                                .foregroundColor(.zGrey)
                        }
                    }
                    ForEach(saved) { c in
                        NavigationLink { CityView(city: c) } label: { CityRow(city: c) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.zBG.ignoresSafeArea())
            .navigationTitle(tr("Saved"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Near me

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let mgr = CLLocationManager()
    @Published var location: CLLocation?
    @Published var denied = false

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        let status = mgr.authorizationStatus
        if status == .notDetermined {
            mgr.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            mgr.requestLocation()
        } else {
            denied = true
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            denied = true
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct NearMeView: View {
    @StateObject private var lm = LocationManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Hero(title: tr("Near me"), subtitle: tr("Cities closest to you"), height: 120)
                if let loc = lm.location {
                    let sorted = DB.data.cities.sorted {
                        loc.distance(from: CLLocation(latitude: $0.lat, longitude: $0.lon)) <
                        loc.distance(from: CLLocation(latitude: $1.lat, longitude: $1.lon))
                    }
                    ForEach(sorted.prefix(10)) { c in
                        let km = Int(loc.distance(from: CLLocation(latitude: c.lat, longitude: c.lon)) / 1000)
                        NavigationLink { CityView(city: c) } label: {
                            CityRow(city: c, hit: "\(km) km")
                        }
                        .buttonStyle(.plain)
                    }
                } else if lm.denied {
                    Card {
                        Text(tr("Location is off. Enable it in Settings to see the cities closest to you."))
                            .font(.system(size: 14.5))
                            .foregroundColor(.zGrey)
                    }
                } else {
                    Card {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(tr("Allow location"))
                                .font(.system(size: 14.5))
                                .foregroundColor(.zGrey)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.zBG.ignoresSafeArea())
        .navigationTitle(tr("Near me"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { lm.request() }
    }
}

// MARK: - Morocco map

struct CityMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.8, longitude: -6.5),
        span: MKCoordinateSpan(latitudeDelta: 7.5, longitudeDelta: 7.5))

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: DB.data.cities) { c in
            MapAnnotation(coordinate: c.coordinate) {
                NavigationLink { CityView(city: c) } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.zTerra)
                        Text(c.name)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.zInk)
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(tr("Morocco map"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

import Foundation
import CoreLocation

// MARK: - Data models (mirror assets/data.json)

struct Sight: Codable, Identifiable {
    let n: String
    let note: String
    let tag: String
    let min: Int
    let p: Int
    let v: Bool
    var id: String { n }
}

struct City: Codable, Identifiable {
    let id: String
    let name: String
    let ar: String
    let region: String
    let lat: Double
    let lon: Double
    let wv: String
    let tagline: String
    let days: Int
    let best: String
    let sights: [Sight]
    let stay: [String]
    let food: [String]
    let scams: [String]
    let transport: String
    let daytrips: [String]
    let wvsrc: String

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }
}

struct Price: Codable, Identifiable {
    let k: String
    let v: String
    let lvl: String
    let src: String
    var id: String { k }
}

struct ScamItem: Codable, Identifiable {
    let t: String
    let d: String
    var id: String { t }
}

struct General: Codable {
    let prices: [Price]
    let scams: [ScamItem]
    let phrases: [[String]]
    let tips: [String]
    let sources: [[String]]
}

struct AppData: Codable {
    let cities: [City]
    let general: General
    let built: String
}

struct Credit: Codable {
    let a: String
    let l: String
    let f: String
}

struct Content: Codable {
    let pages: [String: [[String]]]
    let emergency: [[String]]
    let welcome: [String]
    let activities: [[String]]
    let firstDay: [String]
    let quiz: [[String]]
    let packing: [String]
    let itineraries: [[String]]
    let unesco: [[String]]
    let routes: [[String]]
    let homeCards: [String]
}

enum DB {
    static let data: AppData = load("data")
    static let content: Content = load("content")
    static let credits: [String: Credit] = load("credits")

    static let regions = ["All", "North", "Atlantic Coast", "Center", "South", "Atlas"]
    static let topIds = ["marrakech", "fes", "chefchaouen", "essaouira", "merzouga", "casablanca", "rabat", "tangier"]

    private static func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let d = try? Data(contentsOf: url),
              let obj = try? JSONDecoder().decode(T.self, from: d) else {
            fatalError("Missing or invalid resource: \(name).json")
        }
        return obj
    }
}

// MARK: - Shared UI components

import SwiftUI

func bundleImage(_ id: String) -> UIImage? {
    guard let url = Bundle.main.url(forResource: id, withExtension: "jpg") else { return nil }
    return UIImage(contentsOfFile: url.path)
}

struct Hero: View {
    let title: String
    var subtitle: String = ""
    var imageId: String? = nil
    var height: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageId = imageId, let ui = bundleImage(imageId) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.05)],
                               startPoint: .bottom, endPoint: .top)
            } else {
                LinearGradient(colors: [.zDark, .zGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zLine, lineWidth: 1))
            .padding(.horizontal, 16)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(tr(text))
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.zInk)
            .padding(.horizontal, 20)
            .padding(.top, 6)
    }
}

struct BulletRow: View {
    let text: String
    var icon: String = "circle.fill"
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundColor(.zGold)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.zInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct Chip: View {
    let text: String
    var tint: Color = .zGreen
    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct CityImage: View {
    let id: String
    var body: some View {
        if let ui = bundleImage(id) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            LinearGradient(colors: [.zGreen, .zGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

func mapsURL(query: String) -> URL? {
    var c = URLComponents(string: "https://maps.apple.com/")!
    c.queryItems = [URLQueryItem(name: "q", value: query)]
    return c.url
}

func mapsURL(lat: Double, lon: Double, label: String) -> URL? {
    var c = URLComponents(string: "https://maps.apple.com/")!
    c.queryItems = [URLQueryItem(name: "ll", value: "\(lat),\(lon)"), URLQueryItem(name: "q", value: label)]
    return c.url
}

import SwiftUI
import MapKit

// MARK: - Biblical Map View

struct BiblicalMapView: View {
    var filterLocationId: String? = nil
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int

    var initialLatitude: Double = 31.5
    var initialLongitude: Double = 35.5
    var initialSpan: Double = 8.0

    @EnvironmentObject var encyclopediaService: EncyclopediaService

    @State private var selectedLocation: BiblicalLocation?

    private var displayLocations: [BiblicalLocation] {
        if let filterId = filterLocationId {
            return encyclopediaService.locations.filter { $0.id == filterId }
        }
        return encyclopediaService.locations
    }

    var body: some View {
        BiblicalMKMapView(
            locations: displayLocations,
            initialLatitude: initialLatitude,
            initialLongitude: initialLongitude,
            initialSpan: initialSpan,
            onLocationSelected: { location in
                selectedLocation = location
            }
        )
        .sheet(item: $selectedLocation) { location in
            MapLocationSheet(
                location: location,
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab
            )
            .environmentObject(encyclopediaService)
            .presentationDetents([.medium])
        }
    }
}

// MARK: - MKMapView Wrapper

private struct BiblicalMKMapView: UIViewRepresentable {
    let locations: [BiblicalLocation]
    let initialLatitude: Double
    let initialLongitude: Double
    let initialSpan: Double
    let onLocationSelected: (BiblicalLocation) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLocationSelected: onLocationSelected)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: initialLatitude, longitude: initialLongitude),
            span: MKCoordinateSpan(latitudeDelta: initialSpan, longitudeDelta: initialSpan)
        )
        mapView.setRegion(region, animated: false)

        addAnnotations(to: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.onLocationSelected = onLocationSelected
        context.coordinator.locationMap = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })

        let existingIds = Set(mapView.annotations.compactMap { ($0 as? LocationAnnotation)?.locationId })
        let newIds = Set(locations.map(\.id))

        if existingIds != newIds {
            mapView.removeAnnotations(mapView.annotations)
            addAnnotations(to: mapView)
        }
    }

    private func addAnnotations(to mapView: MKMapView) {
        for location in locations {
            let annotation = LocationAnnotation(location: location)
            mapView.addAnnotation(annotation)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        var onLocationSelected: (BiblicalLocation) -> Void
        var locationMap: [String: BiblicalLocation] = [:]

        init(onLocationSelected: @escaping (BiblicalLocation) -> Void) {
            self.onLocationSelected = onLocationSelected
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let locationAnnotation = annotation as? LocationAnnotation else { return nil }

            let identifier = "BiblicalPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.annotation = annotation
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            view.markerTintColor = pinUIColor(for: locationAnnotation.category)
            view.glyphImage = UIImage(systemName: pinIcon(for: locationAnnotation.category))

            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let locationAnnotation = view.annotation as? LocationAnnotation,
                  let location = locationMap[locationAnnotation.locationId] else { return }
            onLocationSelected(location)
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
            // Just show callout, don't auto-navigate
        }

        private func pinIcon(for category: String) -> String {
            switch category {
            case "city": return "building.2.fill"
            case "region": return "map.fill"
            case "mountain": return "mountain.2.fill"
            case "river", "water": return "water.waves"
            case "island": return "leaf.fill"
            case "landmark": return "mappin"
            default: return "mappin.and.ellipse"
            }
        }

        private func pinUIColor(for category: String) -> UIColor {
            switch category {
            case "city": return UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
            case "region": return .systemGreen
            case "mountain": return .systemGray
            case "river", "water": return .systemBlue
            case "island": return .systemTeal
            case "landmark": return .systemOrange
            default: return .systemRed
            }
        }
    }
}

// MARK: - Location Annotation

private class LocationAnnotation: NSObject, MKAnnotation {
    let locationId: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(location: BiblicalLocation) {
        self.locationId = location.id
        self.category = location.category
        self.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.title = location.name
        self.subtitle = location.description
    }
}

// MARK: - Map Location Sheet

struct MapLocationSheet: View {
    let location: BiblicalLocation
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int

    @EnvironmentObject var encyclopediaService: EncyclopediaService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Name and category
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text(location.name)
                            .font(.title2.bold())
                    }
                    .padding(.horizontal)

                    // Description
                    Text(location.description)
                        .font(.body)
                        .padding(.horizontal)

                    // Key events
                    if !location.keyEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Evenimente cheie")
                                .font(.subheadline.bold())

                            ForEach(location.keyEvents, id: \.self) { event in
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    Text(event)
                                        .font(.callout)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Link to encyclopedia
                    if let encId = location.encyclopediaId,
                       let entry = encyclopediaService.entry(byId: encId) {
                        Divider()
                        NavigationLink(value: entry) {
                            HStack {
                                Image(systemName: "text.book.closed.fill")
                                    .foregroundStyle(.accent)
                                Text("Deschide \u{00EE}n enciclopedie")
                                    .font(.callout)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gata") { dismiss() }
                }
            }
        }
    }
}

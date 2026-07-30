import SwiftUI
import MapKit

/// Native map of the joints. Pins are ember for unvisited, green for visited;
/// tapping a pin opens the detail sheet.
struct JointMapView: View {
    @Environment(PassportStore.self) private var passport
    let joints: [Joint]
    let onSelect: (Joint) -> Void

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 29.76, longitude: -95.42), // Houston
            span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)))

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(joints.filter { $0.coordinate != nil }) { joint in
                Annotation(joint.name, coordinate: joint.coordinate!) {
                    Button { onSelect(joint) } label: {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(passport.isVisited(joint.id) ? Theme.good : Theme.ember,
                                        in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .tint(Theme.ember)
    }
}

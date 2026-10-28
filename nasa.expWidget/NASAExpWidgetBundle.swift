import SwiftUI
import WidgetKit

@main
struct NASAExpWidgetBundle: WidgetBundle {
    var body: some Widget {
        APODWidget()
        RoversWidget()
        EPICWidget()
    }
}

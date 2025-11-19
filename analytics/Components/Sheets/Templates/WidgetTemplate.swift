import SwiftUI

struct WidgetTemplate {
    let type: WidgetType
    let title: String
    let aggregationLabel: String
    let aggregationValue: String
    let filterButtonLabel: String
    let content: () -> AnyView
}

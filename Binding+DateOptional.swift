import SwiftUI

extension Binding where Value == Date {
    /// Projects a Binding<Date?> to a Binding<Date> by providing a default value when the source is nil.
    /// - Parameters:
    ///   - source: The optional Date binding to project from.
    ///   - default: A default Date value used when `source` is nil. Defaults to `Date()`.
    /// - Returns: A non-optional Date binding that writes back into the optional source.
    static func fromOptional(_ source: Binding<Date?>, default defaultValue: @autoclosure @escaping () -> Date = Date()) -> Binding<Date> {
        Binding<Date>(
            get: { source.wrappedValue ?? defaultValue() },
            set: { source.wrappedValue = $0 }
        )
    }
}

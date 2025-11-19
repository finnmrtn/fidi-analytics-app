#if false
// NOTE:
// These types appear to be defined elsewhere in the project. To avoid
// "Invalid redeclaration" and ambiguous type lookup errors, this file's
// duplicate definitions are disabled. If this file was the intended source
// of truth, remove the other duplicates and re-enable by changing `#if false`
// to `#if true` or by deleting the other definitions.

import Foundation

struct StackedSeriesPoint {
    let value: Double
    let category: String
}

struct StackedSeriesPart {
    let points: [StackedSeriesPoint]
    let name: String
}

#endif // Duplicate definitions disabled to avoid redeclaration conflicts

import Foundation
import Observation

@Observable
final class SharedSelectionStore {
    var selectedNetwork: Network = .moonbeam
    var selectedAggregation: Aggregation = .month // default to 1M; adjust as needed
    var startDate: Date? = nil
    var endDate: Date? = nil
}

import Foundation

enum WidgetType: String, Identifiable, CaseIterable {
    case transactions
    case uaw
    case gasFees
    case txFees

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transactions:
            return "Transactions"
        case .uaw:
            return "Unique Active Wallets"
        case .gasFees:
            return "Gas Fees"
        case .txFees:
            return "Transaction Fees"
        }
    }
}

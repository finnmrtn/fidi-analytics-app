import SwiftUI

public enum ChartTheme {
    // Transaction Fees color order (ranked 1..10)
    public static let transactionFeesColors: [Color] = [
        Color("GraphColor2", bundle: .main),
        Color("GraphColor6", bundle: .main),
        Color("GraphColor7", bundle: .main),
        Color("GraphColor8", bundle: .main),
        Color("GraphColor4", bundle: .main),
        Color("GraphColor3", bundle: .main),
        Color("GraphColor1", bundle: .main),
        Color("GraphColor9", bundle: .main),
        Color("GraphColor5", bundle: .main),
        Color("GraphColor10", bundle: .main)
    ]

    // Gas Fees bar order (ranked 1..10) — mirrors your spec in GasFeesSheet
    public static let gasFeesColors: [Color] = [
        Color("GraphColor2", bundle: .main),
        Color("GraphColor8", bundle: .main),
        Color("GraphColor7", bundle: .main),
        Color("GraphColor8", bundle: .main),
        Color("GraphColor4", bundle: .main),
        Color("GraphColor3", bundle: .main),
        Color("GraphColor1", bundle: .main),
        Color("GraphColor9", bundle: .main),
        Color("GraphColor5", bundle: .main),
        Color("GraphColor10", bundle: .main)
    ]

    // Default palette for stacked bar charts
    public static let stackedDefaultColors: [Color] = [
        Color("GraphColor2", bundle: .main),
        Color("GraphColor6", bundle: .main),
        Color("GraphColor7", bundle: .main),
        Color("GraphColor8", bundle: .main),
        Color("GraphColor4", bundle: .main),
        Color("GraphColor3", bundle: .main),
        Color("GraphColor1", bundle: .main),
        Color("GraphColor9", bundle: .main),
        Color("GraphColor5", bundle: .main),
        Color("GraphColor10", bundle: .main)
    ]

    // Transactions stacked chart colors (can diverge from default later)
    public static let transactionsColors: [Color] = stackedDefaultColors
}

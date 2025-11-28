//
//  RankedChart.swift
//  analytics
//
//  Created by Finn Garrels on 24.11.25.
//

import SwiftUI

struct RankedChart: View {
    let dapps: [(name: String, gasFees: Double)]

    private let palette: [Color] = [
        Color("GraphColor2"),      // Blue
        Color("GraphColor5"),      // Yellow
        Color("GraphColor6"),      // Orange
        Color("GraphColor7"),      // Red
        Color("GraphColor4"),      // Pink
        Color("GraphColor3"),      // Purple
        Color("GraphColor1"),      // Green
        Color("GraphColor8"),      // Coral
        Color("GraphColor9"),      // Gray
        Color("GraphColor10")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(dapps.enumerated()), id: \.offset) { index, item in
                let barColor = palette.indices.contains(index) ? palette[index] : palette[index % palette.count]
                HorizontalBarRow(
                    name: item.name,
                    value: item.gasFees,
                    color: barColor,
                    maxValue: dapps.map { $0.gasFees }.max() ?? 1
                )
            }
        }
    }
}

struct HorizontalBarRow: View {
    let name: String
    let value: Double
    let color: Color
    let maxValue: Double

    private var barWidthRatio: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue)
    }

    private var isSmallBar: Bool {
        return barWidthRatio < 0.35
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.shade)
                    .frame(height: 48)

                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 3)
                            .cornerRadius(4)

                        if !isSmallBar {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, isSmallBar ? 0 : 8)
                    .frame(width: geometry.size.width * barWidthRatio, alignment: .leading)
                    .frame(height: 48)
                    .background(color)
                    .cornerRadius(16)

                    if isSmallBar {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                                .frame(width: 3)
                                .cornerRadius(4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.41, green: 0.41, blue: 0.41))
                                    .lineLimit(1)

                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.backing)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white)
                        .cornerRadius(8)
                        .padding(.leading, 10)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 48)
        .cornerRadius(4)
    }
}

#Preview("Gas Fees Ranked Chart") {
    let mockData: [(name: String, gasFees: Double)] = [
        ("Project A", 3_343_000),
        ("Project B", 184_000),
        ("Project C", 45_000),
        ("Project D", 12_000)
    ]
    VStack(alignment: .leading) {
        RankedChart(dapps: mockData)
            .padding(16)
    }
}

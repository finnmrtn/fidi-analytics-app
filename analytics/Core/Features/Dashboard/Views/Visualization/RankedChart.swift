//
//  RankedChart.swift
//  analytics
//
//  Created by Finn Garrels on 24.11.25.
//

import SwiftUI

struct LeftCapsuleShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let height = rect.height
        let width = rect.width
        
        path.move(to: CGPoint(x: radius, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: radius, y: height))
        path.addArc(center: CGPoint(x: radius, y: height / 2), radius: radius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: -90), clockwise: true)
        path.closeSubpath()
        
        return path
    }
}

private struct RoundedCornersShape: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: tl, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()

        return path
    }
}

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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.shade)
                    .frame(height: 48)

                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        if !isSmallBar {
                            Capsule()
                                .fill(.white)
                                .frame(width: 3, height: 32)
                        }

                        if !isSmallBar {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.system(size: 12))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, isSmallBar ? 0 : 8)
                    .frame(width: geometry.size.width * barWidthRatio, alignment: .leading)
                    .frame(height: 48)
                    .background(
                        ZStack(alignment: .leading) {
                            // Backing: full width, masked to pill
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.shade)
                                .frame(height: 48)

                            // Data bar: fills proportionally from the left
                            Rectangle()
                                .fill(color)
                                .frame(width: geometry.size.width * barWidthRatio, height: 48)
                        }
                        .mask(
                            RoundedCornersShape(
                                tl: 12,
                                tr: 12,
                                bl: 12,
                                br: 12
                            )
                        )
                    )

                    if isSmallBar {
                        HStack(spacing: 6) {
                            Capsule()
                                .fill(Color.shade)
                                .frame(width: 3, height: 32)
                                .padding(4)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.system(size: 12))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.subtext)
                                    .lineLimit(2)

                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.black)
                            }.padding(.trailing, 8).padding(.vertical, 4)
                        }
                        .background(Color.backing)
                        .cornerRadius(8)
                        .padding(4)
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


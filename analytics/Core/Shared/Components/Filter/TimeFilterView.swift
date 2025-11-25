import SwiftUI

struct TimeFilterView: View {
    @Bindable var viewModel: TimeFilterViewModel
    @Binding var selectedAggregation: Aggregation
    @Binding var chartStartDate: Date?
    @Binding var chartEndDate: Date?
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showingRangePicker = false
    @State private var tempSelection: Date = Date()
    @State private var selectedDetent: PresentationDetent = .medium
    var globalRangeProvider: GlobalDateRangeProvider? = nil

    init(viewModel: TimeFilterViewModel, selectedAggregation: Binding<Aggregation>, chartStartDate: Binding<Date?>, chartEndDate: Binding<Date?>, globalRangeProvider: GlobalDateRangeProvider? = nil) {
        self._viewModel = Bindable(wrappedValue: viewModel)
        self._selectedAggregation = selectedAggregation
        self._chartStartDate = chartStartDate
        self._chartEndDate = chartEndDate
        self.globalRangeProvider = globalRangeProvider
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                // Aggregation
                VStack {
                    Picker("Aggregation", selection: $selectedAggregation) {
                        ForEach(Aggregation.allCases) { agg in
                            Text(agg.rawValue).tag(agg)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .padding(.top, 4)

                VStack(spacing: 12) {
                    // Quick scales
                    let quickScales = TimeFilterViewModel.TimeScale.allCases.filter { scale in
                        switch scale {
                        case .q1, .q2, .q3, .q4:
                            return false
                        default:
                            return true
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(quickScales) { scale in
                            Button {
                                viewModel.setScale(scale)
                                if scale == .all, let provider = globalRangeProvider {
                                    Task {
                                        if let range = await provider.globalDateRange() {
                                            chartStartDate = range.start
                                            chartEndDate = range.end
                                        } else {
                                            // Fallback to the view model's computed range if provider returns nil
                                            chartStartDate = viewModel.startDate
                                            chartEndDate = viewModel.endDate
                                        }
                                    }
                                } else {
                                    chartStartDate = viewModel.startDate
                                    chartEndDate = viewModel.endDate
                                }
                            } label: {
                                Text(scale.rawValue)
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        Group {
                                            if viewModel.selectedScale == scale {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(Color("BrandColor"))
                                            } else {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    )
                                    .foregroundStyle(viewModel.selectedScale == scale ? .white : .primary)
                            }
                        }
                    }
                    .padding(.top, 0)

                    // Date range picker
                    VStack(spacing: 12) {
                        Text("Select Date Range")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            // Liquid Glass styled button whose text reflects current selection or preset
                            Button {
                                tempSelection = viewModel.startDate
                                showingRangePicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.headline)
                                    if chartStartDate == nil && chartEndDate == nil {
                                        Text("Select Time Range")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    } else {
                                        Text(longRangeOrPresetDescription(start: chartStartDate, end: chartEndDate))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose date range")

                            Spacer()

                            if chartStartDate != nil || chartEndDate != nil {
                                Button {
                                    chartStartDate = nil
                                    chartEndDate = nil
                                    // Reset to the current preset scale values so UI shows the preselect instead of nil
                                    viewModel.setScale(viewModel.selectedScale)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.medium)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("Clear custom date range")
                                }
                            }
                        }

                        // Removed descriptive line under the button as per instructions

                    }
                    .padding(.top, 2)

                    // Preset buttons with quarter and year labels
                    HStack(spacing: 10) {
                        let year = Calendar.current.component(.year, from: Date())
                        let shortYear = String(year % 100)
                        let quarters: [(label: String, scale: TimeFilterViewModel.TimeScale)] = [
                            ("Q1 '\(shortYear)", .q1),
                            ("Q2 '\(shortYear)", .q2),
                            ("Q3 '\(shortYear)", .q3),
                            ("Q4 '\(shortYear)", .q4)
                        ]
                        ForEach(quarters, id: \.label) { item in
                            Button(item.label) {
                                // Treat as preset: set scale and compute internal dates, but keep external selection nil
                                viewModel.setScale(item.scale)
                                chartStartDate = nil
                                chartEndDate = nil
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(viewModel.selectedScale == item.scale ? Color("BrandColor").opacity(0.12) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(viewModel.selectedScale == item.scale ? Color("BrandColor") : .primary)
                        }
                    }

                }
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
        .fullScreenCover(isPresented: $showingRangePicker) {
            ZStack {
                // Blurred background with subtle white overlay
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    Color.white.opacity(0.009) // 0.9%
                        .ignoresSafeArea()
                }
                .onTapGesture { withAnimation(.easeInOut) { showingRangePicker = false } }

                // Edge-to-edge content container
                VStack(spacing: 0) {
                    // Custom top bar
                    HStack {
                        Button("Abbrechen") {
                            withAnimation(.easeInOut) { showingRangePicker = false }
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("BrandColor"))

                        Spacer()
                        Text("Zeitraum wählen")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()

                        Button("Fertig") {
                            // Will be enabled by RangePickerSheet as soon as end picked
                            withAnimation(.easeInOut) { showingRangePicker = false }
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .disabled(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    // The actual range picker content
                    RangePickerSheet(
                        initialStart: chartStartDate,
                        initialEnd: chartEndDate,
                        onDone: { newStart, newEnd in
                            viewModel.setCustomRange(start: newStart, end: newEnd)
                            chartStartDate = viewModel.startDate
                            chartEndDate = viewModel.endDate
                            withAnimation(.easeInOut) { showingRangePicker = false }
                        },
                        onCancel: {
                            withAnimation(.easeInOut) { showingRangePicker = false }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Spacer(minLength: 0)
                }
            }
            .presentationBackground(.clear)
            .presentationDragIndicator(.hidden)
        }
    }

    private func shortRangeLabel(start: Date?, end: Date?) -> String {
        guard let start, let end else { return "Custom…" }
        let cal = Calendar.current
        let sameMonth = cal.component(.month, from: start) == cal.component(.month, from: end)
        let sameYear = cal.component(.year, from: start) == cal.component(.year, from: end)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        let monthYearFormatter = DateFormatter()
        monthYearFormatter.dateFormat = "MMM ''yy" // e.g., Nov '25

        if sameMonth && sameYear {
            let startDay = dayFormatter.string(from: start)
            let endDay = dayFormatter.string(from: end)
            let monthYear = monthYearFormatter.string(from: end)
            return "\(startDay) - \(endDay) \(monthYear)"
        } else if sameYear {
            // Different months within same year: 28 Sep - 02 Nov '25
            let startFmt = DateFormatter(); startFmt.dateFormat = "d MMM"
            let endFmt = DateFormatter(); endFmt.dateFormat = "d MMM ''yy"
            return "\(startFmt.string(from: start)) - \(endFmt.string(from: end))"
        } else {
            // Different years: 28 Dec '24 - 02 Jan '25
            let startFmt = DateFormatter(); startFmt.dateFormat = "d MMM ''yy"
            let endFmt = startFmt
            return "\(startFmt.string(from: start)) - \(endFmt.string(from: end))"
        }
    }

    private func shortRangeOrPresetLabel(start: Date?, end: Date?) -> String {
        if let start, let end {
            // Show number of days as "Past nD"
            let cal = Calendar.current
            let s = cal.startOfDay(for: start)
            let e = cal.startOfDay(for: end)
            let days = max(1, (cal.dateComponents([.day], from: s, to: e).day ?? 0) + 1)
            return "Past \(days)D"
        }
        // Fallback to preset scale label when no custom range is set
        return viewModel.presetLabel()
    }

    private func longRangeOrPresetDescription(start: Date?, end: Date?) -> String {
        if let start, let end {
            let f = DateFormatter()
            f.locale = Locale.current
            f.dateFormat = "d. MMM yyyy"
            let s = f.string(from: start)
            let e = f.string(from: end)
            return "\(s) – \(e)"
        }
        // No custom range -> show nothing under the button
        return ""
    }
}

private struct RangePickerSheet: View {
    let initialStart: Date?
    let initialEnd: Date?
    var onDone: (Date, Date) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isPickingEnd: Bool = false
    @State private var tempSelection: Date = Calendar.current.startOfDay(for: Date())

    init(initialStart: Date?, initialEnd: Date?, onDone: @escaping (Date, Date) -> Void, onCancel: @escaping () -> Void) {
        self.initialStart = initialStart
        self.initialEnd = initialEnd
        self.onDone = onDone
        self.onCancel = onCancel
        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer().frame(height: 8)

            HStack {
                Label(startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Start", systemImage: "calendar")
                Text("–")
                Label(endDate?.formatted(date: .abbreviated, time: .omitted) ?? "End", systemImage: "calendar")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)

            DatePicker(
                "",
                selection: Binding(
                    get: { tempSelection },
                    set: { newValue in
                        let day = Calendar.current.startOfDay(for: newValue)
                        if isPickingEnd == false {
                            startDate = day
                            endDate = nil
                            tempSelection = day
                            isPickingEnd = true
                        } else {
                            if let start = startDate {
                                if day < start {
                                    endDate = start
                                    startDate = day
                                } else {
                                    endDate = day
                                }
                                tempSelection = day
                                if let s = startDate, let e = endDate {
                                    onDone(s, e)
                                }
                            } else {
                                startDate = day
                                isPickingEnd = true
                                tempSelection = day
                            }
                        }
                    }
                ),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .frame(minHeight: 380)

            Spacer(minLength: 0)
        }
        .padding(.top, 0)
        .padding(.bottom, 4)
    }
}


import SwiftUI

struct DateRangePickerDemo: View {
    @State private var startDate: Date?
    @State private var endDate: Date?

    var body: some View {
        VStack {
            presetsSection
            if let start = startDate, let end = endDate {
                Text(longRangeOrPresetDescription(start: start, end: end))
            } else {
                Text("All time")
            }
        }
    }

    private var presetsSection: some View {
        Section(header: Text("Presets")) {
            presetButton(start: Calendar.current.date(byAdding: .day, value: -7, to: Date()), end: Date())
            presetButton(start: Calendar.current.date(byAdding: .month, value: -1, to: Date()), end: Date())
            presetButton(start: Calendar.current.date(byAdding: .month, value: -3, to: Date()), end: Date())
            presetButton(start: Calendar.current.date(byAdding: .year, value: -1, to: Date()), end: Date())
            presetButton(start: nil, end: nil)
        }
    }

    private func presetButton(start: Date?, end: Date?) -> some View {
        Button(action: {
            startDate = start
            endDate = end
        }) {
            Text(shortRangeOrPresetLabel(start: start, end: end))
        }
    }

    private func shortRangeOrPresetLabel(start: Date?, end: Date?) -> String {
        if let start = start, let end = end {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            let yStart = Calendar.current.component(.year, from: start)
            let yEnd = Calendar.current.component(.year, from: end)
            if yStart == yEnd {
                return "\(f.string(from: start)) – \(f.string(from: end))"
            } else {
                let fy = DateFormatter(); fy.dateFormat = "MMM d, yyyy"
                return "\(fy.string(from: start)) – \(fy.string(from: end))"
            }
        }
        return "All"
    }

    private func longRangeOrPresetDescription(start: Date?, end: Date?) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        if let start = start, let end = end {
            return "\(f.string(from: start)) – \(f.string(from: end))"
        } else {
            return "All time"
        }
    }
}



#Preview("TimeFilterView") {
    // Lightweight mock view model. If TimeFilterViewModel has a concrete init, replace with real initializer.
    // This mock assumes an init that takes an initial scale; adjust as needed for your project.
    let vm = TimeFilterViewModel()

    @State var aggregation: Aggregation = .sum
    @State var startDate: Date? = nil
    @State var endDate: Date? = nil

    TimeFilterView(
        viewModel: vm,
        selectedAggregation: Binding(get: { aggregation }, set: { aggregation = $0 }),
        chartStartDate: Binding(get: { startDate }, set: { startDate = $0 }),
        chartEndDate: Binding(get: { endDate }, set: { endDate = $0 }),
        globalRangeProvider: nil
    )
    .padding()
}


//
//  TimeFilterSheet.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import SwiftUI

struct TimeFilterSheet: View {
    @Bindable var viewModel: TimeFilterViewModel
    @Binding var selectedAggregation: Aggregation
    @Binding var chartStartDate: Date?
    @Binding var chartEndDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showingRangePicker = false
    @State private var tempSelection: Date = Date()
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        
        // --- Aggregation & Range (moved from AnalyticsView) ---
        VStack(spacing: 10) {
            // Aggregation on Liquid Glass
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

        }
        .padding(.top, 4)
        
        VStack(spacing: 12) {
    
            // --- Buttons: 1H, 1D, 1W, 1M, 1Q, 1Y, YTD, ALL ---
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(TimeFilterViewModel.TimeScale.allCases) { scale in
                    Button {
                        viewModel.setScale(scale)
                        chartStartDate = viewModel.startDate
                        chartEndDate = viewModel.endDate
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

            // --- Date Range Picker ---
            VStack(spacing: 12) {
                // Optional: a compact range slider placeholder (aligns with mock)
                // You can replace this with a real range slider later.
                //Spacer(minLength: 0)

                Text("Select Date Range")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button {
                        // Beim Öffnen: Start der Range-Auswahl vorbereiten
                        tempSelection = viewModel.startDate
                        showingRangePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.startDate.formatted(date: .abbreviated, time: .omitted))
                            Text("–")
                                .foregroundStyle(.secondary)
                            Text(viewModel.endDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.gray.opacity(0.12))
                        )
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Date range")
                }
                .sheet(isPresented: $showingRangePicker) {
                    RangePickerSheet(
                        initialStart: viewModel.startDate,
                        initialEnd: viewModel.endDate
                    ) { newStart, newEnd in
                        viewModel.setCustomRange(start: newStart, end: newEnd)
                        chartStartDate = viewModel.startDate
                        chartEndDate = viewModel.endDate
                        showingRangePicker = false
                    } onCancel: {
                        showingRangePicker = false
                    }
                    .presentationDetents([.medium, .large], selection: $selectedDetent)
                }
            }
            .padding(.top, 2)

            // --- Preset Buttons ---
            HStack(spacing: 10) {
                ForEach(["Q1", "Q2", "Q3", "Q4"], id: \.self) { preset in
                    Button(preset) {
                        // TODO: Apply preset logic later
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(Color("BrandColor"))
                }
            }

    
          
        }

        .padding(.top, 4)
        .padding(.bottom, 8)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
    }
}

private struct RangePickerSheet: View {
    let initialStart: Date
    let initialEnd: Date
    var onDone: (Date, Date) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isPickingEnd: Bool = false
    @State private var tempSelection: Date

    init(initialStart: Date, initialEnd: Date, onDone: @escaping (Date, Date) -> Void, onCancel: @escaping () -> Void) {
        self.initialStart = initialStart
        self.initialEnd = initialEnd
        self.onDone = onDone
        self.onCancel = onCancel
        _startDate = State(initialValue: Calendar.current.startOfDay(for: initialStart))
        _endDate = State(initialValue: Calendar.current.startOfDay(for: initialEnd))
        _tempSelection = State(initialValue: Calendar.current.startOfDay(for: initialStart))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 6) {
                Spacer().frame(height: 8)

                HStack {
                    Label(startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Text("–")
                    Label(endDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
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
                                endDate = day
                                tempSelection = day
                                isPickingEnd = true
                            } else {
                                if day < startDate {
                                    endDate = startDate
                                    startDate = day
                                } else {
                                    endDate = day
                                }
                                tempSelection = day
                                onDone(startDate, endDate)
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
            .navigationTitle("Zeitraum wählen")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onDone(startDate, endDate)
                    }
                    .disabled(!isPickingEnd)
                }
            }
        }
    }
}


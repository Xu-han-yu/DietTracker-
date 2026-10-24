//
//  ExerciseItemEditSheet.swift
//  DietTracker
//
//  编辑**已保存**的一条运动：名称 / 时长 / 强度 / 消耗（可手动修正）。
//
//  ⚠️ 保留估算快照：这里改的是 manualKcal，不动 estimatedKcal / metValue / weightKgAtEstimate。
//     也就是说「当时 MET 算出来多少」这条证据永久留着，复核时能对得上。
//     用户的修正值优先级更高（见 ExerciseItem.effectiveKcal），但不会销毁原估算。
//
//  ⚠️ 时长改了**不重新估算**：用户手动填了 kcal 之后，再改时长系统不会覆盖他的数字。
//     这是刻意的 —— 让用户掌握最终解释权。
//

import SwiftUI
import SwiftData

struct ExerciseItemEditSheet: View {

    @Bindable var item: ExerciseItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    nameField

                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        Stepper(value: $item.minutes,
                                in: 0...ExerciseFallback.maxMinutes,
                                step: 5) {
                            Text("时长 \(Int(item.minutes.rounded())) 分钟")
                                .font(Tokens.Typography.body)
                                .monospacedDigit()
                        }
                        .dtMaxDynamicType()

                        Text("时长只影响记录，不会重算已修正的消耗值。")
                            .font(Tokens.Typography.overline)
                            .foregroundStyle(Tokens.Palette.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        Text("强度")
                            .font(Tokens.Typography.caption)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                        Picker("强度", selection: $item.intensity) {
                            ForEach(ExerciseIntensity.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    kcalCard

                    DTDisclaimer()
                }
                .dtScreenPadding()
                .padding(.vertical, Tokens.Space.md)
            }
            .dtScreenBackground()
            .navigationTitle("修改运动记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: 子视图

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("名称")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
            TextField("运动名称", text: $item.name)
                .font(Tokens.Typography.body)
                .padding(Tokens.Space.sm)
                .background(Tokens.Palette.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                .dtMaxDynamicType()
        }
    }

    private var kcalCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            DTSectionHeader(title: "消耗估算",
                            subtitle: "MET \(String(format: "%.1f", item.metValue)) × \(AnalysisFormat.kcal(item.weightKgAtEstimate)) kg",
                            trailing: item.isFallback ? "兜底估算" : nil)

            ExerciseKcalEditor(manualKcal: $item.manualKcal,
                               estimatedKcal: item.estimatedKcal)

            DTDivider()

            Text("估算公式给出的是群体平均值，个体差异很大。如果你有更准的来源（运动手环、跑步机读数），直接改这里的值。")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textTertiary)
        }
        .dtCard()
    }
}

#Preview("编辑运动条目") {
    ExerciseItemEditPreviewHost()
        .dtTheme(.default)
}

@MainActor
private struct ExerciseItemEditPreviewHost: View {
    private let context = try! SeedData.makePreviewContext()

    var body: some View {
        let item = ExerciseItem(name: "跑步",
                                matchedExerciseID: "running",
                                minutes: 30,
                                intensity: .moderate,
                                metValue: 11.0,
                                estimatedKcal: 385,
                                weightKgAtEstimate: 70)
        ExerciseItemEditSheet(item: item)
            .modelContext(context)
    }
}

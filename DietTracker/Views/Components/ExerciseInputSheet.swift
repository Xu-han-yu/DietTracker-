//
//  ExerciseInputSheet.swift
//  DietTracker
//
//  运动输入卡片：自然语言 → 解析预览（时长 / 强度可改）→ 保存。
//
//  ⚠️ 强度默认中等，用户可手动改低 / 中 / 高。
//     没匹配到具体运动时会用「中等强度一般运动」MET 兜底，
//     预览里必须明确标注，不能让用户以为是一个准确数字。
//

import SwiftUI
import SwiftData

struct ExerciseInputSheet: View {

    var dayIdentifier: String
    /// 估算用的体重。传 0 或未设置时用 ExerciseFallback.defaultWeightKg 兜底。
    var weightKg: Double
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var services

    @State private var rawText: String = ""
    @State private var drafts: [ExerciseDraft] = []
    @State private var hasParsed: Bool = false
    @State private var isSaving: Bool = false
    @State private var notice: String?

    private var writer: EntryWriter {
        EntryWriter(services: services, context: modelContext)
    }

    /// ⚠️ 这里必须用 effective 口径（手动值优先），否则「合计」会和单行显示对不上。
    private var totalKcal: Double {
        drafts.reduce(0) { sum, draft in
            let estimated = writer.estimate(draft: draft, weightKg: weightKg).kcal
            return sum + (draft.manualKcal ?? estimated)
        }
    }

    private var resolvedWeightText: String {
        weightKg > 0
            ? "按体重 \(AnalysisFormat.kcal(weightKg)) kg 估算"
            : "未设置体重，按 \(AnalysisFormat.kcal(ExerciseFallback.defaultWeightKg)) kg 估算"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    inputEditor
                    if hasParsed { previewSection }
                    if let notice {
                        Text(notice)
                            .font(Tokens.Typography.caption)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                    }
                    DTDisclaimer()
                }
                .dtScreenPadding()
                .padding(.vertical, Tokens.Space.md)
            }
            .dtScreenBackground()
            .navigationTitle("记一笔运动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text(isSaving ? "保存中…" : "保存")
                    }
                    .disabled(drafts.isEmpty || isSaving)
                }
            }
        }
    }

    // MARK: 子视图

    private var inputEditor: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            TextField("例如：跑步 30 分钟、力量训练 40 分钟", text: $rawText, axis: .vertical)
                .lineLimit(2...5)
                .font(Tokens.Typography.body)
                .foregroundStyle(Tokens.Palette.textPrimary)
                .padding(Tokens.Space.sm)
                .background(Tokens.Palette.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                .dtMaxDynamicType()

            Button { runParse() } label: { Text("解析") }
                .dtSecondaryButton()
                .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            DTSectionHeader(title: "识别结果",
                            subtitle: resolvedWeightText,
                            trailing: "合计 \(AnalysisFormat.kcal(totalKcal)) kcal")

            if drafts.isEmpty {
                Text("没能识别出运动。试试写成「跑步 30 分钟」这样的形式，或者直接写运动名再手动填时长。")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
            } else {
                ForEach(drafts.indices, id: \.self) { index in
                    draftRow(index: index, draft: drafts[index])
                    if index < drafts.count - 1 { DTDivider() }
                }
            }

            Text("消耗 = MET × 体重 kg × 小时数。这是按群体平均值推算的估算值，个体差异很大。")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textTertiary)
        }
        .dtCard()
    }

    private func draftRow(index: Int, draft: ExerciseDraft) -> some View {
        let estimate = writer.estimate(draft: draft, weightKg: weightKg)
        return VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                Text(draft.name)
                    .font(Tokens.Typography.subhead)
                    .foregroundStyle(Tokens.Palette.textPrimary)
                Spacer(minLength: Tokens.Space.xxs)
                Text("\(AnalysisFormat.kcal(draft.manualKcal ?? estimate.kcal)) kcal")
                    .dtNumber(Tokens.Typography.Number.small)
            }

            Stepper(value: $drafts[index].minutes,
                    in: 0...ExerciseFallback.maxMinutes,
                    step: 5) {
                Text("时长 \(Int(drafts[index].minutes.rounded())) 分钟")
                    .font(Tokens.Typography.caption)
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Palette.textSecondary)
            }
            .dtMaxDynamicType()

            Picker("强度", selection: $drafts[index].intensity) {
                ForEach(ExerciseIntensity.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("\(estimate.formulaText) ≈ \(AnalysisFormat.kcal(estimate.kcal)) kcal")
                .font(Tokens.Typography.overline)
                .monospacedDigit()
                .foregroundStyle(Tokens.Palette.textTertiary)

            ExerciseKcalEditor(manualKcal: $drafts[index].manualKcal,
                               estimatedKcal: estimate.kcal)

            if let caution = estimate.cautionText {
                Text(caution)
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 动作

    private func runParse() {
        drafts = writer.previewExercises(rawText: rawText)
        hasParsed = true
        notice = nil
    }

    @MainActor
    private func save() {
        isSaving = true
        defer { isSaving = false }

        let entry = writer.saveExercise(dayIdentifier: dayIdentifier,
                                        rawText: rawText,
                                        weightKg: weightKg,
                                        drafts: drafts)
        if entry == nil {
            notice = "没有可保存的内容，先点「解析」看看识别结果。"
            return
        }
        onSaved?()
        dismiss()
    }
}

#Preview("运动输入") {
    ExerciseInputPreviewHost()
        .dtTheme(.default)
}

/// 预览宿主：注入一个内存 ModelContext，否则点「解析」时会因为取不到 context 崩。
@MainActor
private struct ExerciseInputPreviewHost: View {
    private let context = try! SeedData.makePreviewContext()

    var body: some View {
        ExerciseInputSheet(dayIdentifier: DayIdentifier.today, weightKg: 70)
            .modelContext(context)
    }
}

// MARK: - 编辑已保存的运动条目

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

//
//  ExerciseKcalEditor.swift
//  DietTracker
//
//  运动消耗的「手动修正」编辑器。输入卡片（草稿）与历史条目（已落库）共用同一份 UI，
//  这样「为什么要改」「改了算什么」在两个入口的表现一致。
//
//  ⚠️ 为什么必须有这个：
//    MET 公式算的是群体平均值，个体差异极大 —— 同样「跑步 30 分钟」，
//    配速、坡度、体能都会让实际消耗差出一倍。用户自己的感受才是更准的数据源，
//    所以手动值**永远覆盖估算值**（见 ExerciseItem.effectiveKcal）。
//
//  ⚠️ 保留估算值：手动值存在 manualKcal，estimatedKcal 原样留着。
//    用户「恢复估算值」能立刻回到公式结果，历史也不会被一次性改写。
//

import SwiftUI

struct ExerciseKcalEditor: View {

    /// 手动填入的数值。nil 表示用估算值。
    @Binding var manualKcal: Double?
    /// MET 公式算出来的估算值
    var estimatedKcal: Double

    @State private var text: String = ""

    private var isManual: Bool { manualKcal != nil }

    private var effectiveKcal: Double { manualKcal ?? estimatedKcal }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                Text("消耗")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                Spacer(minLength: Tokens.Space.xxs)
                Text("\(AnalysisFormat.kcal(effectiveKcal)) kcal")
                    .dtNumber(Tokens.Typography.Number.small)
            }

            HStack(spacing: Tokens.Space.xs) {
                Text(verbatim: "估算 \(AnalysisFormat.kcal(estimatedKcal))")
                    .font(Tokens.Typography.overline)
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Palette.textTertiary)

                Spacer(minLength: Tokens.Space.xxs)

                TextField("手动改 kcal", text: $text)
                    .font(Tokens.Typography.body)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110)
                    .padding(.horizontal, Tokens.Space.xs)
                    .padding(.vertical, Tokens.Space.xxs)
                    .background(Tokens.Palette.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
                    .onChange(of: text) { _, newValue in apply(newValue) }

                Button("用估算值") { reset() }
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.accentText)
                    .disabled(!isManual)
            }

            if isManual {
                Text("已手动修正 —— 后续的能量计算与趋势都用这个数值")
                    .font(Tokens.Typography.overline)
                    .foregroundStyle(Tokens.Palette.accentText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { syncFromValue() }
        .onChange(of: manualKcal) { _, _ in syncFromValue() }
    }

    // MARK: 逻辑

    private func syncFromValue() {
        if let value = manualKcal {
            let formatted = String(format: "%.0f", value)
            if text != formatted { text = formatted }
        } else if !text.isEmpty {
            text = ""
        }
    }

    /// 输入即生效。非法输入按「未修正」处理，不弹报错 —— 这是正在输入的中间态。
    private func apply(_ raw: String) {
        let cleaned = Self.sanitized(raw)
        if cleaned != raw { text = cleaned }
        guard let value = Double(cleaned), value > 0 else {
            manualKcal = nil
            return
        }
        manualKcal = Swift.min(value, 10000)
    }

    private func reset() {
        text = ""
        manualKcal = nil
    }

    /// 只留数字和一个小数点。防止粘贴进来 "12k cal" 这种东西。
    static func sanitized(_ raw: String) -> String {
        var out = ""
        var seenDot = false
        for ch in raw {
            if ch.isNumber { out.append(ch) }
            else if ch == ".", !seenDot { seenDot = true; out.append(ch) }
            else if ch == "。" { continue }
        }
        return out
    }
}

#Preview("kcal 修正器") {
    ExerciseKcalEditorPreviewHost()
        .dtTheme(.default)
}

private struct ExerciseKcalEditorPreviewHost: View {
    @State private var manual: Double? = 320

    var body: some View {
        ExerciseKcalEditor(manualKcal: $manual, estimatedKcal: 280)
            .padding()
    }
}

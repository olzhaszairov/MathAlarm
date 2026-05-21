import SwiftUI
import PersonalColorDesignSystem

// MARK: - AlarmRingingView

/// 알람 울림 전체 화면. PGradientBackground + 시간 표시 + 정지/스누즈 버튼.
/// MVVM: View는 UI 선언만. 비즈니스 로직은 ViewModel로.
struct AlarmRingingView: View {
    @State private var viewModel: AlarmRingingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pThemeColors) private var theme

    init(
        alarm: Alarm,
        audioService: AudioService,
        volumeService: VolumeService,
        alarmStore: AlarmStore
    ) {
        _viewModel = State(initialValue: AlarmRingingViewModel(
            alarm: alarm,
            audioService: audioService,
            volumeService: volumeService,
            alarmStore: alarmStore,
            onStopHaptic: { HapticManager.notification(.success) },
            onSnoozeHaptic: { HapticManager.impact() },
            onWrongAnswerHaptic: { HapticManager.notification(.error) }
        ))
    }

    var body: some View {
        ZStack {
            PGradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // 현재 시간
                timeDisplay

                Spacer()
                    .frame(height: 24)

                // 알람 제목
                alarmTitleDisplay

                Spacer()

                // 버튼 영역
                buttonArea

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .task {
            await viewModel.startRinging()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Subviews

    private var timeDisplay: some View {
        Text(viewModel.currentTimeString)
            .font(.system(.largeTitle, design: .rounded, weight: .ultraLight))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Color.pTextPrimary)
            .accessibilityLabel(Text("alarm_ringing_current_time_a11y \(viewModel.currentTimeString)"))
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var alarmTitleDisplay: some View {
        Text(viewModel.alarm.displayTitle)
            .font(.title.weight(.semibold))
            .foregroundStyle(Color.pTextPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .accessibilityLabel(Text("alarm_ringing_alarm_title_a11y \(viewModel.alarm.displayTitle)"))
    }

    private var buttonArea: some View {
        @Bindable var vm = viewModel

        return VStack(spacing: 20) {
            mathStopSection(vm: vm)

            // 스누즈 버튼 (작은 캡슐형 아웃라인) — minWidth 200으로 상향 (SPEC §7.2F)
            Button {
                Task {
                    await viewModel.snoozeAlarm()
                    dismiss()
                }
            } label: {
                Text("alarm_ringing_snooze_button")
                    .font(.body.weight(.medium))
                    .foregroundStyle(theme.accentSecondary)
                    .frame(minWidth: 200, minHeight: 48)
                    .overlay(
                        Capsule()
                            .stroke(theme.accentSecondary, lineWidth: 1.5)
                    )
            }
            .accessibilityLabel(Text("alarm_ringing_snooze_a11y"))
            .accessibilityHint(Text("alarm_ringing_snooze_a11y_hint"))
        }
    }

    private func mathStopSection(vm: AlarmRingingViewModel) -> some View {
        MathStopChallengeView(
            challenge: vm.mathChallenge,
            answerInput: Binding(
                get: { vm.stopAnswerInput },
                set: { vm.stopAnswerInput = $0 }
            ),
            showError: vm.stopAnswerError,
            onClearError: { vm.clearStopAnswerError() },
            submitButtonTitle: "alarm_ringing_math_submit_button",
            submitAccessibilityLabel: "alarm_ringing_stop_a11y",
            submitAccessibilityHint: "alarm_ringing_stop_a11y_hint",
            onSubmit: {
                Task {
                    if await vm.submitStopAnswer() {
                        dismiss()
                    } else {
                        HapticManager.notification(.error)
                    }
                }
            }
        )
    }
}

// MARK: - MathStopChallengeView

/// Общий UI: уравнение + поле ответа + кнопка (экран звонка и выключение в списке).
struct MathStopChallengeView: View {
    let challenge: MathStopChallenge
    @Binding var answerInput: String
    let showError: Bool
    let onClearError: () -> Void
    let submitButtonTitle: LocalizedStringKey
    var submitAccessibilityLabel: LocalizedStringKey?
    var submitAccessibilityHint: LocalizedStringKey?
    let onSubmit: () -> Void

    @Environment(\.pThemeColors) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Text(challenge.equationText)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.pTextPrimary)
                .accessibilityLabel(
                    Text("alarm_ringing_math_equation_a11y \(challenge.equationText)")
                )

            TextField("alarm_ringing_math_answer_placeholder", text: Binding(
                get: { answerInput },
                set: { newValue in
                    answerInput = String(newValue.filter(\.isNumber))
                    onClearError()
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title2.weight(.medium))
            .foregroundStyle(Color.pTextPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color.pGlassFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel(Text("alarm_ringing_math_answer_a11y"))

            if showError {
                Text("alarm_ringing_math_wrong")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.pAccentPrimary)
            }

            Group {
                if let submitAccessibilityLabel, let submitAccessibilityHint {
                    Button(action: onSubmit) { submitButtonLabel }
                        .accessibilityLabel(Text(submitAccessibilityLabel))
                        .accessibilityHint(Text(submitAccessibilityHint))
                } else {
                    Button(action: onSubmit) { submitButtonLabel }
                }
            }
        }
        .frame(maxWidth: 320)
    }

    private var submitButtonLabel: some View {
        Text(submitButtonTitle)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.accentPrimary)
            .clipShape(Capsule())
    }
}

// MARK: - Math toggle sheet

extension View {
    func mathToggleGateSheet(
        gate: Binding<MathToggleGate>,
        onSubmit: @escaping () async -> Bool,
        onCancel: @escaping () -> Void
    ) -> some View {
        sheet(item: Binding(
            get: { gate.wrappedValue.pendingAlarm },
            set: { if $0 == nil { onCancel() } }
        )) { alarm in
            ZStack {
                PGradientBackground()
                VStack(spacing: 24) {
                    Text("alarm_toggle_math_title \(alarm.displayTitle)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.pTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    MathStopChallengeView(
                        challenge: gate.wrappedValue.challenge,
                        answerInput: Binding(
                            get: { gate.wrappedValue.answerInput },
                            set: { gate.wrappedValue.answerInput = $0 }
                        ),
                        showError: gate.wrappedValue.answerError,
                        onClearError: { gate.wrappedValue.answerError = false },
                        submitButtonTitle: "alarm_toggle_math_submit_button",
                        onSubmit: {
                            Task {
                                let ok = await onSubmit()
                                if !ok {
                                    HapticManager.notification(.error)
                                } else {
                                    HapticManager.notification(.success)
                                }
                            }
                        }
                    )

                    Button("alarm_toggle_math_cancel_button", role: .cancel) {
                        onCancel()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.pTextSecondary)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

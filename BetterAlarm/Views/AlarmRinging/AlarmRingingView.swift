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
        VStack(spacing: 16) {
            Text(vm.mathChallenge.equationText)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.pTextPrimary)
                .accessibilityLabel(
                    Text("alarm_ringing_math_equation_a11y \(vm.mathChallenge.equationText)")
                )

            TextField("alarm_ringing_math_answer_placeholder", text: Binding(
                get: { vm.stopAnswerInput },
                set: { newValue in
                    vm.stopAnswerInput = String(newValue.filter(\.isNumber))
                    vm.clearStopAnswerError()
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

            if vm.stopAnswerError {
                Text("alarm_ringing_math_wrong")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.pAccentPrimary)
            }

            Button {
                Task {
                    if await vm.submitStopAnswer() {
                        dismiss()
                    }
                }
            } label: {
                Text("alarm_ringing_math_submit_button")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.accentPrimary)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(Text("alarm_ringing_stop_a11y"))
            .accessibilityHint(Text("alarm_ringing_stop_a11y_hint"))
        }
        .frame(maxWidth: 320)
    }
}

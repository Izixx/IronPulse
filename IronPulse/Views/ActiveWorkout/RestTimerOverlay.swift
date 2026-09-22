import SwiftUI

public struct RestTimerOverlay: View {
    @Bindable var restTimer = RestTimerViewModel.shared

    public var body: some View {
        if restTimer.isPresented {
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    // Cercle de progression circulaire
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: restTimer.progress)
                            .stroke(restTimer.timeRemaining <= 10 ? Color.red : Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                            .animation(.linear(duration: 1.0), value: restTimer.progress)

                        Image(systemName: "timer")
                            .font(.subheadline)
                            .foregroundColor(restTimer.timeRemaining <= 10 ? .red : .orange)
                    }

                    // Temps restant et nom exercice
                    VStack(alignment: .leading, spacing: 2) {
                        Text(restTimer.timeFormatted)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .foregroundColor(.primary)

                        Text(restTimer.exerciseName ?? "Temps de repos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Boutons rapides : +30s et Passer
                    HStack(spacing: 8) {
                        Button(action: {
                            restTimer.addSeconds(30)
                        }) {
                            Text("+30s")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .cornerRadius(8)
                        }

                        Button(action: {
                            restTimer.stop()
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.bold))
                                .padding(8)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(restTimer.timeRemaining <= 10 ? Color.red.opacity(0.6) : Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

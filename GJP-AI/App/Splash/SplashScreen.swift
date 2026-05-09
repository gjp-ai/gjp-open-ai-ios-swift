import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: SplashModel
    @State private var pulsing = false
    @State private var rotation = 0.0
    @State private var logoOpacity = 0.0
    @State private var brandOpacity = 0.0
    let onComplete: () -> Void

    init(app: AppModel, onComplete: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: SplashModel(app: app))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                stops: [
                    .init(color: Color(uiColor: .systemBackground), location: 0),
                    .init(color: Color(uiColor: .systemBackground), location: 0.6),
                    .init(color: app.tint.opacity(0.06), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Brand Identity with pulsing animation
                Image("SplashIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .scaleEffect(pulsing ? 1.5 : 1.0)
                    .opacity(logoOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            logoOpacity = 1.0
                        }
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulsing = true
                        }
                    }

                if let error = viewModel.error {
                    // Error Handling UI
                    VStack(spacing: 16) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)

                        Button {
                            Task { await viewModel.initialize(onComplete: onComplete) }
                        } label: {
                            Label(L10n.text("retry", app.language), systemImage: "arrow.clockwise")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(app.tint)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Custom Sleek Loading Indicator
                    ZStack {
                        Circle()
                            .stroke(app.tint.opacity(0.08), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(app.tint.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(Angle(degrees: rotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotation = 360
                                }
                            }
                    }
                    .padding(.top, 20)
                }

                Spacer()

                // Brand footer
                Text(L10n.text("brandName", app.language))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .tracking(4)
                    .opacity(brandOpacity)
                    .padding(.bottom, 24)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                            brandOpacity = 1.0
                        }
                    }
            }
        }
        .animation(.spring(), value: viewModel.error)
        .task {
            await viewModel.initialize(onComplete: onComplete)
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}

#Preview {
    SplashScreen(app: AppModel()) {}
        .environmentObject(AppModel())
}

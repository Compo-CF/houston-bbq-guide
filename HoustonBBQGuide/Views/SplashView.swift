import SwiftUI

/// Animated splash shown on cold launch while ContentView loads data in the
/// background. ~1.2s of animation; the parent fades it out after ~1.4s.
///
/// Composition mirrors the app icon: the brand steer head in amber->ember on
/// the smoked-dark ground. The mark is the SAME artwork the icon is cut from -
/// `pipeline/generate_icon.py` writes both from one isolated head, so the
/// launcher icon and the first screen can never drift apart.
///
/// The smoke is the one thing the icon cannot do. It rises behind the steer on
/// a slow loop, which is what makes the screen read as barbecue rather than as
/// a logo on a dark rectangle.
struct SplashView: View {
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.55
    @State private var markScale: CGFloat = 0.74
    @State private var markOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffsetY: CGFloat = 14
    @State private var ruleScale: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Coals under the mark, blooming once.
            RadialGradient(
                colors: [Theme.ember.opacity(0.30), Theme.ember.opacity(0)],
                center: .center,
                startRadius: 8,
                endRadius: 240
            )
            .frame(width: 480, height: 480)
            .scaleEffect(glowScale)
            .opacity(glowOpacity)
            .allowsHitTesting(false)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    // Behind the steer, so it reads as smoke off the pit
                    // rather than decoration in front of the logo.
                    HStack(spacing: 34) {
                        SmokeWisp(width: 26, delay: 0.0)
                        SmokeWisp(width: 34, delay: 0.55)
                        SmokeWisp(width: 22, delay: 1.1)
                    }
                    .offset(y: -34)

                    Image("SteerMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 232)
                        .scaleEffect(markScale)
                        .opacity(markOpacity)
                        .shadow(color: Theme.ember.opacity(0.35), radius: 24)
                }
                .frame(height: 220)

                VStack(spacing: 10) {
                    Text("HOUSTON BBQ GUIDE")
                        .font(Theme.serif(25, .bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Rectangle()
                        .fill(Theme.ember)
                        .frame(width: 96, height: 2)
                        .scaleEffect(x: ruleScale, y: 1, anchor: .center)

                    Text("A field guide to Houston barbecue")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.muted)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffsetY)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        // Coals come up first, so the mark lands on something lit.
        withAnimation(.easeOut(duration: 0.7)) {
            glowOpacity = 1
            glowScale = 1
        }
        // The steer settles in with a soft spring.
        withAnimation(.spring(response: 0.58, dampingFraction: 0.74).delay(0.12)) {
            markScale = 1
            markOpacity = 1
        }
        // Wordmark rises.
        withAnimation(.easeOut(duration: 0.5).delay(0.42)) {
            titleOpacity = 1
            titleOffsetY = 0
        }
        // The rule draws out from the centre, last.
        withAnimation(.easeOut(duration: 0.45).delay(0.62)) {
            ruleScale = 1
        }
    }
}

/// One column of smoke: a soft vertical gradient that rises and thins out, on
/// a slow repeating loop. Blurred rather than shaped - smoke has no edges, and
/// a hard-edged capsule reads as a pill.
private struct SmokeWisp: View {
    let width: CGFloat
    let delay: Double

    @State private var rise = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.amber.opacity(0),
                        Theme.amber.opacity(0.20),
                        Theme.amber.opacity(0),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: width, height: 130)
            .blur(radius: 11)
            .offset(y: rise ? -72 : 16)
            .opacity(rise ? 0 : 0.85)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.6)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    rise = true
                }
            }
    }
}

#Preview("Splash") {
    SplashView().preferredColorScheme(.dark)
}

import SwiftUI
// ColorTheme is already available in the project

struct ActivityIcons {
    // Define colors directly using ColorTheme or RGB values
    // Additional fun colors not in ColorTheme
    static let sunnyYellow = Color(red: 1.0, green: 0.82, blue: 0.4)
    static let grassGreen = Color(red: 0.02, green: 0.84, blue: 0.63)
    static let skyBlue = Color(red: 0.07, green: 0.54, blue: 0.7)
    static let orangeRed = Color(red: 0.94, green: 0.28, blue: 0.44)
    static let purpleBlue = Color(red: 0.46, green: 0.47, blue: 0.93)
    
    // Icon size constants
    static let smallIconSize: CGFloat = 24
    static let mediumIconSize: CGFloat = 36
    static let largeIconSize: CGFloat = 48
    
    // MARK: - Park Icon
    struct ParkIcon: View {
        var size: CGFloat
        var color: Color = ColorTheme.primary
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                VStack(spacing: size * 0.05) {
                    // Trees
                    HStack(spacing: size * 0.1) {
                        // Tree 1
                        VStack(spacing: -size * 0.05) {
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.25, height: size * 0.25)
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.3, height: size * 0.25)
                            Rectangle()
                                .fill(Color.brown)
                                .frame(width: size * 0.05, height: size * 0.1)
                        }
                        
                        // Tree 2
                        VStack(spacing: -size * 0.05) {
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.3, height: size * 0.3)
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.35, height: size * 0.3)
                            Rectangle()
                                .fill(Color.brown)
                                .frame(width: size * 0.06, height: size * 0.12)
                        }
                        
                        // Tree 3
                        VStack(spacing: -size * 0.05) {
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.25, height: size * 0.25)
                            Triangle()
                                .fill(grassGreen)
                                .frame(width: size * 0.3, height: size * 0.25)
                            Rectangle()
                                .fill(Color.brown)
                                .frame(width: size * 0.05, height: size * 0.1)
                        }
                    }
                    
                    // Ground
                    Rectangle()
                        .fill(grassGreen.opacity(0.5))
                        .frame(width: size * 0.8, height: size * 0.15)
                        .cornerRadius(size * 0.05)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Museum Icon
    struct MuseumIcon: View {
        var size: CGFloat
        var color: Color = ColorTheme.accent
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                VStack(spacing: 0) {
                    // Roof
                    Triangle()
                        .fill(ColorTheme.darkPurple)
                        .frame(width: size * 0.7, height: size * 0.3)
                    
                    // Building
                    Rectangle()
                        .fill(ColorTheme.secondary)
                        .frame(width: size * 0.6, height: size * 0.35)
                    
                    // Steps
                    VStack(spacing: size * 0.01) {
                        Rectangle()
                            .fill(ColorTheme.secondary.opacity(0.8))
                            .frame(width: size * 0.7, height: size * 0.05)
                        
                        Rectangle()
                            .fill(ColorTheme.secondary.opacity(0.6))
                            .frame(width: size * 0.8, height: size * 0.05)
                    }
                }
                
                // Columns
                HStack(spacing: size * 0.12) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(ColorTheme.secondary)
                            .frame(width: size * 0.08, height: size * 0.35)
                    }
                }
                .offset(y: -size * 0.05)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Playground Icon
    struct PlaygroundIcon: View {
        var size: CGFloat
        var color: Color = ColorTheme.highlight
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                VStack {
                    // Swing set
                    HStack(spacing: size * 0.3) {
                        // Left pole
                        Rectangle()
                            .fill(ColorTheme.darkPurple)
                            .frame(width: size * 0.05, height: size * 0.4)
                        
                        // Right pole
                        Rectangle()
                            .fill(ColorTheme.darkPurple)
                            .frame(width: size * 0.05, height: size * 0.4)
                    }
                    
                    // Ground
                    Rectangle()
                        .fill(grassGreen.opacity(0.5))
                        .frame(width: size * 0.8, height: size * 0.15)
                        .cornerRadius(size * 0.05)
                }
                
                // Top bar
                Rectangle()
                    .fill(ColorTheme.darkPurple)
                    .frame(width: size * 0.4, height: size * 0.05)
                    .offset(y: -size * 0.2)
                
                // Swings
                HStack(spacing: size * 0.15) {
                    // Left swing
                    VStack(spacing: 0) {
                        // Chains
                        Rectangle()
                            .fill(ColorTheme.darkPurple.opacity(0.7))
                            .frame(width: size * 0.02, height: size * 0.15)
                        
                        // Seat
                        Rectangle()
                            .fill(sunnyYellow)
                            .frame(width: size * 0.1, height: size * 0.03)
                            .cornerRadius(size * 0.01)
                    }
                    .offset(y: -size * 0.1)
                    
                    // Right swing
                    VStack(spacing: 0) {
                        // Chains
                        Rectangle()
                            .fill(ColorTheme.darkPurple.opacity(0.7))
                            .frame(width: size * 0.02, height: size * 0.15)
                        
                        // Seat
                        Rectangle()
                            .fill(sunnyYellow)
                            .frame(width: size * 0.1, height: size * 0.03)
                            .cornerRadius(size * 0.01)
                    }
                    .offset(y: -size * 0.1)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Library Icon
    struct LibraryIcon: View {
        var size: CGFloat
        var color: Color = skyBlue
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                VStack(spacing: size * 0.05) {
                    // Books on shelf
                    HStack(spacing: size * 0.02) {
                        // Book 1
                        Rectangle()
                            .fill(ColorTheme.highlight)
                            .frame(width: size * 0.1, height: size * 0.35)
                        
                        // Book 2
                        Rectangle()
                            .fill(ColorTheme.primary)
                            .frame(width: size * 0.1, height: size * 0.35)
                        
                        // Book 3
                        Rectangle()
                            .fill(sunnyYellow)
                            .frame(width: size * 0.1, height: size * 0.35)
                        
                        // Book 4
                        Rectangle()
                            .fill(ColorTheme.accent)
                            .frame(width: size * 0.1, height: size * 0.35)
                        
                        // Book 5
                        Rectangle()
                            .fill(orangeRed)
                            .frame(width: size * 0.1, height: size * 0.35)
                    }
                    
                    // Shelf
                    Rectangle()
                        .fill(ColorTheme.darkPurple)
                        .frame(width: size * 0.7, height: size * 0.05)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Swimming Icon
    struct SwimmingIcon: View {
        var size: CGFloat
        var color: Color = skyBlue.opacity(0.7)
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Pool
                Circle()
                    .fill(skyBlue)
                    .frame(width: size * 0.7, height: size * 0.7)
                
                // Water waves
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.5, height: size * 0.05)
                        .offset(y: CGFloat(i) * size * 0.15 - size * 0.15)
                }
                
                // Swimmer
                Circle()
                    .fill(ColorTheme.secondary)
                    .frame(width: size * 0.15, height: size * 0.15)
                    .offset(x: size * 0.1, y: -size * 0.05)
                
                // Arms
                Path { path in
                    path.move(to: CGPoint(x: size * 0.1, y: -size * 0.05))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.25, y: size * 0.1),
                        control: CGPoint(x: size * 0.3, y: -size * 0.1)
                    )
                }
                .stroke(ColorTheme.secondary, lineWidth: size * 0.03)
                
                Path { path in
                    path.move(to: CGPoint(x: size * 0.1, y: -size * 0.05))
                    path.addQuadCurve(
                        to: CGPoint(x: -size * 0.05, y: size * 0.1),
                        control: CGPoint(x: -size * 0.1, y: -size * 0.1)
                    )
                }
                .stroke(ColorTheme.secondary, lineWidth: size * 0.03)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Sports Icon
    struct SportsIcon: View {
        var size: CGFloat
        var color: Color = orangeRed
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Soccer ball
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.6, height: size * 0.6)
                
                // Soccer ball pattern
                ZStack {
                    // Horizontal line
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: size * 0.6, height: size * 0.02)
                    
                    // Vertical line
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: size * 0.02, height: size * 0.6)
                    
                    // Diagonal lines
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: size * 0.02, height: size * 0.3)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    
                    // Pentagons
                    ForEach(0..<5) { i in
                        RegularPolygon(sides: 5)
                            .fill(Color.black)
                            .frame(width: size * 0.15, height: size * 0.15)
                            .offset(
                                x: cos(Double(i) * 2 * .pi / 5) * size * 0.2,
                                y: sin(Double(i) * 2 * .pi / 5) * size * 0.2
                            )
                    }
                }
                .frame(width: size * 0.6, height: size * 0.6)
                .mask(
                    Circle()
                        .frame(width: size * 0.6, height: size * 0.6)
                )
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Zoo Icon
    struct ZooIcon: View {
        var size: CGFloat
        var color: Color = grassGreen
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Lion face
                ZStack {
                    // Face
                    Circle()
                        .fill(sunnyYellow)
                        .frame(width: size * 0.6, height: size * 0.6)
                    
                    // Mane
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(orangeRed)
                            .frame(width: size * 0.15, height: size * 0.05)
                            .cornerRadius(size * 0.025)
                            .rotationEffect(.degrees(Double(i) * 30))
                            .offset(
                                x: cos(Double(i) * .pi / 6) * size * 0.3,
                                y: sin(Double(i) * .pi / 6) * size * 0.3
                            )
                    }
                    
                    // Eyes
                    HStack(spacing: size * 0.2) {
                        Circle()
                            .fill(ColorTheme.darkPurple)
                            .frame(width: size * 0.1, height: size * 0.1)
                        
                        Circle()
                            .fill(ColorTheme.darkPurple)
                            .frame(width: size * 0.1, height: size * 0.1)
                    }
                    .offset(y: -size * 0.05)
                    
                    // Nose
                    Triangle()
                        .fill(ColorTheme.darkPurple)
                        .frame(width: size * 0.15, height: size * 0.15)
                        .rotationEffect(.degrees(180))
                        .offset(y: size * 0.1)
                    
                    // Mouth
                    Capsule()
                        .fill(ColorTheme.darkPurple)
                        .frame(width: size * 0.3, height: size * 0.05)
                        .offset(y: size * 0.2)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Aquarium Icon
    struct AquariumIcon: View {
        var size: CGFloat
        var color: Color = skyBlue
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Fish tank
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(skyBlue.opacity(0.5))
                    .frame(width: size * 0.7, height: size * 0.5)
                
                // Water bubbles
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: size * CGFloat([0.05, 0.07, 0.06, 0.04, 0.05][i]), height: size * CGFloat([0.05, 0.07, 0.06, 0.04, 0.05][i]))
                        .offset(
                            x: size * CGFloat([-0.2, -0.1, 0, 0.1, 0.2][i]),
                            y: size * CGFloat([-0.15, -0.05, -0.1, -0.2, -0.1][i])
                        )
                }
                
                // Fish
                Fish(size: size * 0.2, color: orangeRed)
                    .offset(x: size * 0.15, y: 0)
                
                Fish(size: size * 0.15, color: ColorTheme.primary)
                    .offset(x: -size * 0.15, y: size * 0.1)
                    .rotationEffect(.degrees(180))
                
                // Seaweed
                ForEach(0..<3) { i in
                    Path { path in
                        path.move(to: CGPoint(x: size * CGFloat([-0.2, 0, 0.2][i]), y: size * 0.25))
                        path.addQuadCurve(
                            to: CGPoint(x: size * CGFloat([-0.15, 0.05, 0.25][i]), y: size * 0.15),
                            control: CGPoint(x: size * CGFloat([-0.1, 0.1, 0.3][i]), y: size * 0.2)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: size * CGFloat([-0.2, 0, 0.2][i]), y: size * 0.05),
                            control: CGPoint(x: size * CGFloat([-0.2, 0, 0.2][i]), y: size * 0.1)
                        )
                    }
                    .stroke(grassGreen, lineWidth: size * 0.02)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Movie Theater Icon
    struct MovieTheaterIcon: View {
        var size: CGFloat
        var color: Color = purpleBlue
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Movie screen
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(Color.white)
                    .frame(width: size * 0.7, height: size * 0.4)
                    .offset(y: -size * 0.1)
                
                // Film strip
                VStack(spacing: size * 0.02) {
                    ForEach(0..<2) { _ in
                        HStack(spacing: size * 0.02) {
                            ForEach(0..<4) { _ in
                                RoundedRectangle(cornerRadius: size * 0.01)
                                    .fill(ColorTheme.darkPurple)
                                    .frame(width: size * 0.1, height: size * 0.05)
                            }
                        }
                    }
                }
                .offset(y: -size * 0.1)
                
                // Seats
                VStack(spacing: size * 0.05) {
                    ForEach(0..<2) { row in
                        HStack(spacing: size * 0.05) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: size * 0.02)
                                    .fill(row == 0 ? ColorTheme.highlight : ColorTheme.accent)
                                    .frame(width: size * 0.15, height: size * 0.08)
                            }
                        }
                    }
                }
                .offset(y: size * 0.15)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Theme Park Icon
    struct ThemeParkIcon: View {
        var size: CGFloat
        var color: Color = sunnyYellow
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Ferris wheel
                Circle()
                    .stroke(ColorTheme.darkPurple, lineWidth: size * 0.03)
                    .frame(width: size * 0.6, height: size * 0.6)
                
                // Spokes
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(ColorTheme.darkPurple)
                        .frame(width: size * 0.6, height: size * 0.02)
                        .rotationEffect(.degrees(Double(i) * 22.5))
                }
                
                // Cabins
                ForEach(0..<8) { i in
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(i % 2 == 0 ? ColorTheme.primary : ColorTheme.highlight)
                        .frame(width: size * 0.12, height: size * 0.08)
                        .offset(
                            x: cos(Double(i) * .pi / 4) * size * 0.3,
                            y: sin(Double(i) * .pi / 4) * size * 0.3
                        )
                }
                
                // Support structure
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.3))
                    path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.3))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                }
                .fill(ColorTheme.darkPurple)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Other Activity Icon
    struct OtherActivityIcon: View {
        var size: CGFloat
        var color: Color = ColorTheme.accent
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color)
                
                // Star shape
                ForEach(0..<5) { i in
                    Triangle()
                        .fill(ColorTheme.highlight)
                        .frame(width: size * 0.2, height: size * 0.3)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                
                // Center circle
                Circle()
                    .fill(ColorTheme.secondary)
                    .frame(width: size * 0.25, height: size * 0.25)
                
                // Question mark
                Text("?")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundColor(ColorTheme.darkPurple)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Helper Shapes
    
    struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
    
    struct RegularPolygon: Shape {
        var sides: Int
        
        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
            let radius = min(rect.width, rect.height) / 2
            
            var path = Path()
            let angle = Double.pi * 2 / Double(sides)
            
            for i in 0..<sides {
                let x = center.x + CGFloat(cos(angle * Double(i))) * radius
                let y = center.y + CGFloat(sin(angle * Double(i))) * radius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            path.closeSubpath()
            return path
        }
    }
    
    struct Fish: View {
        var size: CGFloat
        var color: Color
        
        var body: some View {
            ZStack {
                // Fish body
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                
                // Tail
                Triangle()
                    .fill(color)
                    .frame(width: size * 0.6, height: size * 0.8)
                    .offset(x: -size * 0.5, y: 0)
                
                // Eye
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: size * 0.25, y: -size * 0.1)
                
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.15, height: size * 0.15)
                    .offset(x: size * 0.3, y: -size * 0.1)
            }
        }
    }
}


// Preview provider
struct ActivityIcons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ActivityIcons.ParkIcon(size: 60)
                ActivityIcons.MuseumIcon(size: 60)
                ActivityIcons.PlaygroundIcon(size: 60)
                ActivityIcons.LibraryIcon(size: 60)
            }
            
            HStack(spacing: 20) {
                ActivityIcons.SwimmingIcon(size: 60)
                ActivityIcons.SportsIcon(size: 60)
                ActivityIcons.ZooIcon(size: 60)
                ActivityIcons.AquariumIcon(size: 60)
            }
            
            HStack(spacing: 20) {
                ActivityIcons.MovieTheaterIcon(size: 60)
                ActivityIcons.ThemeParkIcon(size: 60)
                ActivityIcons.OtherActivityIcon(size: 60)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

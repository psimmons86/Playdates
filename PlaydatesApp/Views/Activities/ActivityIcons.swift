import SwiftUI

struct ActivityIcons {
    // MARK: - Activity Icons
    struct ParkIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.green)
                .frame(width: size, height: size)
        }
    }
    
    struct MuseumIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "building.columns.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.blue)
                .frame(width: size, height: size)
        }
    }
    
    struct PlaygroundIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "figure.play")
                .font(.system(size: size * 0.6))
                .foregroundColor(.green)
                .frame(width: size, height: size)
        }
    }
    
    struct LibraryIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.blue)
                .frame(width: size, height: size)
        }
    }
    
    struct SwimmingIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "figure.pool.swim")
                .font(.system(size: size * 0.6))
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.9))
                .frame(width: size, height: size)
        }
    }
    
    struct SportsIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.orange)
                .frame(width: size, height: size)
        }
    }
    
    struct ZooIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.orange)
                .frame(width: size, height: size)
        }
    }
    
    struct AquariumIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "fish.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.9))
                .frame(width: size, height: size)
        }
    }
    
    struct MovieTheaterIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "film.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(.purple)
                .frame(width: size, height: size)
        }
    }
    
    struct ThemeParkIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "ferriswheel")
                .font(.system(size: size * 0.6))
                .foregroundColor(.red)
                .frame(width: size, height: size)
        }
    }
    
    struct OtherActivityIcon: View {
        let size: CGFloat
        
        var body: some View {
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.6))
                .foregroundColor(ColorTheme.primary)
                .frame(width: size, height: size)
        }
    }
}

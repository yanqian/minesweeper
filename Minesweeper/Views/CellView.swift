import SwiftUI

struct CellView: View {
    let cell: Cell
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(backgroundColor)

            if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: "burst.fill")
                        .foregroundStyle(.gray)
                        .font(.system(size: size * 0.5))
                } else if cell.adjacentMines > 0 {
                    Text("\(cell.adjacentMines)")
                        .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor)
                }
            } else if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: size * 0.45))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.black.opacity(0.05))
        )
    }

    private var backgroundColor: Color {
        if cell.isRevealed {
            return Color.secondary.opacity(0.12)
        }
        return Color.accentColor.opacity(0.2)
    }

    private var numberColor: Color {
        switch cell.adjacentMines {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        case 5: return .red
        default: return .gray
        }
    }
}

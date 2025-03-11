import SwiftUI

struct GameSelectionRow: View {
    let game: Game
    @Binding var selectedGames: Set<Game>
    @State private var selectedRank: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Checkbox del juego
                Button(action: {
                    if selectedGames.contains(game) {
                        selectedGames.remove(game)
                    } else {
                        selectedGames.insert(game)
                    }
                }) {
                    Image(systemName: selectedGames.contains(game) ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedGames.contains(game) ? Color(red: 0.9, green: 0.3, blue: 0.2) : .gray)
                        .font(.system(size: 20))
                }
                
                Text(game.name)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            
            // Selector de rango (solo visible si el juego está seleccionado)
            if selectedGames.contains(game) {
                Picker("Rango", selection: $selectedRank) {
                    ForEach(game.ranks, id: \.self) { rank in
                        Text(rank).tag(rank)
                    }
                }
                .pickerStyle(.menu)
                .padding(.leading, 30)
            }
        }
        .padding(.vertical, 8)
    }
} 
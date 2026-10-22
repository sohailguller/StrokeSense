//
//  AudioRow.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/22/25.
//
import SwiftUI
import AVKit

class SoundManager: ObservableObject {
    @Published var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    enum Sound: String {
        case preventStroke
        case realStory
        case strokeCare
    }

    func playSound(sound: Sound) {
        if audioPlayer == nil {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") else { return }

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                duration = audioPlayer?.duration ?? 0
                startTimer()
            } catch {
                print("Could not find and play the sound file")
            }
        }
        audioPlayer?.play()
        isPlaying = true
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func togglePlayPause(sound: Sound) {
        if isPlaying {
            pause()
        } else {
            playSound(sound: sound)
        }
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.isPlaying = false
                timer.invalidate()
            }
        }
    }
}


struct AudioRow: View {
    var sound: String
    var episodeName: String
    @StateObject private var soundManager = SoundManager()
    @State private var sliderValue: Double = 0
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        VStack {
            HStack {
                Text(episodeName)
                    .font(.headline)
                    .padding()
                    .padding(.bottom, -20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Button(action: {
                    switch sound {
                        case "preventStroke":
                            soundManager.togglePlayPause(sound: .preventStroke)
                        case "realStory":
                            soundManager.togglePlayPause(sound: .realStory)
                        case "strokeCare":
                            soundManager.togglePlayPause(sound: .strokeCare)
                        default:
                            soundManager.togglePlayPause(sound: .preventStroke)
                    }
                }) {
                    Image(systemName: soundManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .padding()

                Slider(value: $sliderValue, in: 0...soundManager.duration, onEditingChanged: { editing in
                    if !editing {
                        soundManager.seek(to: sliderValue)
                    }
                })
                .padding()
                
                Button(action: {
                    if favoritesManager.favorites.keys.contains(sound) {
                        favoritesManager.removeFavorite(sound: sound)
                    } else {
                        favoritesManager.addFavorite(sound: sound, episode: episodeName)
                    }
                }) {
                    Image(systemName: favoritesManager.favorites.keys.contains(sound) ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 25, height: 23)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(soundManager.$currentTime) { newValue in
            sliderValue = newValue
        }
        .onDisappear {
            soundManager.pause()
        }
    }
}


#Preview {
    AudioRow(sound: "preventStroke", episodeName: "The true story of a 15 year old boy")
        .environmentObject(FavoritesManager())
}

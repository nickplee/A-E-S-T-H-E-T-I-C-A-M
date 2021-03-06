//
//  Synthesizer.swift
//  A E S T H E T I C A M
//
//  Created by Nick Lee on 5/23/16.
//  Copyright © 2016 Nick Lee. All rights reserved.
//

import Foundation
import AudioKit
import Then

final class Synthesizer {
    
    static let shared = Synthesizer()
    
    private static let noteRange = MIDINoteNumber(24)...84
    
    private let mixer = AKMixer().then {
        $0.volume = 0.7
    }
    
    private let osc = AKFMOscillatorBank().then {
        $0.releaseDuration = 0.1
    }
    
    private var players: [AKAudioPlayer] = []
    
    private let aesthetic = (try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "push", withExtension: "aiff")!)).then {
        $0.volume = 0.1
    }
    
    private init() {
        
        AudioKit.output = mixer
        
        osc.connect(to: mixer)
        
        players += (1...4).flatMap { i in
            let name = "snd\(i)"
            guard let url = Bundle.main.url(forResource: name, withExtension: "aiff") else {
                return nil
            }
            do {
                let file = try AKAudioFile(forReading: url)
                let player = try AKAudioPlayer(file: file)
                player.connect(to: mixer)
                return player
            }
            catch {
                return nil
            }
        }
    }
    
    func startEngine() {
        do {
            try AudioKit.start()
        }
        catch{}
    }
    
    func play(_ includeSounds: Bool = false) {
        DispatchQueue.main.async {
            if !includeSounds || Bool.random(using: &DeviceRandom.default) {
                self.osc.play(noteNumber: MIDINoteNumber.random(within: Synthesizer.noteRange), velocity: 127)
            }
            else if self.players.isNotEmpty {
                self.players.randomElement().play()
            }
        }
    }
    
    func playAesthetic() {
        DispatchQueue.main.async {
            self.aesthetic.stop()
            self.aesthetic.currentTime = 0
            self.aesthetic.play()
        }
    }
    
    func stop(_ includeSounds: Bool = false) {
        DispatchQueue.main.async {
            if includeSounds {
                for p in self.players {
                    if p.isPlaying {
                        p.stop()
                        do {
                            try p.reloadFile()
                        }
                        catch {}
                    }
                }
            }
            for i in Synthesizer.noteRange {
                self.osc.stop(noteNumber: i)
            }
        }
    }
    
}

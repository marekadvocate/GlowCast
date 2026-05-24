import AVFoundation
import os

/// Captures microphone input level from the system default input device.
/// Thread-safe: the tap runs on a realtime audio thread; `level` is guarded
/// by an unfair lock so it can be read from any context (including @MainActor).
final class AudioMonitor: @unchecked Sendable {

    // MARK: - Public interface

    /// Smoothed, normalised input level in 0...1.
    var level: Double { _lock.withLock { $0 } }

    /// Called on the main actor when the user denies microphone access.
    var onPermissionDenied: (() -> Void)?

    // MARK: - Private state

    /// Stores the smoothed level; all access is through `_lock`.
    private let _lock = OSAllocatedUnfairLock<Double>(initialState: 0)

    private let engine = AVAudioEngine()
    private var isRunning = false

    // MARK: - Start / Stop

    func start() {
        // Request microphone permission first (no-op if already granted).
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard let self else { return }
            if granted {
                DispatchQueue.main.async { self.startEngine() }
            } else {
                DispatchQueue.main.async {
                    self.onPermissionDenied?()
                }
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        _lock.withLock { $0 = 0 }
    }

    // MARK: - Private helpers

    private func startEngine() {
        guard !isRunning else { return }

        let inputNode = engine.inputNode
        // Use the hardware format so we don't need a converter.
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 512, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.processTap(buffer: buffer)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            NSLog("AudioMonitor: engine start failed: %@", error.localizedDescription)
            inputNode.removeTap(onBus: 0)
        }
    }

    /// Called on the realtime audio thread -- must not touch @MainActor state.
    private func processTap(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        // Compute RMS of the first channel.
        let samples = channelData[0]
        var sumOfSquares: Float = 0
        for i in 0 ..< frameCount {
            let s = samples[i]
            sumOfSquares += s * s
        }
        let rms = Double(sqrt(sumOfSquares / Float(frameCount)))

        // Map to 0...1: roughly -50 dB -> 0, 0 dB -> 1.
        let db = rms > 0 ? 20 * log10(rms) : -160
        let normalised = min(1, max(0, (db + 50) / 50))

        // Exponential smoothing (attack 0.2, decay 0.8).
        _lock.withLock { current in
            current = current * 0.8 + normalised * 0.2
        }
    }
}

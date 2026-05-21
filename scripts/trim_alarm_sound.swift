import AVFoundation
import Foundation

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let maxSeconds = Double(CommandLine.arguments[3]) ?? 30

let asset = AVURLAsset(url: input)
guard let session = AVAssetExportSession(
    asset: asset,
    presetName: AVAssetExportPresetAppleM4A
) else {
    fputs("Failed to create export session\n", stderr)
    exit(1)
}

try? FileManager.default.removeItem(at: output)
session.outputURL = output
session.outputFileType = .m4a
session.timeRange = CMTimeRange(
    start: .zero,
    duration: CMTime(seconds: maxSeconds, preferredTimescale: 600)
)

let semaphore = DispatchSemaphore(value: 0)
session.exportAsynchronously {
    semaphore.signal()
}
semaphore.wait()

switch session.status {
case .completed:
    print("Exported \(maxSeconds)s to \(output.path)")
case .failed, .cancelled:
    fputs("Export failed: \(session.error?.localizedDescription ?? "unknown")\n", stderr)
    exit(1)
default:
    fputs("Export ended with status \(session.status.rawValue)\n", stderr)
    exit(1)
}

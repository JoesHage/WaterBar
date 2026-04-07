import Foundation

protocol WaterSnapshotStorage {
    func load() throws -> WaterBarSnapshot?
    func save(_ snapshot: WaterBarSnapshot) throws
}

struct FileWaterSnapshotStorage: WaterSnapshotStorage {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        let directory = appSupport.appendingPathComponent("WaterBar", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state.json")
    }

    func load() throws -> WaterBarSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(WaterBarSnapshot.self, from: data)
    }

    func save(_ snapshot: WaterBarSnapshot) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}

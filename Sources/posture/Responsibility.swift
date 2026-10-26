import Darwin
import Foundation
import PostureKit

enum Responsibility {
    private static let marker = "POSTURE_DISCLAIMED"

    static func disclaimTerminal() {
        guard getenv(marker) == nil,
              let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_spawnattrs_setdisclaim")
        else { return }

        typealias Disclaim = @convention(c) (UnsafeMutablePointer<posix_spawnattr_t?>, Int32) -> Int32
        let disclaim = unsafeBitCast(symbol, to: Disclaim.self)

        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        guard disclaim(&attributes, 1) == 0 else { return }

        setenv(marker, "1", 1)
        let argv = CommandLine.unsafeArgv
        var pid: pid_t = 0
        guard posix_spawn(&pid, Bundle.main.executablePath ?? CommandLine.arguments[0], nil, &attributes, argv, environ) == 0 else { return }

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        var status: Int32 = 0
        while waitpid(pid, &status, 0) == -1 && errno == EINTR {}
        let code = status & 0x7f == 0 ? (status >> 8) & 0xff : 128 + (status & 0x7f)
        exit(code)
    }
}

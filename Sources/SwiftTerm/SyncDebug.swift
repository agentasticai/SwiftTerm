//
// SyncDebug.swift
//
// Upstream commit 9446f60 ("Simplifies the DEC 2026 buffering support")
// added SyncDebug.log(...) call sites in AppleTerminalView.swift and
// Terminal.swift but did not commit the type itself, leaving upstream
// HEAD un-buildable. This stub keeps the fork building until upstream
// publishes the real implementation; remove on the next upstream sync
// once SyncDebug ships upstream.
//

import Foundation

enum SyncDebug {
    @inlinable
    static func log(_ message: @autoclosure () -> String) {}
}

//
//  TerminalView+HostReads.swift
//
//  Agentastic fork: copied reads and commands for host features that the
//  SwiftTerm 2.0 view API does not cover. Agentastic resolves link clicks
//  before mouse reporting forwards them to a program, hit-tests image paths
//  under the pointer, and reads recent output for its CLI; all of them address
//  buffer rows and need the text SwiftTerm's own getText produces. Each member
//  here holds the terminal lock only for the read and returns values, like
//  ``TerminalView/terminalStateSnapshot()``. Kept in its own file so upstream
//  syncs do not conflict with it.
//
#if os(macOS) || os(iOS) || os(visionOS)
import Foundation

/// Where a host addresses the live buffer from, read under one lock.
public struct TerminalBufferGeometry: Sendable, Equatable {
    /// The buffer row shown at the top of the viewport. Rows above it are
    /// scrollback the user scrolled past.
    public let viewportRow: Int
    /// The buffer row at the top of the screen, which the viewport shows when
    /// it is not scrolled back.
    public let screenRow: Int
    /// The cursor. `row` is relative to ``screenRow``.
    public let cursor: Position
    /// The grid size.
    public let dimensions: TerminalDimensions
}

extension TerminalView {
    /// Returns the viewport and screen origins, the cursor, and the grid size.
    public func bufferGeometry() -> TerminalBufferGeometry {
        withTerminal { terminal in
            let buffer = terminal.buffer
            return TerminalBufferGeometry(
                viewportRow: buffer.yDisp,
                screenRow: buffer.yBase,
                cursor: Position(col: buffer.x, row: buffer.y),
                dimensions: TerminalDimensions(cols: terminal.cols, rows: terminal.rows))
        }
    }

    /// Returns the text between two buffer positions, as
    /// ``Terminal/getText(start:end:)`` does: soft-wrapped rows are joined and
    /// blank cells are trimmed from the end of each row. Rows are buffer rows,
    /// so they include scrollback; see ``bufferGeometry()``.
    public func getText(start: Position, end: Position) -> String {
        withTerminal { $0.getText(start: start, end: end) }
    }

    /// Returns the hyperlink or detected link at a viewport cell, if any.
    public func link(atScreen position: Position, mode: Terminal.LinkLookupMode) -> String? {
        withTerminal { $0.link(at: .screen(position), mode: mode) }
    }

    /// Whether the program asked to receive Shift-modified mouse events
    /// (XTSHIFTESCAPE). When it did not, Shift bypasses mouse reporting.
    public var mouseShiftCapture: Bool {
        withTerminal { $0.mouseShiftCapture }
    }

    /// Whether the terminal suppresses its diagnostic log output. Release
    /// builds default to `true` and debug builds to `false`.
    public var silentLog: Bool {
        get { withTerminal { $0.silentLog } }
        set { withTerminal { $0.silentLog = newValue } }
    }

    /// Marks every row dirty and schedules a frame. For a host whose backing
    /// store may be stale after sleep, a display change, or reattaching the
    /// view to a window.
    public func refreshFullScreen() {
        withTerminal { $0.updateFullScreen() }
        frameDriver.markDirty()
    }
}
#endif

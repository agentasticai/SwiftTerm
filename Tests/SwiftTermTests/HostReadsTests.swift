//
//  HostReadsTests.swift
//
//  Coverage for the Agentastic fork's copied host reads in
//  TerminalView+HostReads.swift.
//
#if os(macOS)
import AppKit
import Testing

@testable import SwiftTerm

@MainActor
struct HostReadsTests {
    private func makeView() -> TerminalView {
        TerminalView(frame: NSRect(x: 0, y: 0, width: 400, height: 200),
                     font: NSFont(name: "Menlo-Regular", size: 12))
    }

    @Test func bufferGeometryReportsScrollbackAndCursor() {
        let view = makeView()
        let rows = view.terminalDimensions.rows
        // rows + 1 line feeds from the top row scroll two rows into history.
        view.feed(text: String(repeating: "x\r\n", count: rows + 1) + "ab")

        let geometry = view.bufferGeometry()

        #expect(geometry.dimensions == view.terminalDimensions)
        #expect(geometry.screenRow == 2)
        #expect(geometry.viewportRow == 2)
        #expect(geometry.cursor == Position(col: 2, row: rows - 1))
    }

    @Test func getTextJoinsSoftWrappedRows() {
        let view = makeView()
        let cols = view.terminalDimensions.cols
        let line = String(repeating: "w", count: cols + 3)
        view.feed(text: line + "\r\nnext")

        let text = view.getText(start: Position(col: 0, row: 0),
                                end: Position(col: cols, row: 2))

        #expect(text == line + "\nnext")
    }

    @Test func linkLookupFindsAnExplicitHyperlink() {
        let view = makeView()
        view.feed(text: "\u{1b}]8;;https://example.com\u{1b}\\link\u{1b}]8;;\u{1b}\\ plain")

        #expect(view.link(atScreen: Position(col: 1, row: 0), mode: .explicitOnly)
                == "https://example.com")
        #expect(view.link(atScreen: Position(col: 6, row: 0), mode: .explicitOnly) == nil)
    }

    @Test func mouseShiftCaptureFollowsShiftEscape() {
        let view = makeView()
        #expect(!view.mouseShiftCapture)

        view.feed(text: "\u{1b}[>1s")
        #expect(view.mouseShiftCapture)

        view.feed(text: "\u{1b}[>0s")
        #expect(!view.mouseShiftCapture)
    }

    @Test func silentLogWritesThroughToTheTerminal() {
        let view = makeView()
        view.silentLog = true
        #expect(view.silentLog)
        view.silentLog = false
        #expect(!view.silentLog)
    }
}
#endif

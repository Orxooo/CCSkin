// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import AppKit

/// NSPopUpButton fills its assigned column; SwiftUI's borderless Menu collapses to its title on macOS.
struct ModsFilterControl: NSViewRepresentable {
    struct Option { let id: String; let title: String }
    let label: String
    let options: [Option]
    @Binding var selection: String

    final class Coordinator: NSObject {
        var parent: ModsFilterControl
        init(_ parent: ModsFilterControl) { self.parent = parent }
        @objc func changed(_ sender: NSPopUpButton) {
            guard parent.options.indices.contains(sender.indexOfSelectedItem) else { return }
            parent.selection = parent.options[sender.indexOfSelectedItem].id
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSPopUpButton {
        let control = NSPopUpButton(frame:.zero,pullsDown:false)
        control.controlSize = .large
        control.bezelStyle = .rounded
        control.font = .systemFont(ofSize:12,weight:.medium)
        control.setContentHuggingPriority(.defaultLow,for:.horizontal)
        control.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        control.target = context.coordinator
        control.action = #selector(Coordinator.changed(_:))
        return control
    }
    func updateNSView(_ control: NSPopUpButton, context: Context) {
        context.coordinator.parent = self
        let titles = options.map(\.title)
        if control.itemTitles != titles { control.removeAllItems(); control.addItems(withTitles:titles) }
        if let index = options.firstIndex(where: { $0.id == selection }) { control.selectItem(at:index) }
        control.isEnabled = context.environment.isEnabled
        control.setAccessibilityLabel(label)
        control.setAccessibilityIdentifier("CCSkin.Mods."+label)
    }
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
        CGSize(width:proposal.width ?? 200,height:38)
    }
}

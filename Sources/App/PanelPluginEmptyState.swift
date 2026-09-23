import MacToolsPluginKit
import SwiftUI

struct PanelPluginEmptyState: View {
    let tab: MenuBarPanelTab
    let onInstall: () -> Void
    @Environment(\.menuBarPanelTheme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                Image(systemName: PluginSystemImage.resolvedName(tab.systemImage))
                    .font(PluginPanelTheme.Symbol.hero.weight(.semibold))
                    .foregroundStyle(theme.text.secondary)

                Text(AppL10n.plugins("plugin.panel.empty.title", defaultValue: "暂无插件"))
                    .font(PluginPanelTheme.Typography.emptyStateTitle)
            }

            installButton
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var installButton: some View {
        Button(action: onInstall) {
            Text(AppL10n.plugins("plugin.empty.install", defaultValue: "去安装"))
                .font(PluginPanelTheme.Typography.controlLabel)
                .foregroundStyle(theme.accent)
        }
            .buttonStyle(.link)
            .help(AppL10n.plugins("plugin.empty.openMarketplace", defaultValue: "打开插件市场"))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
    }
}

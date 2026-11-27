import SwiftUI
import WidgetKit

struct AgendaWidgetView: View {
  let entry: AgendaEntry

  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryInline:
      AgendaInlineView(entry: entry)
        .containerBackground(for: .widget) { Color.clear }
    case .accessoryRectangular:
      AgendaRectangularView(entry: entry)
        .containerBackground(for: .widget) { Color.clear }
    default:
      AgendaHomeView(entry: entry)
    }
  }
}

// MARK: - Home screen

private struct AgendaHomeView: View {
  let entry: AgendaEntry

  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.colorSchemeContrast) private var contrast

  private var palette: AgendaPalette { AgendaPalette(colorScheme: colorScheme, contrast: contrast) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        AgendaHeader(family: family, palette: palette, strings: entry.strings)
          .linked(to: AgendaLinks.planner, in: family)
        Spacer(minLength: 0)
        if family.showsDetails, let todayLabel = entry.content?.todayLabel {
          Text(todayLabel)
            .font(AgendaFont.regular(11))
            .foregroundStyle(palette.muted)
            .lineLimit(1)
        }
      }
      main
      if let staleDays = entry.content?.staleDays {
        Text(String(localized: "Updated \(staleDays)d ago", bundle: entry.strings))
          .font(AgendaFont.regular(10))
          .foregroundStyle(palette.muted)
          .accessibilityLabel(String(localized: "Updated \(staleDays) days ago", bundle: entry.strings))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) { palette.surface }
    .widgetURL(entry.content == nil ? nil : AgendaLinks.planner)
  }

  @ViewBuilder
  private var main: some View {
    switch entry.state {
    case .missing:
      AgendaMessage(
        symbol: "arrow.up.forward.app", text: String(localized: "Open Helium to see what's due", bundle: entry.strings),
        palette: palette)
    case .signedOut:
      AgendaMessage(
        symbol: "person.crop.circle", text: String(localized: "Sign in to Helium", bundle: entry.strings),
        palette: palette)
    case .loaded:
      if let content = entry.content, !content.isEmpty {
        GeometryReader { proxy in
          AgendaList(
            layout: AgendaLayout(content: content, family: family, height: proxy.size.height),
            family: family, palette: palette)
        }
      } else {
        AgendaMessage(
          symbol: "checkmark.circle", text: String(localized: "All caught up", bundle: entry.strings), palette: palette)
      }
    }
  }
}

private struct AgendaHeader: View {
  let family: WidgetFamily
  let palette: AgendaPalette
  let strings: Bundle

  var body: some View {
    HStack(spacing: 6) {
      Image("HeliumLogo")
        .resizable()
        .desaturatedWhenAccented()
        .frame(width: 20, height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .accessibilityHidden(true)
      Text(String(localized: "Agenda", bundle: strings))
        .font(AgendaFont.title(17))
        .foregroundStyle(palette.onSurface)
    }
    .frame(height: 22)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      family == .systemSmall
        ? String(localized: "Agenda", bundle: strings) : String(localized: "Open Planner", bundle: strings))
    .accessibilityAddTraits(.isHeader)
  }
}

private struct AgendaMessage: View {
  let symbol: String
  let text: String
  let palette: AgendaPalette

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: symbol)
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(palette.primary)
        .accessibilityHidden(true)
      Text(text)
        .font(AgendaFont.medium(13))
        .foregroundStyle(palette.onSurface)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// The groups and rows that fit the space left under the header, measured in the fixed font sizes' line heights
/// (Poppins renders 1.5 times its point size).
struct AgendaLayout {
  struct FittedGroup {
    let group: AgendaGroup
    let items: [AgendaItem]
    let olderOverdueCount: Int
  }

  static let headerHeight: CGFloat = 15
  static let rowHeight: CGFloat = 36
  static let markerSize: CGFloat = 18
  static let markerColumnWidth: CGFloat = 26
  static let noteHeight: CGFloat = 17
  static let groupSpacing: CGFloat = 6
  static let rowSpacing: CGFloat = 4

  let groups: [FittedGroup]
  let showsNothingUpcoming: Bool
  let showsClass: Bool
  let today: String
  let days: [String: AgendaDay]
  let strings: Bundle

  init(content: AgendaContent, family: WidgetFamily, height: CGFloat) {
    today = content.today
    days = content.days
    strings = content.strings
    showsClass = family.showsDetails

    var remaining = height
    var fitted: [FittedGroup] = []
    var fitsAll = true
    for group in content.groups {
      let olderOverdueCount = group.isOverdue ? content.olderOverdueCount : 0
      let headerCost = Self.headerHeight + (fitted.isEmpty ? 0 : Self.groupSpacing)
      let firstLineCost = Self.rowSpacing + (group.items.isEmpty ? Self.noteHeight : Self.rowHeight)
      guard remaining >= headerCost + firstLineCost else {
        fitsAll = false
        break
      }
      remaining -= headerCost

      var items: [AgendaItem] = []
      for item in group.items {
        guard remaining >= Self.rowSpacing + Self.rowHeight else { break }
        remaining -= Self.rowSpacing + Self.rowHeight
        items.append(item)
      }
      let showsOlder =
        items.count == group.items.count && olderOverdueCount > 0 && remaining >= Self.rowSpacing + Self.noteHeight
      if showsOlder {
        remaining -= Self.rowSpacing + Self.noteHeight
      }
      fitted.append(FittedGroup(group: group, items: items, olderOverdueCount: showsOlder ? olderOverdueCount : 0))
      if items.count < group.items.count || olderOverdueCount > 0 && !showsOlder {
        fitsAll = false
        break
      }
    }
    groups = fitted
    showsNothingUpcoming = !content.hasUpcoming && fitsAll && remaining >= Self.groupSpacing + Self.noteHeight * 2
  }
}

private struct AgendaList: View {
  let layout: AgendaLayout
  let family: WidgetFamily
  let palette: AgendaPalette

  var body: some View {
    VStack(alignment: .leading, spacing: AgendaLayout.groupSpacing) {
      ForEach(layout.groups, id: \.group.id) { fitted in
        VStack(alignment: .leading, spacing: AgendaLayout.rowSpacing) {
          AgendaGroupHeader(group: fitted.group, palette: palette)
          ForEach(fitted.items) { item in
            AgendaRow(
              item: item, today: layout.today, days: layout.days, showsClass: layout.showsClass, family: family,
              palette: palette, strings: layout.strings)
          }
          if fitted.olderOverdueCount > 0 {
            let olderOverdue = String(localized: "\(fitted.olderOverdueCount) older overdue", bundle: layout.strings)
            AgendaNote(
              text: fitted.items.isEmpty
                ? olderOverdue
                : String(localized: "+\(fitted.olderOverdueCount) older overdue", bundle: layout.strings),
              lineLimit: 1, palette: palette)
              .accessibilityLabel(olderOverdue)
              .accessibilityInputLabels([
                Text(olderOverdue), Text(String(localized: "Open Planner", bundle: layout.strings)),
              ])
              .linked(to: AgendaLinks.overdueTodos, in: family)
          }
        }
      }
      if layout.showsNothingUpcoming {
        AgendaNote(
          text: String(localized: "Nothing due in the next 7 days", bundle: layout.strings), lineLimit: 2,
          palette: palette)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct AgendaGroupHeader: View {
  let group: AgendaGroup
  let palette: AgendaPalette

  var body: some View {
    HStack(spacing: 4) {
      if group.isOverdue {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 9, weight: .semibold))
      }
      Text(group.title.uppercased())
        .tracking(0.6)
    }
    .font(AgendaFont.semiBold(10))
    .foregroundStyle(group.isOverdue ? palette.error : palette.muted)
    .frame(height: AgendaLayout.headerHeight)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(group.title)
    .accessibilityAddTraits(.isHeader)
  }
}

/// Touch devices toggle from the whole checkbox column, as the app's Agenda does; with a pointer (the iPad app on a
/// Mac) only the checkbox toggles. The rest of the row opens the assignment.
private struct AgendaRow: View {
  let item: AgendaItem
  let today: String
  let days: [String: AgendaDay]
  let showsClass: Bool
  let family: WidgetFamily
  let palette: AgendaPalette
  let strings: Bundle

  var body: some View {
    HStack(spacing: 0) {
      if item.canToggle {
        if ProcessInfo.processInfo.isiOSAppOnMac {
          checkboxToggle(fillsColumn: false)
            .frame(width: AgendaLayout.markerSize)
          opensItem(details.padding(.leading, AgendaLayout.markerColumnWidth - AgendaLayout.markerSize))
        } else {
          checkboxToggle(fillsColumn: true)
          opensItem(details)
        }
      } else {
        opensItem(
          HStack(spacing: 0) {
            AgendaMarkerColumn {
              AgendaCheckbox(isOn: item.completed, hex: item.color)
                .accessibilityHidden(true)
            }
            details
          })
      }
    }
    .frame(height: AgendaLayout.rowHeight)
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(item.title)
        .font(AgendaFont.medium(13))
        .foregroundStyle(palette.onSurface)
        .strikethrough(item.completed)
        .lineLimit(1)
      secondaryLine
        .font(AgendaFont.regular(11))
        .foregroundStyle(palette.muted)
        .lineLimit(1)
    }
  }

  private var secondaryLine: some View {
    HStack(spacing: 0) {
      if let dayPrefix = item.dayPrefix(today: today, days: days) {
        Text(dayPrefix)
          .layoutPriority(1)
        Text(verbatim: " · \(item.timeLabel)")
          .layoutPriority(2)
      } else {
        Text(item.timeLabel)
          .layoutPriority(2)
      }
      if showsClass, let className = item.className {
        Text(verbatim: " · \(className)")
      }
    }
  }

  private func checkboxToggle(fillsColumn: Bool) -> some View {
    Toggle(isOn: item.completed, intent: BackgroundIntent(url: item.completionURL)) {}
      .toggleStyle(AgendaCheckboxToggleStyle(hex: item.color, fillsColumn: fillsColumn))
      .accessibilityLabel(
        item.completed
          ? String(localized: "Mark \(item.title) not done", bundle: strings)
          : String(localized: "Complete \(item.title)", bundle: strings))
  }

  private func opensItem(_ content: some View) -> some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(([item.title] + item.secondaryParts(today: today, days: days)).joined(separator: ", "))
      .accessibilityValue(item.completed ? String(localized: "Completed", bundle: strings) : "")
      .linked(to: item.url, in: family)
  }
}

private struct AgendaMarkerColumn<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    content
      .frame(width: AgendaLayout.markerSize, height: AgendaLayout.markerSize)
      .frame(width: AgendaLayout.markerColumnWidth, height: AgendaLayout.rowHeight, alignment: .leading)
  }
}

private struct AgendaCheckboxToggleStyle: ToggleStyle {
  let hex: String
  let fillsColumn: Bool

  @ViewBuilder
  func makeBody(configuration: Configuration) -> some View {
    let checkbox = AgendaCheckbox(isOn: configuration.isOn, hex: hex)
    if fillsColumn {
      AgendaMarkerColumn { checkbox }
        .contentShape(Rectangle())
    } else {
      checkbox
        .contentShape(Rectangle())
    }
  }
}

/// A checked box is filled in the class color. In the tinted modes (macOS desktop widgets behind other windows,
/// tinted and clear home screens) every color becomes the tint, so a fill would hide the checkmark; there the box
/// stays an outline and the checkmark takes the tint.
private struct AgendaCheckbox: View {
  let isOn: Bool
  let hex: String

  @Environment(\.colorSchemeContrast) private var contrast
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    let color = Color(hex: hex)
    let isFilled = isOn && renderingMode == .fullColor
    ZStack {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(isFilled ? color : .clear)
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .strokeBorder(color, lineWidth: 2)
      if isOn {
        Image(systemName: "checkmark")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(isFilled ? ContrastingInk.color(onHex: hex, contrast: contrast) : color)
      }
    }
    .frame(width: 16, height: 16)
  }
}

private extension Image {
  /// Keeps the image's detail in grayscale in the tinted modes, where an image is otherwise drawn as a solid shape.
  @ViewBuilder
  func desaturatedWhenAccented() -> some View {
    if #available(iOS 18, *) {
      widgetAccentedRenderingMode(.desaturated)
    } else {
      self
    }
  }
}

private struct AgendaNote: View {
  let text: String
  let lineLimit: Int
  let palette: AgendaPalette

  var body: some View {
    Text(text)
      .font(AgendaFont.regular(11))
      .foregroundStyle(palette.muted)
      .lineLimit(lineLimit)
      .frame(minHeight: AgendaLayout.noteHeight, alignment: .leading)
  }
}

private extension WidgetFamily {
  var showsDetails: Bool { self != .systemSmall }
}

private extension View {
  /// Small widgets take one tap target, the widget URL; the others open each link.
  @ViewBuilder
  func linked(to url: URL, in family: WidgetFamily) -> some View {
    if family == .systemSmall {
      self
    } else {
      Link(destination: url) { self }
    }
  }
}

// MARK: - Lock screen

private struct AgendaRectangularView: View {
  let entry: AgendaEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch entry.state {
      case .missing:
        Text(verbatim: "Helium").font(.headline).widgetAccentable()
        Text(String(localized: "Open Helium to see what's due", bundle: entry.strings)).font(.caption)
      case .signedOut:
        Text(verbatim: "Helium").font(.headline).widgetAccentable()
        Text(String(localized: "Sign in to Helium", bundle: entry.strings)).font(.caption)
      case .loaded:
        if let content = entry.content,
          let group = content.groups.first(where: { !$0.items.isEmpty }) ?? content.groups.first
        {
          let olderOverdueCount = group.isOverdue && !group.items.isEmpty ? content.olderOverdueCount : 0
          HStack(spacing: 3) {
            if group.isOverdue {
              Image(systemName: "exclamationmark.triangle.fill")
            }
            Text(group.title)
            if olderOverdueCount > 0 {
              Text(String(localized: "+\(olderOverdueCount) older", bundle: entry.strings))
            }
          }
          .font(.headline)
          .widgetAccentable()
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            olderOverdueCount > 0
              ? String(localized: "\(group.title), \(olderOverdueCount) older overdue", bundle: entry.strings)
              : group.title)
          if let item = group.items.first(where: { !$0.completed }) ?? group.items.first {
            Text(item.title)
              .font(.body)
              .lineLimit(1)
            let more = content.groups.flatMap(\.items).filter { !$0.completed && $0.key != item.key }.count
            Text(
              more > 0
                ? String(localized: "\(more) more", bundle: entry.strings)
                : item.secondaryLine(today: content.today, days: content.days))
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else if group.isOverdue && content.olderOverdueCount > 0 {
            Text(String(localized: "\(content.olderOverdueCount) older overdue", bundle: entry.strings))
              .font(.body)
              .lineLimit(1)
          }
        } else {
          Label(String(localized: "All caught up", bundle: entry.strings), systemImage: "checkmark.circle")
            .font(.headline)
            .widgetAccentable()
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(entry.content == nil ? nil : AgendaLinks.planner)
  }
}

private struct AgendaInlineView: View {
  let entry: AgendaEntry

  var body: some View {
    Text(summary)
      .widgetURL(entry.content == nil ? nil : AgendaLinks.planner)
  }

  private var summary: String {
    switch entry.state {
    case .missing: return String(localized: "Open Helium", bundle: entry.strings)
    case .signedOut: return String(localized: "Sign in to Helium", bundle: entry.strings)
    case .loaded:
      guard let content = entry.content else { return String(localized: "All caught up", bundle: entry.strings) }
      if content.overdueCount > 0 { return String(localized: "\(content.overdueCount) overdue", bundle: entry.strings) }
      for group in content.groups {
        let due = group.items.filter { !$0.completed }.count
        if due > 0 { return String(localized: "\(group.title) · \(due) due", bundle: entry.strings) }
      }
      return String(localized: "All caught up", bundle: entry.strings)
    }
  }
}

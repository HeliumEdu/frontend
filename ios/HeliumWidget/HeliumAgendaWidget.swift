import SwiftUI
import WidgetKit

@main
struct HeliumAgendaWidget: Widget {
  let kind = HeliumAppGroup.agendaWidgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AgendaProvider()) { entry in
      AgendaWidgetView(entry: entry)
    }
    .configurationDisplayName("Agenda")
    .description("See what's due this week, and check off assignments right from your home screen.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
  }
}

#Preview("Small", as: .systemSmall) {
  HeliumAgendaWidget()
} timeline: {
  AgendaEntry.sample
}

#Preview("Medium", as: .systemMedium) {
  HeliumAgendaWidget()
} timeline: {
  AgendaEntry.sample
  AgendaEntry(date: .now, state: .signedOut(language: nil))
}

#Preview("Large", as: .systemLarge) {
  HeliumAgendaWidget()
} timeline: {
  AgendaEntry.sample
}

#Preview("Lock screen", as: .accessoryRectangular) {
  HeliumAgendaWidget()
} timeline: {
  AgendaEntry.sample
}

#Preview("Inline", as: .accessoryInline) {
  HeliumAgendaWidget()
} timeline: {
  AgendaEntry.sample
}

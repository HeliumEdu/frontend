package com.heliumedu.heliumapp.widget

import java.time.Duration
import java.time.Instant
import java.time.LocalDate

/** Groups a snapshot at the moment the widget renders, so it stays right between the app's writes. */
object AgendaGrouping {
    val STALE_AFTER: Duration = Duration.ofHours(24)
    private const val HORIZON_DAYS = 14L

    fun groups(snapshot: AgendaSnapshot, now: Instant): List<AgendaGroup> {
        val today = now.atZone(snapshot.timeZone).toLocalDate()
        val (overdue, upcoming) = snapshot.items
            .filterNot { it.completed && it.start.isBefore(now) }
            .partition { !it.completed && it.start.isBefore(now) }
        val overdueGroups = if (overdue.isEmpty() && snapshot.olderOverdueCount == 0) {
            emptyList()
        } else {
            listOf(AgendaGroup(AgendaGroup.Kind.OVERDUE, overdue))
        }
        val dayGroups = upcoming
            .groupBy { it.day }
            .toSortedMap()
            .map { (day, items) ->
                val kind = when (day) {
                    today -> AgendaGroup.Kind.TODAY
                    today.plusDays(1) -> AgendaGroup.Kind.TOMORROW
                    else -> AgendaGroup.Kind.LATER
                }
                AgendaGroup(kind, items)
            }
        return overdueGroups + dayGroups
    }

    fun laterTitle(day: LocalDate, today: LocalDate, names: AgendaDay): String =
        if (day.isBefore(today.plusDays(7))) names.weekday else names.date

    /** The instants at which [groups] or the staleness footer changes. */
    fun refreshTimes(snapshot: AgendaSnapshot, now: Instant): List<Instant> {
        val today = now.atZone(snapshot.timeZone).toLocalDate()
        val horizon = now.plus(Duration.ofDays(HORIZON_DAYS))
        val midnights = (1..HORIZON_DAYS).map { today.plusDays(it).atStartOfDay(snapshot.timeZone).toInstant() }
        val staleMarks = (1..HORIZON_DAYS).map { snapshot.generatedAt.plus(STALE_AFTER.multipliedBy(it)) }
        val itemTransitions = snapshot.items.map { it.start }
        return (midnights + staleMarks + itemTransitions)
            .filter { it.isAfter(now) && !it.isAfter(horizon) }
            .distinct()
            .sorted()
    }
}

package com.heliumedu.heliumapp.widget

import android.graphics.Color
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import org.json.JSONArray
import org.json.JSONObject

/** The snapshot the app writes under [SNAPSHOT_KEY]; see `AgendaWidgetService` on the Dart side. */
data class AgendaSnapshot(
    val signedIn: Boolean,
    val generatedAt: Instant,
    val timeZone: ZoneId,
    val olderOverdueCount: Int,
    val days: Map<LocalDate, AgendaDay>,
    val items: List<AgendaItem>,
) {
    companion object {
        const val SNAPSHOT_KEY = "agenda_snapshot"
        private const val SUPPORTED_VERSION = 1

        fun parse(json: String): AgendaSnapshot? {
            val root = JSONObject(json)
            if (root.getInt("version") != SUPPORTED_VERSION) return null
            return AgendaSnapshot(
                signedIn = root.getBoolean("signedIn"),
                generatedAt = Instant.parse(root.getString("generatedAt")),
                timeZone = ZoneId.of(root.getString("timeZone")),
                olderOverdueCount = root.getInt("olderOverdueCount"),
                days = root.optJSONObject("days")?.let(AgendaDay::parseAll).orEmpty(),
                items = root.getJSONArray("items").objects().map(AgendaItem::parse),
            )
        }
    }
}

/** A day's names as the app formats them, so the widget never formats dates itself. */
data class AgendaDay(val weekday: String, val date: String) {
    companion object {
        fun parseAll(json: JSONObject): Map<LocalDate, AgendaDay> = json.keys().asSequence().associate { day ->
            val names = json.getJSONObject(day)
            LocalDate.parse(day) to AgendaDay(weekday = names.getString("weekday"), date = names.getString("date"))
        }
    }
}

data class AgendaItem(
    val key: String,
    val title: String,
    val start: Instant,
    val day: LocalDate,
    val timeLabel: String,
    val className: String?,
    val color: Int,
    val completed: Boolean,
    val repeating: Boolean,
    val url: String,
) {
    companion object {
        fun parse(json: JSONObject) = AgendaItem(
            key = json.getString("key"),
            title = json.getString("title"),
            start = Instant.parse(json.getString("start")),
            day = LocalDate.parse(json.getString("day")),
            timeLabel = json.getString("timeLabel"),
            className = if (json.isNull("className")) null else json.getString("className"),
            color = Color.parseColor(json.getString("color")),
            completed = json.getBoolean("completed"),
            repeating = json.getBoolean("repeating"),
            url = json.getString("url"),
        )
    }

    /** A repeating occurrence completes by splitting off, which the widget cannot undo. */
    val canToggle: Boolean get() = !(completed && repeating)
}

data class AgendaGroup(val kind: Kind, val items: List<AgendaItem>) {
    enum class Kind { OVERDUE, TODAY, TOMORROW, LATER }
}

internal fun JSONArray.objects(): List<JSONObject> = (0 until length()).map(::getJSONObject)

package com.heliumedu.heliumapp.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.annotation.ColorRes
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.heliumedu.heliumapp.MainActivity
import com.heliumedu.heliumapp.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetScheduler
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

private val SMALL = DpSize(110.dp, 110.dp)
private val SMALL_TALL = DpSize(110.dp, 160.dp)
private val MEDIUM = DpSize(180.dp, 110.dp)
private val LARGE = DpSize(250.dp, 180.dp)

private val onSurfaceColor = ColorProvider(R.color.agenda_widget_on_surface)
private val mutedColor = ColorProvider(R.color.agenda_widget_on_surface_muted)
private val errorColor = ColorProvider(R.color.agenda_widget_error)

private val isNarrow: Boolean
    @Composable get() = LocalSize.current.width < MEDIUM.width


class AgendaWidget : GlanceAppWidget() {
    companion object {
        const val URL_SCHEME = "heliumwidget"
        const val PLANNER_URL = "$URL_SCHEME://open/planner"
        const val OVERDUE_URL = "$PLANNER_URL?view=todos&status=overdue"
    }

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, SMALL_TALL, MEDIUM, LARGE))

    override val previewSizeMode = sizeMode

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = AgendaStore.read(currentState<HomeWidgetGlanceState>().preferences)
            val now = Instant.now()
            LaunchedEffect(state) { scheduleRefreshes(context, state, now) }
            AgendaContent(state, now)
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent {
            val now = LocalDate.now().atTime(8, 0).atZone(ZoneId.systemDefault())
            AgendaContent(AgendaStore.State.Ready(sampleSnapshot(context, now)), now.toInstant())
        }
    }

    private fun scheduleRefreshes(context: Context, state: AgendaStore.State, now: Instant) {
        val receiver = AgendaWidgetReceiver::class.java.name
        if (state is AgendaStore.State.Ready) {
            HomeWidgetScheduler.schedule(
                context,
                receiver,
                AgendaGrouping.refreshTimes(state.snapshot, now).map(Instant::toEpochMilli),
            )
        } else {
            HomeWidgetScheduler.cancel(context, receiver)
        }
    }

    private fun sampleSnapshot(context: Context, now: ZonedDateTime): AgendaSnapshot = AgendaSnapshot(
        signedIn = true,
        generatedAt = now.toInstant(),
        timeZone = now.zone,
        olderOverdueCount = 2,
        days = (-1L..4L).associate { offset ->
            val day = now.toLocalDate().plusDays(offset)
            day to AgendaDay(
                weekday = day.format(DateTimeFormatter.ofPattern("EEEE", Locale.US)),
                date = day.format(DateTimeFormatter.ofPattern("EEE, MMM d", Locale.US)),
            )
        },
        items = listOf(
            sampleItem(context, now, 1, R.string.agenda_widget_sample_case_study, -1, SampleTime.AFTERNOON, SampleCourse.PSYCHOLOGY),
            sampleItem(
                context, now, 2, R.string.agenda_widget_sample_programming_quiz, 0, SampleTime.MORNING, SampleCourse.PROGRAMMING,
                completed = true,
            ),
            sampleItem(context, now, 3, R.string.agenda_widget_sample_short_stories, 0, SampleTime.MORNING, SampleCourse.WRITING),
            sampleItem(context, now, 4, R.string.agenda_widget_sample_psychology_quiz, 1, SampleTime.AFTERNOON, SampleCourse.PSYCHOLOGY),
            sampleItem(context, now, 5, R.string.agenda_widget_sample_essay, 2, SampleTime.MORNING, SampleCourse.WRITING),
            sampleItem(context, now, 6, R.string.agenda_widget_sample_homework, 3, SampleTime.MORNING, SampleCourse.PROGRAMMING),
            sampleItem(context, now, 7, R.string.agenda_widget_sample_reading, 4, SampleTime.ALL_DAY, SampleCourse.WRITING),
        ),
    )

    private fun sampleItem(
        context: Context,
        now: ZonedDateTime,
        id: Int,
        @StringRes title: Int,
        daysFromToday: Long,
        time: SampleTime,
        course: SampleCourse,
        completed: Boolean = false,
    ): AgendaItem {
        val start = now.toLocalDate().plusDays(daysFromToday).atTime(time.at).atZone(now.zone)
        return AgendaItem(
            key = "homework:$id",
            title = context.getString(title),
            start = start.toInstant(),
            day = start.toLocalDate(),
            timeLabel = context.getString(time.label),
            className = context.getString(course.title),
            color = context.getColor(course.color),
            completed = completed,
            repeating = false,
            url = PLANNER_URL,
        )
    }

    private enum class SampleCourse(@StringRes val title: Int, @ColorRes val color: Int) {
        WRITING(R.string.agenda_widget_sample_writing, R.color.agenda_widget_sample_writing),
        PROGRAMMING(R.string.agenda_widget_sample_programming, R.color.agenda_widget_sample_programming),
        PSYCHOLOGY(R.string.agenda_widget_sample_psychology, R.color.agenda_widget_sample_psychology),
    }

    private enum class SampleTime(val at: LocalTime, @StringRes val label: Int) {
        MORNING(LocalTime.of(11, 0), R.string.agenda_widget_sample_morning),
        AFTERNOON(LocalTime.of(13, 0), R.string.agenda_widget_sample_afternoon),
        ALL_DAY(LocalTime.MIDNIGHT, R.string.agenda_widget_sample_all_day),
    }
}

@Composable
private fun AgendaContent(state: AgendaStore.State, now: Instant) {
    val context = LocalContext.current
    val openApp = actionStartActivity(Intent(context, MainActivity::class.java))
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(ImageProvider(R.drawable.agenda_widget_background))
            .padding(12.dp),
    ) {
        Header(today = (state as? AgendaStore.State.Ready)?.snapshot?.let { it.days[now.atZone(it.timeZone).toLocalDate()] })
        when (state) {
            AgendaStore.State.Missing -> Message(R.string.agenda_widget_no_snapshot, openApp)
            AgendaStore.State.SignedOut -> Message(R.string.agenda_widget_signed_out, openApp)
            is AgendaStore.State.Ready -> Agenda(state.snapshot, now)
        }
    }
}

@Composable
private fun Header(today: AgendaDay?) {
    val context = LocalContext.current
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(start = 2.dp, bottom = 4.dp)
            .clickable(openUrlAction(context, AgendaWidget.PLANNER_URL))
            .semantics { contentDescription = context.getString(R.string.agenda_widget_open_planner) },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(R.mipmap.ic_launcher),
            contentDescription = null,
            modifier = GlanceModifier.size(22.dp),
        )
        Spacer(GlanceModifier.width(8.dp))
        Text(
            text = context.getString(R.string.agenda_widget_label),
            style = TextStyle(color = onSurfaceColor, fontSize = 18.sp, fontFamily = FontFamily.Serif),
            modifier = GlanceModifier.defaultWeight(),
            maxLines = 1,
        )
        if (today != null && !isNarrow) {
            Text(
                text = today.date,
                style = TextStyle(color = mutedColor, fontSize = 12.sp),
                modifier = GlanceModifier.padding(start = 8.dp),
                maxLines = 1,
            )
        }
    }
}

@Composable
private fun ColumnScope.Message(@StringRes message: Int, onClick: Action) {
    val context = LocalContext.current
    Box(
        modifier = GlanceModifier.defaultWeight().fillMaxWidth().clickable(onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = context.getString(message),
            style = TextStyle(color = mutedColor, fontSize = 14.sp, textAlign = TextAlign.Center),
        )
    }
}

@Composable
private fun ColumnScope.Agenda(snapshot: AgendaSnapshot, now: Instant) {
    val context = LocalContext.current
    val groups = AgendaGrouping.groups(snapshot, now)
    val today = now.atZone(snapshot.timeZone).toLocalDate()
    val lines = agendaLines(groups, snapshot.olderOverdueCount)

    if (groups.isEmpty()) {
        Message(R.string.agenda_widget_all_caught_up, openUrlAction(context, AgendaWidget.PLANNER_URL))
    } else {
        LazyColumn(modifier = GlanceModifier.defaultWeight().fillMaxWidth()) {
            items(lines) { AgendaLineRow(it, today, snapshot.days, showsClass = !isNarrow) }
        }
    }

    val age = Duration.between(snapshot.generatedAt, now)
    if (age > AgendaGrouping.STALE_AFTER) {
        val days = age.toDays()
        Text(
            text = context.getString(R.string.agenda_widget_updated_days_ago, days),
            style = TextStyle(color = mutedColor, fontSize = 11.sp),
            modifier = GlanceModifier
                .padding(start = 2.dp, top = 4.dp)
                .semantics {
                    contentDescription = context.resources.getQuantityString(
                        R.plurals.agenda_widget_updated_days_ago_description,
                        days.toInt(),
                        days,
                    )
                },
            maxLines = 1,
        )
    }
}

private sealed interface AgendaLine {
    data class Header(val group: AgendaGroup) : AgendaLine
    data class Item(val item: AgendaItem) : AgendaLine
    data class OlderOverdue(val count: Int) : AgendaLine
    data object NothingUpcoming : AgendaLine
}

private fun agendaLines(groups: List<AgendaGroup>, olderOverdueCount: Int): List<AgendaLine> {
    val groupLines = groups.flatMap { group ->
        val olderOverdue = AgendaLine.OlderOverdue(olderOverdueCount)
            .takeIf { group.kind == AgendaGroup.Kind.OVERDUE && olderOverdueCount > 0 }
        listOf(AgendaLine.Header(group)) + group.items.map(AgendaLine::Item) + listOfNotNull(olderOverdue)
    }
    val nothingUpcoming = AgendaLine.NothingUpcoming.takeIf { groups.all { it.kind == AgendaGroup.Kind.OVERDUE } }
    return groupLines + listOfNotNull(nothingUpcoming)
}

@Composable
private fun AgendaLineRow(line: AgendaLine, today: LocalDate, days: Map<LocalDate, AgendaDay>, showsClass: Boolean) {
    when (line) {
        is AgendaLine.Header -> GroupHeader(line.group, today, days)
        is AgendaLine.Item -> ItemRow(line.item, today, days, showsClass)
        is AgendaLine.OlderOverdue -> OlderOverdueRow(line.count)
        AgendaLine.NothingUpcoming -> NothingUpcomingRow()
    }
}

@Composable
private fun GroupHeader(group: AgendaGroup, today: LocalDate, days: Map<LocalDate, AgendaDay>) {
    val context = LocalContext.current
    val overdue = group.kind == AgendaGroup.Kind.OVERDUE
    val title = when (group.kind) {
        AgendaGroup.Kind.OVERDUE -> context.getString(R.string.agenda_widget_overdue)
        AgendaGroup.Kind.TODAY -> context.getString(R.string.agenda_widget_today)
        AgendaGroup.Kind.TOMORROW -> context.getString(R.string.agenda_widget_tomorrow)
        AgendaGroup.Kind.LATER -> group.items.first().day.let { AgendaGrouping.laterTitle(it, today, days.getValue(it)) }
    }

    Row(
        modifier = GlanceModifier.fillMaxWidth().padding(start = 2.dp, top = 6.dp, bottom = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (overdue) {
            Image(
                provider = ImageProvider(R.drawable.agenda_widget_warning),
                contentDescription = null,
                modifier = GlanceModifier.size(12.dp),
                colorFilter = ColorFilter.tint(errorColor),
            )
            Spacer(GlanceModifier.width(4.dp))
        }
        Text(
            text = title.uppercase(Locale.getDefault()),
            style = TextStyle(color = if (overdue) errorColor else mutedColor, fontSize = 11.sp, fontWeight = FontWeight.Bold),
            modifier = GlanceModifier.defaultWeight().semantics { contentDescription = title },
            maxLines = 1,
        )
    }
}

@Composable
private fun ItemRow(item: AgendaItem, today: LocalDate, days: Map<LocalDate, AgendaDay>, showsClass: Boolean) {
    val context = LocalContext.current
    val earlierDay = days.getValue(item.day).date.takeIf { item.day.isBefore(today) }
    val details = listOfNotNull(earlierDay, item.timeLabel, item.className.takeIf { showsClass })
    val description = (
        listOf(item.title) +
            details +
            listOfNotNull(context.getString(R.string.agenda_widget_completed).takeIf { item.completed })
        ).joinToString(", ")

    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .clickable(openUrlAction(context, item.url))
            .semantics { contentDescription = description },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Checkbox(item)
        Column(modifier = GlanceModifier.defaultWeight().padding(start = 4.dp, top = 2.dp, bottom = 2.dp)) {
            Text(
                text = item.title,
                style = TextStyle(
                    color = onSurfaceColor,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    textDecoration = if (item.completed) TextDecoration.LineThrough else TextDecoration.None,
                ),
                maxLines = 1,
            )
            Text(text = details.joinToString(" · "), style = TextStyle(color = mutedColor, fontSize = 12.sp), maxLines = 1)
        }
    }
}

@Composable
private fun Checkbox(item: AgendaItem) {
    val context = LocalContext.current
    val itemColor = ColorProvider(Color(item.color))
    val modifier = GlanceModifier.width(36.dp).fillMaxHeight().let {
        if (!item.canToggle) return@let it
        val description = context.getString(
            if (item.completed) R.string.agenda_widget_uncomplete else R.string.agenda_widget_complete,
            item.title,
        )
        it.clickable(actionRunCallback<CompleteAction>(actionParametersOf(CompleteAction.keyParameter to item.key)))
            .semantics { contentDescription = description }
    }

    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        if (item.completed) {
            Image(
                provider = ImageProvider(R.drawable.agenda_widget_checkbox_filled),
                contentDescription = null,
                modifier = GlanceModifier.size(18.dp),
                colorFilter = ColorFilter.tint(itemColor),
            )
            Image(
                provider = ImageProvider(R.drawable.agenda_widget_check),
                contentDescription = null,
                modifier = GlanceModifier.size(14.dp),
                colorFilter = ColorFilter.tint(ColorProvider(contrastingColor(item.color))),
            )
        } else {
            Image(
                provider = ImageProvider(R.drawable.agenda_widget_checkbox_outline),
                contentDescription = null,
                modifier = GlanceModifier.size(18.dp),
                colorFilter = ColorFilter.tint(itemColor),
            )
        }
    }
}

@Composable
private fun OlderOverdueRow(count: Int) {
    val context = LocalContext.current
    Text(
        text = context.getString(R.string.agenda_widget_older_overdue, count),
        style = TextStyle(color = mutedColor, fontSize = 12.sp, fontWeight = FontWeight.Medium),
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(start = 2.dp, top = 4.dp, bottom = 4.dp)
            .clickable(openUrlAction(context, AgendaWidget.OVERDUE_URL))
            .semantics { contentDescription = context.getString(R.string.agenda_widget_older_overdue_description, count) },
        maxLines = 1,
    )
}

@Composable
private fun NothingUpcomingRow() {
    Text(
        text = LocalContext.current.getString(R.string.agenda_widget_nothing_upcoming),
        style = TextStyle(color = mutedColor, fontSize = 12.sp),
        modifier = GlanceModifier.fillMaxWidth().padding(start = 2.dp, top = 8.dp),
        maxLines = 2,
    )
}

private fun openUrlAction(context: Context, url: String): Action =
    actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url), context, MainActivity::class.java))

/** Mirrors the app's `HeliumColors.contrastingTextColor`. */
private fun contrastingColor(color: Int): Color =
    if (android.graphics.Color.luminance(color) > 0.5f) Color.Black else Color.White

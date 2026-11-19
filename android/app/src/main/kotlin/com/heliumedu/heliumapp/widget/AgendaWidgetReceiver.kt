package com.heliumedu.heliumapp.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class AgendaWidgetReceiver : HomeWidgetGlanceWidgetReceiver<AgendaWidget>() {
    override val glanceAppWidget = AgendaWidget()

    /** The gallery preview is sample data, never the user's planner; change the fingerprint when the sample changes. */
    override fun previewFingerprint(context: Context): String = "sample-6"
}

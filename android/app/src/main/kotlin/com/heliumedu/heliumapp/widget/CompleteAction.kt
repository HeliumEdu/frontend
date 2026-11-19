package com.heliumedu.heliumapp.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.updateAll
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class CompleteAction : ActionCallback {
    companion object {
        val keyParameter = ActionParameters.Key<String>("key")
    }

    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val key = checkNotNull(parameters[keyParameter])
        val completed = AgendaStore.toggleCompleted(context, key) ?: return
        AgendaWidget().updateAll(context)

        val uri = Uri.Builder()
            .scheme(AgendaWidget.URL_SCHEME)
            .authority("complete")
            .appendQueryParameter("key", key)
            .appendQueryParameter("completed", completed.toString())
            .build()
        HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
    }
}

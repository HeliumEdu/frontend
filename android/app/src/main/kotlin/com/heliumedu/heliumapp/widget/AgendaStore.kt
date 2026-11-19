package com.heliumedu.heliumapp.widget

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.DateTimeException
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONException
import org.json.JSONObject

object AgendaStore {
    private const val TAG = "AgendaWidget"
    private val writeLock = Mutex()

    sealed interface State {
        data object Missing : State
        data object SignedOut : State
        data class Ready(val snapshot: AgendaSnapshot) : State
    }

    fun read(preferences: SharedPreferences): State {
        val json = preferences.getString(AgendaSnapshot.SNAPSHOT_KEY, null) ?: return State.Missing
        val snapshot = try {
            AgendaSnapshot.parse(json)
        } catch (e: Exception) {
            if (e !is JSONException && e !is DateTimeException && e !is IllegalArgumentException) throw e
            Log.e(TAG, "Unreadable agenda snapshot", e)
            null
        }
        return when {
            snapshot == null -> State.Missing
            !snapshot.signedIn -> State.SignedOut
            else -> State.Ready(snapshot)
        }
    }

    /**
     * Flips [key] done (or not) right away and returns its new state, or `null` when it is no longer in the snapshot;
     * the app's interactivity callback then saves it or reverts.
     */
    suspend fun toggleCompleted(context: Context, key: String): Boolean? = writeLock.withLock {
        val preferences = HomeWidgetPlugin.getData(context)
        val json = preferences.getString(AgendaSnapshot.SNAPSHOT_KEY, null) ?: return null
        val root = JSONObject(json)
        val item = root.getJSONArray("items").objects().firstOrNull { it.getString("key") == key } ?: return null
        val completed = !item.getBoolean("completed")
        item.put("completed", completed)
        preferences.edit().putString(AgendaSnapshot.SNAPSHOT_KEY, root.toString()).commit()
        completed
    }
}

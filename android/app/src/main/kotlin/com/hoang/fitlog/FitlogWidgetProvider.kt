package com.hoang.fitlog

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

/**
 * Daily-summary home widget (4x2). Data is pushed from Dart via the
 * `home_widget` plugin into the "HomeWidgetPreferences" SharedPreferences file.
 * Quick actions deep-link into the app (fitlog://app/<route>).
 */
class FitlogWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) update(context, mgr, id)
    }

    companion object {
        private fun prefs(context: Context) =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, FitlogWidgetProvider::class.java)
            )
            ids.forEach { update(context, mgr, it) }
        }

        private fun update(context: Context, mgr: AppWidgetManager, id: Int) {
            val p = prefs(context)
            val views = RemoteViews(context.packageName, R.layout.widget_daily)

            views.setTextViewText(R.id.w_title, "Today")
            views.setTextViewText(R.id.w_eaten, "${p.getString("caloriesEaten", "0")} eaten")
            views.setTextViewText(R.id.w_burned, "${p.getString("burned", "0")} burned")
            views.setTextViewText(R.id.w_left, "${p.getString("caloriesLeft", "—")} kcal left")
            views.setTextViewText(R.id.w_protein, "Protein ${p.getString("protein", "0")}/${p.getString("proteinTarget", "0")} g")
            views.setTextViewText(R.id.w_weight, "${p.getString("weight", "—")} kg")
            views.setProgressBar(R.id.w_progress, 100,
                p.getString("ringProgress", "0")!!.toIntOrNull() ?: 0, false)

            views.setOnClickPendingIntent(R.id.w_root, openDeepLink(context, "fitlog://app/"))
            views.setOnClickPendingIntent(R.id.w_a_food, openDeepLink(context, "fitlog://app/food/add"))
            views.setOnClickPendingIntent(R.id.w_a_workout, openDeepLink(context, "fitlog://app/workout/add"))
            views.setOnClickPendingIntent(R.id.w_a_weight, openDeepLink(context, "fitlog://app/weight/add"))
            views.setOnClickPendingIntent(R.id.w_a_water, openDeepLink(context, "fitlog://app/water/quick"))

            mgr.updateAppWidget(id, views)
        }

        private fun openDeepLink(context: Context, url: String): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                setPackage(context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            return PendingIntent.getActivity(
                context, url.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}

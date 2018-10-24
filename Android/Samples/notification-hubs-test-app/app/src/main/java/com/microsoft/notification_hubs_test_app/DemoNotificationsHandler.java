package com.microsoft.notification_hubs_test_app;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import com.microsoft.windowsazure.notifications.NotificationsHandler;

public class DemoNotificationsHandler extends NotificationsHandler {
    public static final int NOTIFICATION_ID = 1;

    private NotificationManager mNotificationManager;

    @Override
    public void onReceive(Context context, Bundle bundle) {
        if (mNotificationManager == null) {
            mNotificationManager = context.getSystemService(NotificationManager.class);
        }

        String nhMessage = bundle.getString("message");
        sendNotification(context, nhMessage);

        if (MainActivity.isVisible) {
            MainActivity.mainActivity.ToastNotify(nhMessage);
        }
    }

    private void sendNotification(Context context, String msg) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0,
                intent, PendingIntent.FLAG_ONE_SHOT);

        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(
                context,
                NotificationHelper.NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Notification Hubs Notification")
                .setSmallIcon(android.R.drawable.stat_notify_more)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true);

        mNotificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
    };
}
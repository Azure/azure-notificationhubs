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

        NotificationData notificationData = new NotificationData(bundle);

        mNotificationManager.notify(NOTIFICATION_ID, notificationData.createNotification(context));

        if (MainActivity.isVisible) {
            MainActivity.mainActivity.ToastNotify(notificationData.getMessage());
        }
    }
}
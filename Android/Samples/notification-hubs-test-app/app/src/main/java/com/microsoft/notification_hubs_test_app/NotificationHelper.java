package com.microsoft.notification_hubs_test_app;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import com.microsoft.windowsazure.notifications.NotificationsManager;

public class NotificationHelper {
    public static final String NOTIFICATION_CHANNEL_ID = "nh-demo-channel-id";
    public static final String NOTIFICATION_CHANNEL_NAME = "Notification Hubs Demo Channel";
    public static final String NOTIFICATION_CHANNEL_DESCRIPTION = "Notification Hubs Demo Channel";

    public static void createChannelAndHandleNotifications(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription(NOTIFICATION_CHANNEL_DESCRIPTION);
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);

            NotificationsManager.handleNotifications(context, NotificationSettings.SenderId, DemoNotificationsHandler.class);
        }
    }

}

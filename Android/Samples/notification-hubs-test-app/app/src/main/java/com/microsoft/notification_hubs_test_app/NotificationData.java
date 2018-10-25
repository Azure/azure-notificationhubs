package com.microsoft.notification_hubs_test_app;

import android.app.Notification;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;

public class NotificationData {
    public enum CustomActionType {
        SNOOZE,
        DISMISS
    }

    public enum CustomAudioType {
        ALARM,
        NOTIFICATION,
        RINGTONE
    }

    public enum MessageSize {
        REGULAR,
        LARGE
    }

    private final String message;
    private final String title;
//    private final Integer badgeCount;
//    private final CustomActionType customAction;
//    private final CustomAudioType customAudio;
//    private final boolean includePicture;
//    private final MessageSize messageSize;
//    private final Integer timeoutSec;

    public NotificationData(Bundle notificationBundle) {
        message = notificationBundle.getString("message");
        title = notificationBundle.containsKey("title") ? notificationBundle.getString("title") : "Default notification title";
    }

    public Notification createNotification(Context context) {
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(
                context,
                NotificationHelper.NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(android.R.drawable.stat_notify_more)
                .setDefaults(NotificationCompat.DEFAULT_ALL);

        return notificationBuilder.build();
    }

    public String getMessage() {
        return this.message;
    }

}

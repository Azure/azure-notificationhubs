package com.microsoft.notification_hubs_test_app;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
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
    private final Integer badgeCount;
    private final CustomActionType customAction;
    private final CustomAudioType customAudio;
//    private final boolean includePicture;
//    private final MessageSize messageSize;
    private final Integer timeoutMs;

    public NotificationData(Bundle notificationBundle) {
        this.message = notificationBundle.getString("message");
        this.title = notificationBundle.getString("title", "Default notification title");
        this.badgeCount = notificationBundle.containsKey("badgeCount") ?
                Integer.parseInt(notificationBundle.getString("badgeCount")) : null;
        this.customAction = notificationBundle.containsKey("customAction") ?
                parseCustomAction(notificationBundle.getString("customAction")) : null;
        this.customAudio = notificationBundle.containsKey("customAudio") ?
                parseCustomAudio(notificationBundle.getString("customAudio")) : null;
        this.timeoutMs = notificationBundle.containsKey("timeoutMs") ?
                Integer.parseInt(notificationBundle.getString("timeoutMs")) : null;
    }

    private CustomActionType parseCustomAction(String customActionString) {
        switch (customActionString) {
            case "snooze":
                return CustomActionType.SNOOZE;

            case "dismiss":
                return CustomActionType.DISMISS;

            default:
                return null;
        }
    }

    private CustomAudioType parseCustomAudio(String customAudioString) {
        switch (customAudioString) {
            case "alarm":
                return CustomAudioType.ALARM;

            case "notification":
                return CustomAudioType.NOTIFICATION;

            case "ringtone":
                return CustomAudioType.RINGTONE;

            default:
                return null;
        }
    }

    public Notification createNotification(Context context) {
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(
                context,
                NotificationHelper.NOTIFICATION_CHANNEL_ID)
                .setContentTitle(this.title)
                .setContentText(this.message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL);

        if (this.customAction != null) {
            Intent customActionIntent = new Intent(context, NotificationButtonsHandler.class);
            PendingIntent customActionPendingIntent =
                    PendingIntent.getBroadcast(context, 0, customActionIntent, 0);

            String title = customAction == CustomActionType.DISMISS ? "Dismiss" : "Snooze";
            notificationBuilder.addAction(
                    android.R.drawable.ic_popup_reminder,
                    title,
                    customActionPendingIntent);
        }

        if (this.badgeCount != null) {
            notificationBuilder.setNumber(this.badgeCount);
        }

        if (this.timeoutMs != null) {
            notificationBuilder.setTimeoutAfter(this.timeoutMs);
        }

        if (this.customAudio != null) {
            Uri soundUri = null;

            switch (this.customAudio) {
                case ALARM:
                    soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
                    break;

                case NOTIFICATION:
                    soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
                    break;

                case RINGTONE:
                    soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE);
                    break;
            }

            notificationBuilder.setSound(soundUri);
        }

        return notificationBuilder.build();
    }

    public String getMessage() {
        return this.message;
    }

}

package com.microsoft.notification_hubs_test_app;

import android.app.IntentService;
import android.content.Intent;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import com.microsoft.windowsazure.messaging.NotificationHub;

public class UnregistrationIntentService extends IntentService {

    public static final String TAGS_KEY = "Tags";
    private static final String TAG = "UnregIntentService";

    public UnregistrationIntentService() {
        super(TAG);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);

        try {
            NotificationHub hub = new NotificationHub(BuildConfig.hubName,
                    BuildConfig.hubListenConnectionString, this);
            hub.unregister();
            sharedPreferences.edit().remove("registrationID").apply();
            sharedPreferences.edit().remove("FCMtoken").apply();

            if (MainActivity.isVisible) {
                MainActivity.mainActivity.ToastNotify("Unregistered from Notification Hubs");
            }
        }
        catch (Exception ex) {
            if (MainActivity.isVisible) {
                MainActivity.mainActivity.ToastNotify("Exception when trying to unregister: " + ex.toString());
            }
        }
    }
}
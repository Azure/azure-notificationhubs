package com.microsoft.notification_hubs_test_app;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.microsoft.windowsazure.messaging.NotificationHub;
import com.microsoft.windowsazure.notifications.NotificationsManager;
import android.content.Intent;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity {

    public static MainActivity mainActivity;
    public static Boolean isVisible = false;
    private static final String TAG = "MainActivity";
    private static final int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mainActivity = this;
        NotificationsManager.handleNotifications(this, NotificationSettings.SenderId, MyHandler.class);
    }

    @Override
    protected void onStart() {
        super.onStart();
        isVisible = true;
    }

    @Override
    protected void onPause() {
        super.onPause();
        isVisible = false;
    }

    @Override
    protected void onResume() {
        super.onResume();
        isVisible = true;
    }

    @Override
    protected void onStop() {
        super.onStop();
        isVisible = false;
    }

    public void ToastNotify(final String notificationMessage) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(MainActivity.this, notificationMessage, Toast.LENGTH_LONG).show();
                TextView textLog = (TextView) findViewById(R.id.textLog);
                textLog.setText(notificationMessage);
            }
        });
    }

    public void onRegisterClick(View view) {
        registerWithNotificationHubs();
//        Button registerButton = (Button) findViewById(R.id.registerButton);
//        Button unregisterButton = (Button) findViewById(R.id.unregisterButton);
//        registerButton.setEnabled(false);
//        unregisterButton.setEnabled(true);
    }

    public void onUnregisterClick(View view) {
        unregisterFromNotificationHubs();
//        Button registerButton = (Button) findViewById(R.id.registerButton);
//        Button unregisterButton = (Button) findViewById(R.id.unregisterButton);
//        registerButton.setEnabled(true);
//        unregisterButton.setEnabled(false);
    }

    /**
     * Check the device to make sure it has the Google Play Services APK. If
     * it doesn't, display a dialog that allows users to download the APK from
     * the Google Play Store or enable it in the device's system settings.
     */

    private boolean checkPlayServices() {
        GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
        int resultCode = apiAvailability.isGooglePlayServicesAvailable(this);
        if (resultCode != ConnectionResult.SUCCESS) {
            if (apiAvailability.isUserResolvableError(resultCode)) {
                apiAvailability.getErrorDialog(this, resultCode, PLAY_SERVICES_RESOLUTION_REQUEST)
                        .show();
            } else {
                Log.i(TAG, "This device is not supported by Google Play Services.");
                ToastNotify("This device is not supported by Google Play Services.");
                finish();
            }
            return false;
        }
        return true;
    }

    private void registerWithNotificationHubs()
    {
        if (checkPlayServices()) {
            // Start IntentService to register this application with FCM.
            EditText tagsText = (EditText) findViewById(R.id.tagsText);

            Intent intent = new Intent(this, RegistrationIntentService.class);
            intent.putExtra(RegistrationIntentService.TAGS_KEY, tagsText.getText().toString());

            startService(intent);
        }
    }

    private void unregisterFromNotificationHubs() {
        if (checkPlayServices()) {
            // Start IntentService to unregister this application with FCM.

            Intent intent = new Intent(this, UnregistrationIntentService.class);

            startService(intent);
        }
    }
}

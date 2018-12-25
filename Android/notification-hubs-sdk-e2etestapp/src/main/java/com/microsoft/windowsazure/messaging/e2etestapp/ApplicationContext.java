package com.microsoft.windowsazure.messaging.e2etestapp;

import java.net.MalformedURLException;
import java.net.URI;
import java.util.Set;

import com.microsoft.windowsazure.messaging.ConnectionString;
import com.microsoft.windowsazure.messaging.NotificationHub;
import com.microsoft.windowsazure.messaging.PnsSpecificRegistrationFactory;
import com.microsoft.windowsazure.messaging.Registration;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.preference.PreferenceManager;

public class ApplicationContext {
	private static Context mContext;

	public static Context getContext() {
		return mContext;
	}

	public static void setContext(Context context) {
		mContext = context.getApplicationContext();
	}
	
	public static NotificationHub createNotificationHub() throws MalformedURLException {
		PnsSpecificRegistrationFactory.getInstance().setRegistrationType( getUseGcm()?Registration.RegistrationType.gcm:Registration.RegistrationType.fcm );
		return createNotificationHub(true);
	}

	public static NotificationHub createNotificationHub(boolean clearLocalStorage) throws MalformedURLException {
		String endpoint = getNotificationHubEndpoint();
		String keyName = getNotificationHubKeyName();
		String keyValue = getNotificationHubKeyValue();
		String notificationHubName = getNotificationHubName();
		
		String connectionString = ConnectionString.createUsingSharedAccessKey(URI.create(endpoint), keyName, keyValue);
		
		if (clearLocalStorage) {
			clearNotificationHubStorageData();
		}
		
		NotificationHub notificationHub = new NotificationHub(notificationHubName, connectionString, mContext);

		return notificationHub;
	}

	public static void clearNotificationHubStorageData() {
		SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(mContext);
		Editor editor = sharedPreferences.edit();
		Set<String> keys = sharedPreferences.getAll().keySet();
		
		for (String key : keys) {
			if (key.startsWith("__NH_")) {
				editor.remove(key);
			}
		}
		
		editor.commit();
	}
	
	public static String getNotificationHubEndpoint() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_NOTIFICATIONHUB_URL, "");
	}

	public static String getNotificationHubKeyName() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_NOTIFICATIONHUB_KEYNAME, "");
	}
	
	public static String getNotificationHubKeyValue() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_NOTIFICATIONHUB_KEYVALUE, "");
	}

	public static String getNotificationHubName() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_NOTIFICATIONHUB_NAME, "");
	}
	
	public static String getLogPostURL() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_LOG_POST_URL, "");
	}
	
	public static String getGCMSenderId() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_GCM_SENDER_ID, "");
	}

	public static String getFCMSenderId() {
		return PreferenceManager.getDefaultSharedPreferences(mContext).getString(Constants.PREFERENCE_FCM_SENDER_ID, "");
	}

	public static Boolean getUseGcm(){
		return PreferenceManager.getDefaultSharedPreferences(mContext).getBoolean(Constants.PREFERENCE_USE_DEPRECATED_GCM, false);
	}
}

/*
Copyright (c) Microsoft Open Technologies, Inc.
All Rights Reserved
Apache 2.0 License
 
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 
See the Apache Version 2.0 License for specific language governing permissions and limitations under the License.
 */

package com.microsoft.windowsazure.messaging;

import static com.microsoft.windowsazure.messaging.Utils.*;

import java.io.IOException;
import java.io.StringReader;
import java.net.URLEncoder;
import java.util.Set;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.http.message.BasicHeader;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.preference.PreferenceManager;

/**
 * The notification hub client
 */
public class NotificationHub {
	
	/**
	 * Prefix for Storage keys
	 */
	private static final String STORAGE_PREFIX = "__NH_";
	
	/**
	 * Prefix for registration information keys in local storage
	 */
	private static final String REGISTRATION_NAME_STORAGE_KEY = "REG_NAME_";
	
	/**
	 * Content-type for atom+xml requests
	 */
	private static final String XML_CONTENT_TYPE = "application/atom+xml";
	
	/**
	 * Storage Version key
	 */
	private static final String STORAGE_VERSION_KEY = "STORAGE_VERSION";
	
	/**
	 * Storage Version
	 */
	private static final String STORAGE_VERSION = "1.0.0";
	
	/**
	 * GCMRegistrationId Key
	 */
	private static final String GCMREGID_KEY = "GCMREGID";
	
	/**
	 * The Notification Hub path
	 */
	private String mNotificationHubPath;
	
	/**
	 * Notification Hub Connection String 
	 */
	private String mConnectionString;
	
	/**
	 * SharedPreferences reference used to access local storage
	 */
	private SharedPreferences mSharedPreferences;
	
	private boolean mIsRefreshNeeded = false;

	/**
	 * Creates a new NotificationHub client
	 * @param notificationHubPath	Notification Hub path
	 * @param connectionString	Notification Hub connection string
	 * @param context	Android context used to access SharedPreferences
	 */
	public NotificationHub(String notificationHubPath, String connectionString, Context context) {
		setNotificationHubPath(notificationHubPath);
		setConnectionString(connectionString);

		if (context == null) {
			throw new IllegalArgumentException("context");
		}

		mSharedPreferences = PreferenceManager.getDefaultSharedPreferences(context.getApplicationContext());
		
		verifyStorageVersion();
	}

	/**
	 * Registers the client for native notifications with the specified tags
	 * @param gcmId	The GCM Registration Id
	 * @param tags	Tags to use in the registration
	 * @return	The created registration
	 * @throws Exception
	 */
	public NativeRegistration register(String gcmId, String... tags) throws Exception {
		if (isNullOrWhiteSpace(gcmId)) {
			throw new IllegalArgumentException("gcmId");
		}
		
		NativeRegistration registration = new NativeRegistration(mNotificationHubPath);
		registration.setGCMRegistrationId(gcmId);
		registration.setName(Registration.DEFAULT_REGISTRATION_NAME);
		registration.addTags(tags);

		return (NativeRegistration) registerInternal(registration);
	}

	/**
	 * Registers the client for template notifications with the specified tags
	 * @param gcmId	The GCM Registration Id
	 * @param templateName	The template name
	 * @param template	The template body
	 * @param tags	The tags to use in the registration
	 * @return	The created registration
	 * @throws Exception
	 */
	public TemplateRegistration registerTemplate(String gcmId, String templateName, String template, String... tags) throws Exception {
		if (isNullOrWhiteSpace(gcmId)) {
			throw new IllegalArgumentException("gcmId");
		}
		
		if (isNullOrWhiteSpace(templateName)) {
			throw new IllegalArgumentException("templateName");
		}
		
		if (isNullOrWhiteSpace(template)) {
			throw new IllegalArgumentException("template");
		}

		TemplateRegistration registration = new TemplateRegistration(mNotificationHubPath);
		registration.setGCMRegistrationId(gcmId);
		registration.setName(templateName);
		registration.setBodyTemplate(template);
		registration.addTags(tags);

		return (TemplateRegistration) registerInternal(registration);
	}

	/**
	 * Unregisters the client for native notifications
	 * @throws Exception
	 */
	public void unregister() throws Exception {
		unregisterInternal(Registration.DEFAULT_REGISTRATION_NAME);
	}

	/**
	 * Unregisters the client for template notifications of a specific template
	 * @param templateName	The template name
	 * @throws Exception
	 */
	public void unregisterTemplate(String templateName) throws Exception {
		if (isNullOrWhiteSpace(templateName)) {
			throw new IllegalArgumentException("templateName");
		}
		
		unregisterInternal(templateName);
	}
	
	/**
	 * Unregisters the client for all notifications
	 * @param gcmId The GCM Registration Id
	 * @throws Exception
	 */
	public void unregisterAll(String gcmId) throws Exception {
		refreshRegistrationInformation(gcmId);
		
		Set<String> keys = mSharedPreferences.getAll().keySet();
		
		for (String key : keys) {
			if (key.startsWith(STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY)) {
				String registrationName = key.substring((STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY).length());
				String registrationId = mSharedPreferences.getString(key, "");
		
				deleteRegistrationInternal(registrationName, registrationId);
			}
		}
	}
	
	private void refreshRegistrationInformation(String gcmId) throws Exception {
		if (isNullOrWhiteSpace(gcmId)) {
			throw new IllegalArgumentException("gcmId");
		}
		
		// delete old registration information
		Editor editor = mSharedPreferences.edit();
		Set<String> keys = mSharedPreferences.getAll().keySet();
		for (String key : keys) {
			if (key.startsWith(STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY)) {
				editor.remove(key);
			}
		}
		
		editor.commit();
		
		// get existing registrations
		Connection conn = new Connection(mConnectionString);

		String filter = "GcmRegistrationId eq '" + gcmId + "'";

		String resource = mNotificationHubPath + "/Registrations/?$filter=" + URLEncoder.encode(filter, "UTF-8");
		String content = null;
		String response = conn.executeRequest(resource, content, XML_CONTENT_TYPE, "GET");

		DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		builder.setEntityResolver(new EntityResolver() {
			@Override
			public InputSource resolveEntity(String publicId, String systemId) throws SAXException, IOException {
				return null;
			}
		});

		Document doc = builder.parse(new InputSource(new StringReader(response)));

		doc.getDocumentElement().normalize();
		Element root = doc.getDocumentElement();
		
		//for each registration, parse it
		NodeList entries = root.getElementsByTagName("entry");
		for (int i = 0; i < entries.getLength(); i++) {
			Registration registration;
			Element entry = (Element) entries.item(i);
			String xml = getXmlString(entry);
			if (TemplateRegistration.isTemplateRegistration(xml)) {
				registration = new TemplateRegistration(mNotificationHubPath);
			} else {
				registration = new NativeRegistration(mNotificationHubPath);
			}

			registration.loadXml(xml, mNotificationHubPath);

			storeRegistrationId(registration.getName(), registration.getRegistrationId(), registration.getGCMRegistrationId());
		}
		
		mIsRefreshNeeded = false;
	}
	
	/**
	 * Gets the Notification Hub connection string
	 */
	public String getConnectionString() {
		return mConnectionString;
	}

	/**
	 * Sets the Notification Hub connection string
	 */
	public void setConnectionString(String connectionString) {

		if (isNullOrWhiteSpace(connectionString)) {
			throw new IllegalArgumentException("connectionString");
		}
		
		try {
			ConnectionStringParser.parse(connectionString);
		} catch (Exception e) {
			throw new IllegalArgumentException("connectionString", e);
		}

		mConnectionString = connectionString;
	}

	/**
	 * Gets the Notification Hub path
	 */
	public String getNotificationHubPath() {
		return mNotificationHubPath;
	}

	/**
	 * Sets the Notification Hub path
	 */
	public void setNotificationHubPath(String notificationHubPath) {

		if (isNullOrWhiteSpace(notificationHubPath)) {
			throw new IllegalArgumentException("notificationHubPath");
		}

		mNotificationHubPath = notificationHubPath;
	}

	/**
	 * Creates a new registration in the server. If it exists, updates its information
	 * @param registration	The registration to create
	 * @return The created registration
	 * @throws Exception
	 */
	private Registration registerInternal(Registration registration) throws Exception {
		
		if (mIsRefreshNeeded) {
			String gcmId = mSharedPreferences.getString(STORAGE_PREFIX + GCMREGID_KEY, "");
			
			if (isNullOrWhiteSpace(gcmId)) {
				gcmId = registration.getGCMRegistrationId();
			}
			
			refreshRegistrationInformation(gcmId);
		}
		
		String registrationId = retrieveRegistrationId(registration.getName());
		
		if (!isNullOrWhiteSpace(registrationId)) {
			registration.setRegistrationId(registrationId);
			
			return updateRegistrationInternal(registration);
		} else {
			return createRegistrationInternal(registration);
		}
	}

	/**
	 * Deletes a registration and removes it from local storage
	 * @param registrationName	The registration name
	 * @throws Exception
	 */
	private void unregisterInternal(String registrationName) throws Exception {
		String registrationId = retrieveRegistrationId(registrationName);
		
		if(!isNullOrWhiteSpace(registrationId)) {
			deleteRegistrationInternal(registrationName, registrationId);
		}
	}
	
	/**
	 * Updates a registration
	 * @param registration	The registration to update
	 * @return	The updated registration
	 * @throws Exception
	 */
	private Registration updateRegistrationInternal(Registration registration) throws Exception {
		Connection conn = new Connection(mConnectionString);

		String resource = registration.getURI();
		String content = registration.toXml();

		String response;
		try {
			response = conn.executeRequest(resource, content, XML_CONTENT_TYPE, "PUT", new BasicHeader("If-Match", "*"));
		} catch (NotificationHubResourceNotFoundException ex) {
			removeRegistrationId(registration.getName());

			return createRegistrationInternal(registration);
		}
		
		Registration result;
		if (TemplateRegistration.isTemplateRegistration(response)) {
			result = new TemplateRegistration(mNotificationHubPath);
		} else {
			result = new NativeRegistration(mNotificationHubPath);
		}

		result.loadXml(response, mNotificationHubPath);

		storeRegistrationId(result.getName(), result.getRegistrationId(), registration.getGCMRegistrationId());
		
		return result;
	}
	
	private Registration createRegistrationInternal(Registration registration) throws Exception {
		Connection conn = new Connection(mConnectionString);

		// new registration
		String resource = mNotificationHubPath + "/Registrations/";
		String content = registration.toXml();
		String response = conn.executeRequest(resource, content, XML_CONTENT_TYPE, "POST");

		Registration result;
		if (TemplateRegistration.isTemplateRegistration(response)) {
			result = new TemplateRegistration(mNotificationHubPath);
		} else {
			result = new NativeRegistration(mNotificationHubPath);
		}
		
		result.loadXml(response, mNotificationHubPath);

		storeRegistrationId(result.getName(), result.getRegistrationId(), result.getGCMRegistrationId());
		
		return result;
	}
	
	/**
	 * Deletes a registration and removes it from local storage
	 * @param regInfo	The reginfo JSON object
	 * @throws Exception
	 */
	private void deleteRegistrationInternal(String registrationName, String registrationId) throws Exception {
		Connection conn = new Connection(mConnectionString);
		String resource = mNotificationHubPath + "/Registrations/" + registrationId;
		
		try {
			conn.executeRequest(resource, null, XML_CONTENT_TYPE, "DELETE", new BasicHeader("If-Match", "*"));
		} finally {
			removeRegistrationId(registrationName);
		}
	}
		
	/**
	 * Retrieves the registration id associated to the registration name from local storage
	 * @param registrationName	The registration name to look for in local storage
	 * @return	A registration id String
	 * @throws Exception
	 */
	private String retrieveRegistrationId(String registrationName) throws Exception {
		return mSharedPreferences.getString(STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY + registrationName, null);
	}
	
	/**
	 * Stores the registration name and id association in local storage
	 * @param registrationName	The registration name to store in local storage
	 * @param registrationId	The registration id to store in local storage
	 * @throws Exception
	 */
	private void storeRegistrationId(String registrationName, String registrationId, String gcmRegistrationId) throws Exception {
		Editor editor = mSharedPreferences.edit();

		editor.putString(STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY + registrationName, registrationId);

		editor.putString(STORAGE_PREFIX + GCMREGID_KEY, gcmRegistrationId);
		
		// Always overwrite the storage version with the latest value
		editor.putString(STORAGE_PREFIX + STORAGE_VERSION_KEY, STORAGE_VERSION);
		
		editor.commit();
	}
	
	/**
	 * Removes the registration name and id association from local storage
	 * @param registrationName	The registration name of the association to remove from local storage
	 * @throws Exception
	 */
	private void removeRegistrationId(String registrationName) throws Exception {
		Editor editor = mSharedPreferences.edit();

		editor.remove(STORAGE_PREFIX + REGISTRATION_NAME_STORAGE_KEY + registrationName);

		editor.commit();
	}
	
	private void verifyStorageVersion() {
		String currentStorageVersion = mSharedPreferences.getString(STORAGE_PREFIX + STORAGE_VERSION_KEY, "");

		Editor editor = mSharedPreferences.edit();

		if (!currentStorageVersion.equals(STORAGE_VERSION)) {
			Set<String> keys = mSharedPreferences.getAll().keySet();
			
			for (String key : keys) {
				if (key.startsWith(STORAGE_PREFIX)) {
					editor.remove(key);
				}
			}
		}
		
		editor.commit();
		
		mIsRefreshNeeded = true;
	}
	
}

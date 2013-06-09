package com.microsoft.windowsazure.messaging.testapp.tests;

import java.net.URI;

import com.microsoft.windowsazure.messaging.ConnectionString;
import com.microsoft.windowsazure.messaging.NotificationHub;

import android.content.Context;
import android.test.InstrumentationTestCase;

public class NotificationHubTests extends InstrumentationTestCase {
	public void testCreateNotificationHub() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhName, cs, context);

		assertEquals(nh.getNotificationHubName(), nhName);
		assertEquals(nh.getConnectionString(), cs);
	}
	
	public void testCreateNotificationHubWithInvalidValues() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
				

		try {
			new NotificationHub(null, cs, context);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			new NotificationHub(nhName, null, context);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			new NotificationHub(nhName, cs, null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
	}
	
	public void testRegisterWithInvalidValues() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhName, cs, context);
		
		String[] tags = {"myTag_1", "myTag_2"};

		try {
			nh.register(null, tags);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
	public void testRegisterTemplateWithInvalidValues() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhName, cs, context);
		
		String gcmId = "123456";
		String templateName = "myTemplate";
		String template = "{\"my_int\": 1, \"my_string\": \"1\" }";
		String[] tags = {"myTag_1", "myTag_2"};

		try {
			nh.registerTemplate(null, templateName, template, tags);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
		
		try {
			nh.registerTemplate(gcmId, null, template, tags);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
		
		try {
			nh.registerTemplate(gcmId, templateName, null, tags);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
	public void testUnregisterTemplateWithInvalidValues() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhName, cs, context);

		try {
			nh.unregisterTemplate(null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
	public void testUnregisterAllWithInvalidValues() {
		String nhName = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhName, cs, context);

		try {
			nh.unregisterAll(null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
}

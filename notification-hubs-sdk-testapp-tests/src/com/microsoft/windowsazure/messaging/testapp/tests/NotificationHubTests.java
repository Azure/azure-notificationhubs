package com.microsoft.windowsazure.messaging.testapp.tests;

import java.net.URI;

import com.microsoft.windowsazure.messaging.ConnectionString;
import com.microsoft.windowsazure.messaging.NotificationHub;

import android.content.Context;
import android.test.InstrumentationTestCase;

public class NotificationHubTests extends InstrumentationTestCase {
	public void testCreateNotificationHub() {
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhPath, cs, context);

		assertEquals(nh.getNotificationHubPath(), nhPath);
		assertEquals(nh.getConnectionString(), cs);
	}
	
	public void testCreateNotificationHubWithInvalidValues() {
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
				

		try {
			new NotificationHub(null, cs, context);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			new NotificationHub(nhPath, null, context);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			new NotificationHub(nhPath, cs, null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
	}
	
	public void testRegisterWithInvalidValues() {
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhPath, cs, context);
		
		String[] tags = {"myTag_1", "myTag_2"};

		try {
			nh.register(null, tags);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
	public void testRegisterTemplateWithInvalidValues() {
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhPath, cs, context);
		
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
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhPath, cs, context);

		try {
			nh.unregisterTemplate(null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
	public void testUnregisterAllWithInvalidValues() {
		String nhPath = "myHub";
		String cs = ConnectionString.createUsingSharedAccessSecretWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		Context context = getInstrumentation().getTargetContext();
		NotificationHub nh = new NotificationHub(nhPath, cs, context);

		try {
			nh.unregisterAll(null);
			
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		} catch (Exception e) {
		}
	}
	
}

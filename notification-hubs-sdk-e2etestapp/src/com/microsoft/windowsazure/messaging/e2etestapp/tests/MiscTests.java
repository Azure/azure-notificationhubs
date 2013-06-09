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
package com.microsoft.windowsazure.messaging.e2etestapp.tests;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;

import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.preference.PreferenceManager;

import com.microsoft.windowsazure.messaging.ConnectionString;
import com.microsoft.windowsazure.messaging.NativeRegistration;
import com.microsoft.windowsazure.messaging.NotificationHub;
import com.microsoft.windowsazure.messaging.NotificationHubException;
import com.microsoft.windowsazure.messaging.NotificationHubResourceNotFoundException;
import com.microsoft.windowsazure.messaging.NotificationHubUnauthorizedException;
import com.microsoft.windowsazure.messaging.Registration;
import com.microsoft.windowsazure.messaging.TemplateRegistration;
import com.microsoft.windowsazure.messaging.e2etestapp.ApplicationContext;
import com.microsoft.windowsazure.messaging.e2etestapp.framework.TestCase;
import com.microsoft.windowsazure.messaging.e2etestapp.framework.TestGroup;
import com.microsoft.windowsazure.messaging.e2etestapp.framework.TestResult;
import com.microsoft.windowsazure.messaging.e2etestapp.framework.TestStatus;
import com.microsoft.windowsazure.messaging.e2etestapp.framework.Util;

public class MiscTests extends TestGroup {

	protected static final String ROUND_TRIP_TABLE_NAME = "droidRoundTripTable";
	protected static final String PARAM_TEST_TABLE_NAME = "ParamsTestTable";

	private static final String DEFAULT_REGISTRATION_NAME = "$Default";
	private static final String REGISTRATION_NAME_STORAGE_KEY = "__NH_REG_NAME_";
	
	private NativeRegistration register(TestCase test, NotificationHub hub, String gcmId, String[] tags) throws Exception {
		test.log("Register Native with GCMID = " + gcmId);
		if (tags != null && tags.length > 0) {
			for (String tag : tags) {
				test.log("Using tag: " + tag);
			}
		}

		return hub.register(gcmId, tags);
	}

	private void unregister(TestCase test, NotificationHub hub) throws Exception {
		test.log("Unregister Native");
		hub.unregister();
	}

	private TemplateRegistration registerTemplate(TestCase test, NotificationHub hub, String gcmId, String templateName, String[] tags) throws Exception {
		String template = "{\"time_to_live\": 108, \"delay_while_idle\": true, \"data\": { \"message\": \"$(msg)\" } }";
		return registerTemplate(test, hub, gcmId, templateName, template, tags);
	}

	private TemplateRegistration registerTemplate(TestCase test, NotificationHub hub, String gcmId, String templateName, String template, String[] tags)
			throws Exception {

		test.log("Register with GCMID = " + gcmId);
		test.log("Register with templateName = " + templateName);

		if (tags != null && tags.length > 0) {
			for (String tag : tags) {
				test.log("Using tag: " + tag);
			}
		}

		return hub.registerTemplate(gcmId, templateName, template, tags);
	}

	private void unregisterTemplate(TestCase test, NotificationHub hub, String templateName) throws Exception {
		test.log("UnregisterTemplate with templateName = " + templateName);

		hub.unregisterTemplate(templateName);
	}

	private void unregisterAll(TestCase test, NotificationHub hub, String gcmId) throws Exception {
		test.log("Unregister Native");
		hub.unregisterAll(gcmId);
	}

	private void addUnexistingNativeRegistration(String registrationId) {
		addUnexistingTemplateRegistration(DEFAULT_REGISTRATION_NAME, registrationId);
	}

	private void addUnexistingTemplateRegistration(String templateName, String registrationId) {
		SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(ApplicationContext.getContext());

		Editor editor = sharedPreferences.edit();
		editor.putString(REGISTRATION_NAME_STORAGE_KEY + templateName, registrationId);
		editor.commit();
	}

	// Register Native Tests

	private TestCase createRegisterNativeTestCase(String name, final String... tags) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					Registration reg = register(this, notificationHub, UUID.randomUUID().toString(), tags);

					ArrayList<String> tagList = new ArrayList<String>();
					for (String tag : tags) {
						tagList.add(tag);
					}

					if (!Util.compareLists(reg.getTags(), tagList)) {
						result.setStatus(TestStatus.Failed);
					}

					unregister(this, notificationHub);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);

		return register;
	}

	private TestCase createRegisterNativeTwiceTestCase(String name, final String... tags) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					String newTag = UUID.randomUUID().toString();

					String gcmId = UUID.randomUUID().toString();
					
					register(this, notificationHub, gcmId, tags);
					Registration reg = register(this, notificationHub, gcmId, new String[] { newTag });

					if (reg.getTags().size() == 0 || reg.getTags().size() != 1 || !reg.getTags().get(0).equals(newTag)) {
						result.setStatus(TestStatus.Failed);
					}

					unregister(this, notificationHub);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);

		return register;
	}

	private TestCase createRegisterNativeWrongHubTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					NotificationHub nh = new NotificationHub("wrongName", notificationHub.getConnectionString(), ApplicationContext.getContext());

					register(this, nh, UUID.randomUUID().toString(), (String[]) null);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createRegisterNativeWrongCredentialsTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					HashMap<String, String> csParts = new HashMap<String, String>();
					String[] keyValues = notificationHub.getConnectionString().split(";");

					for (String keyValue : keyValues) {
						csParts.put(keyValue.split("=")[0], keyValue.split("=")[1]);
					}

					String cs = ConnectionString.createUsingSharedAccessSecret(URI.create(csParts.get("Endpoint")), csParts.get("SharedAccessKeyName"),
							"1234567890");

					NotificationHub nh = new NotificationHub(notificationHub.getNotificationHubName(), cs, ApplicationContext.getContext());

					register(this, nh, UUID.randomUUID().toString(), (String[]) null);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubUnauthorizedException.class);

		return register;
	}

	// Register Template Tests

	private TestCase createRegisterTemplateTestCase(String name, final String templateName, final String... tags) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					Registration reg = registerTemplate(this, notificationHub, UUID.randomUUID().toString(), templateName, tags);

					ArrayList<String> tagList = new ArrayList<String>();
					for (String tag : tags) {
						tagList.add(tag);
					}

					if (!Util.compareLists(reg.getTags(), tagList)) {
						result.setStatus(TestStatus.Failed);
					}
					unregisterTemplate(this, notificationHub, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);

		return register;
	}

	private TestCase createRegisterTemplateTwiceTestCase(String name, final String templateName, final String... tags) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					String gcmId = UUID.randomUUID().toString();
					
					registerTemplate(this, notificationHub, gcmId, templateName, tags);

					String newTag = UUID.randomUUID().toString();

					Registration reg = registerTemplate(this, notificationHub, gcmId, templateName, new String[] { newTag });

					if (reg.getTags().size() == 0 || reg.getTags().size() != 1 || !reg.getTags().get(0).equals(newTag)) {
						result.setStatus(TestStatus.Failed);
					}

					unregisterTemplate(this, notificationHub, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);

		return register;
	}

	private TestCase createRegisterTemplateWrongHubTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					NotificationHub nh = new NotificationHub("wrongName", notificationHub.getConnectionString(), ApplicationContext.getContext());

					registerTemplate(this, nh, UUID.randomUUID().toString(), templateName, (String[]) null);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createRegisterTemplateWrongCredentialsTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					HashMap<String, String> csParts = new HashMap<String, String>();
					String[] keyValues = notificationHub.getConnectionString().split(";");

					for (String keyValue : keyValues) {
						csParts.put(keyValue.split("=")[0], keyValue.split("=")[1]);
					}

					String cs = ConnectionString.createUsingSharedAccessSecret(URI.create(csParts.get("Endpoint")), csParts.get("SharedAccessKeyName"),
							"1234567890");

					NotificationHub nh = new NotificationHub(notificationHub.getNotificationHubName(), cs, ApplicationContext.getContext());

					registerTemplate(this, nh, UUID.randomUUID().toString(), templateName, (String[]) null);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubUnauthorizedException.class);

		return register;
	}

	private TestCase createRegisterTemplateInvalidPayloadTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					registerTemplate(this, notificationHub, UUID.randomUUID().toString(), templateName, "{this is a very ill formatted template}", (String[]) null);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubException.class);

		return register;
	}

	// Unregister Native Tests

	private TestCase createUnregisterNativeWrongHubTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					NotificationHub nh = new NotificationHub("wrongName", notificationHub.getConnectionString(), ApplicationContext.getContext());

					addUnexistingNativeRegistration(UUID.randomUUID().toString());

					unregister(this, nh);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createUnregisterNativeWrongCredentialsTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					HashMap<String, String> csParts = new HashMap<String, String>();
					String[] keyValues = notificationHub.getConnectionString().split(";");

					for (String keyValue : keyValues) {
						csParts.put(keyValue.split("=")[0], keyValue.split("=")[1]);
					}

					String cs = ConnectionString.createUsingSharedAccessSecret(URI.create(csParts.get("Endpoint")), csParts.get("SharedAccessKeyName"),
							"1234567890");

					NotificationHub nh = new NotificationHub(notificationHub.getNotificationHubName(), cs, ApplicationContext.getContext());

					addUnexistingNativeRegistration(UUID.randomUUID().toString());

					unregister(this, nh);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubUnauthorizedException.class);

		return register;
	}

	private TestCase createUnregisterNativeUnexistingRegistrationTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					String gcmId = UUID.randomUUID().toString();
					NativeRegistration nativeRegistration = register(this, notificationHub, gcmId, (String[]) null);
					String registrationId = nativeRegistration.getRegistrationId();
					unregister(this, notificationHub);

					addUnexistingNativeRegistration(registrationId);

					unregister(this, notificationHub);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	// Unregister Template Tests

	private TestCase createUnregisterTemplateWrongHubTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					NotificationHub nh = new NotificationHub("wrongName", notificationHub.getConnectionString(), ApplicationContext.getContext());

					addUnexistingTemplateRegistration(templateName, UUID.randomUUID().toString());

					unregisterTemplate(this, nh, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createUnregisterTemplateWrongCredentialsTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					HashMap<String, String> csParts = new HashMap<String, String>();
					String[] keyValues = notificationHub.getConnectionString().split(";");

					for (String keyValue : keyValues) {
						csParts.put(keyValue.split("=")[0], keyValue.split("=")[1]);
					}

					String cs = ConnectionString.createUsingSharedAccessSecret(URI.create(csParts.get("Endpoint")), csParts.get("SharedAccessKeyName"),
							"1234567890");

					NotificationHub nh = new NotificationHub(notificationHub.getNotificationHubName(), cs, ApplicationContext.getContext());

					addUnexistingTemplateRegistration(templateName, UUID.randomUUID().toString());

					unregisterTemplate(this, nh, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubUnauthorizedException.class);

		return register;
	}

	private TestCase createUnregisterTemplateUnexistingRegistrationTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					TemplateRegistration templateRegistration = registerTemplate(this, notificationHub, UUID.randomUUID().toString(), templateName, (String[]) null);
					String registrationId = templateRegistration.getRegistrationId();
					unregisterTemplate(this, notificationHub, templateName);

					addUnexistingTemplateRegistration(templateName, registrationId);

					unregisterTemplate(this, notificationHub, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	// Unregister All Tests

	private TestCase createUnregisterAllUnregisterNativeTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					String gcmId = UUID.randomUUID().toString();
					NativeRegistration nativeRegistration = register(this, notificationHub, gcmId, (String[]) null);
					String registrationId = nativeRegistration.getRegistrationId();

					registerTemplate(this, notificationHub, gcmId, templateName, (String[]) null);

					unregisterAll(this, notificationHub, gcmId);

					addUnexistingNativeRegistration(registrationId);

					unregister(this, notificationHub);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createUnregisterAllUnregisterTemplateTestCase(String name, final String templateName) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					String gcmId = UUID.randomUUID().toString();
					register(this, notificationHub, gcmId, (String[]) null);

					TemplateRegistration templateRegistration = registerTemplate(this, notificationHub, gcmId, templateName, (String[]) null);
					String registrationId = templateRegistration.getRegistrationId();

					unregisterAll(this, notificationHub, gcmId);

					addUnexistingTemplateRegistration(templateName, registrationId);

					unregisterTemplate(this, notificationHub, templateName);

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubResourceNotFoundException.class);

		return register;
	}

	private TestCase createUnregisterAllWrongCredentialsTestCase(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);

					HashMap<String, String> csParts = new HashMap<String, String>();
					String[] keyValues = notificationHub.getConnectionString().split(";");

					for (String keyValue : keyValues) {
						csParts.put(keyValue.split("=")[0], keyValue.split("=")[1]);
					}

					String cs = ConnectionString.createUsingSharedAccessSecret(URI.create(csParts.get("Endpoint")), csParts.get("SharedAccessKeyName"),
							"1234567890");

					NotificationHub nh = new NotificationHub(notificationHub.getNotificationHubName(), cs, ApplicationContext.getContext());

					unregisterAll(this, nh, UUID.randomUUID().toString());

					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		register.setName(name);
		register.setExpectedExceptionClass(NotificationHubUnauthorizedException.class);

		return register;
	}
	
	private TestCase createClearStorageOnNewVersion(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {

					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);
					
					ApplicationContext.clearNotificationHubStorageData();
					
					SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(ApplicationContext.getContext());
					Editor editor = preferences.edit();
					editor.putString("__NH_STORAGE_VERSION", "0.9.0");
					editor.putString("__NH_STORAGE_" + UUID.randomUUID().toString(), UUID.randomUUID().toString());
					editor.commit();
					
					ApplicationContext.createNotificationHub(false);
					
					for (String key : preferences.getAll().keySet()) {
						if (key.startsWith("__NH_")) {
							if (key.equals("__NH_STORAGE_VERSION")) {
								String version = preferences.getString(key, "");
								if (!version.equals("1.0.0")) {
									result.setStatus(TestStatus.Failed);
								}
							} else {
								result.setStatus(TestStatus.Failed);
							}
						}
					}
					
					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		
		register.setName(name);

		return register;
	}
	
	private TestCase createCheckIsRefreshNeeded(String name) {
		TestCase register = new TestCase() {

			@Override
			protected TestResult executeTest() {
				try {
					NotificationHub notificationHub = ApplicationContext.createNotificationHub();
					TestResult result = new TestResult();
					result.setStatus(TestStatus.Passed);
					result.setTestCase(this);
					
					String gcmId = UUID.randomUUID().toString();
					register(this, notificationHub, gcmId, (String[])null);
					
					notificationHub = ApplicationContext.createNotificationHub(true);
					registerTemplate(this, notificationHub, gcmId, UUID.randomUUID().toString(), (String[])null);
					
					SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(ApplicationContext.getContext());
					int regCount = 0;
					
					for (String key : preferences.getAll().keySet()) {
						if (key.startsWith("__NH_REG_NAME_")) {
							regCount++;
						}
					}
					
					if (regCount != 2) {
						result.setStatus(TestStatus.Failed);
					}
					
					return result;
				} catch (Exception e) {
					return createResultFromException(e);
				}
			}
		};
		
		register.setName(name);

		return register;
	}

	public MiscTests() {
		super("Misc tests");

		this.addTest(createRegisterNativeTestCase("Register native - Register / Unregister - No tags"));
		this.addTest(createRegisterNativeTestCase("Register native - Register / Unregister - One tag", "tagNum1"));
		this.addTest(createRegisterNativeTestCase("Register native - Register / Unregister - Three tags", "tagNum1", "tagNum2", "tagNum3"));

		this.addTest(createRegisterNativeTwiceTestCase("Register native - Register twice / Unregister - No tags"));
		this.addTest(createRegisterNativeTwiceTestCase("Register native - Register twice / Unregister - One tag", "tagNum1"));
		this.addTest(createRegisterNativeTwiceTestCase("Register native - Register twice / Unregister - Three tags", "tagNum1", "tagNum2", "tagNum3"));

		this.addTest(createRegisterNativeWrongHubTestCase("Register native - Wrong hub"));
		this.addTest(createRegisterNativeWrongCredentialsTestCase("Register native - Wrong credentials"));

		this.addTest(createRegisterTemplateTestCase("Register template - Register / Unregister - No tags", UUID.randomUUID().toString()));
		this.addTest(createRegisterTemplateTestCase("Register template - Register / Unregister - One tag", UUID.randomUUID().toString(), "tagNum1"));
		this.addTest(createRegisterTemplateTestCase("Register template - Register / Unregister - Three tags", UUID.randomUUID().toString(), "tagNum1",
				"tagNum2", "tagNum3"));

		this.addTest(createRegisterTemplateTwiceTestCase("Register template - Register twice / Unregister - No tags", UUID.randomUUID().toString()));
		this.addTest(createRegisterTemplateTwiceTestCase("Register template - Register twice / Unregister - One tag", UUID.randomUUID().toString(), "tagNum1"));
		this.addTest(createRegisterTemplateTwiceTestCase("Register template - Register twice / Unregister - Three tags", UUID.randomUUID().toString(),
				"tagNum1", "tagNum2", "tagNum3"));

		this.addTest(createRegisterTemplateWrongHubTestCase("Register template - Wrong hub", UUID.randomUUID().toString()));
		this.addTest(createRegisterTemplateWrongCredentialsTestCase("Register template - Wrong credentials", UUID.randomUUID().toString()));
		this.addTest(createRegisterTemplateInvalidPayloadTestCase("Register template - Invalid Payload", UUID.randomUUID().toString()));

		this.addTest(createUnregisterNativeWrongHubTestCase("Unregister native - Wrong hub"));
		this.addTest(createUnregisterNativeWrongCredentialsTestCase("Unregister native - Wrong credentials"));
		this.addTest(createUnregisterNativeUnexistingRegistrationTestCase("Unregister native - Unexisting registration"));

		this.addTest(createUnregisterTemplateWrongHubTestCase("Unregister template - Wrong hub", UUID.randomUUID().toString()));
		this.addTest(createUnregisterTemplateWrongCredentialsTestCase("Unregister template - Wrong credentials", UUID.randomUUID().toString()));
		this.addTest(createUnregisterTemplateUnexistingRegistrationTestCase("Unregister template - Unexisting registration", UUID.randomUUID().toString()));

		this.addTest(createUnregisterAllUnregisterNativeTestCase(
				"Unregister all - Register native / Register template / Unregister all / Unregister native - Unexisting registration", UUID.randomUUID()
						.toString()));
		this.addTest(createUnregisterAllUnregisterTemplateTestCase(
				"Unregister all - Register native / Register template / Unregister all / Unregister template - Unexisting registration", UUID.randomUUID()
						.toString()));
		this.addTest(createUnregisterAllWrongCredentialsTestCase("Unregister all - Wrong credentials"));
		this.addTest(createClearStorageOnNewVersion("Clear storage on new version"));
		this.addTest(createCheckIsRefreshNeeded("Retrieve existing registrations on first connection"));
	}
}

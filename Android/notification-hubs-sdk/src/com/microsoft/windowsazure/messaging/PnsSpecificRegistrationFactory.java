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

import com.microsoft.windowsazure.messaging.Registration.RegistrationType;

/**
 * Represents a factory which creates Registrations according the PNS supported on device, and also provides some PNS specific utility methods
 */
public final class PnsSpecificRegistrationFactory {

	/**
	 * Keeps the single instance
	 */
	private static final PnsSpecificRegistrationFactory mInstance=new PnsSpecificRegistrationFactory();
	
	/**
	 * If it is Amazon device
	 */
	private boolean mIsAmazonDevice;
	
	/**
	 * Creates a new instance of PnsSpecificRegistrationFactory
	 */
	private PnsSpecificRegistrationFactory() {
		// https://developer.amazon.com/public/solutions/devices/kindle-fire/specifications/01-device-and-feature-specifications
		mIsAmazonDevice=android.os.Build.MANUFACTURER.compareToIgnoreCase("Amazon")==0;
	}
	
	/**
	 * Returns the instance of PnsSpecificRegistrationFactory
	 */
	public static PnsSpecificRegistrationFactory getInstance(){
		return mInstance;
	}

	/**
	 * Creates native registration according the PNS supported on device
	 * @param notificationHubPath The Notification Hub path
	 */
	public Registration createNativeRegistration(String notificationHubPath){
		return mIsAmazonDevice?
				new AdmNativeRegistration(notificationHubPath):
					new GcmNativeRegistration(notificationHubPath);
				
	}
	
	/**
	 * Creates native registration according the PNS supported on device
	 * @param notificationHubPath The Notification Hub path
	 * @param type the notification type.
	 */
	public Registration createNativeRegistration(String notificationHubPath, RegistrationType type){
		switch(type)
		{
			case gcm:{
				return new GcmNativeRegistration(notificationHubPath);
			}
			case baidu:{
				return new BaiduNativeRegistration(notificationHubPath);
			}
			case adm:{
				return new AdmNativeRegistration(notificationHubPath);
			}
			default:{
				throw new AssertionError("Ivalid registration type!");
			}
		}
	}
	/**
	 * Creates template registration according the PNS supported on device
	 * @param notificationHubPath The Notification Hub path
	 */
	public TemplateRegistration createTemplateRegistration(String notificationHubPath){
		return mIsAmazonDevice?
				new AdmTemplateRegistration(notificationHubPath):
					new GcmTemplateRegistration(notificationHubPath);
	}
	
	/**
	 * Creates template registration according the PNS supported on device
	 * @param notificationHubPath The Notification Hub path
	 * @param type the notification type.
	 */
	public TemplateRegistration createTemplateRegistration(String notificationHubPath, RegistrationType type){
		switch(type)
		{
			case gcm:
				return new GcmTemplateRegistration(notificationHubPath);
			case baidu:
				return new BaiduTemplateRegistration(notificationHubPath);
			case adm:
				return new AdmTemplateRegistration(notificationHubPath);
			default:
				// @TODO: Assert.
				return null;
		}		
	}
	
	
	/**
	 * Indicates if a registration xml is a Template Registration
	 * @param xml	The xml to check
	 */
	public boolean isTemplateRegistration(String xml){
		return xml.contains("<" + (
				mIsAmazonDevice?
						AdmTemplateRegistration.ADM_TEMPLATE_REGISTRATION_CUSTOM_NODE: 
							GcmTemplateRegistration.GCM_TEMPLATE_REGISTRATION_CUSTOM_NODE));
	}
	
	/**
	 * Returns PNS handle field name according the PNS supported on device
	 */
	public String getPNSHandleFieldName(){
		return mIsAmazonDevice?AdmNativeRegistration.ADM_HANDLE_NODE:GcmNativeRegistration.GCM_HANDLE_NODE;
	}
	
	/**
	 * Returns API origin value according the PNS supported on device
	 */
	public String getAPIOrigin(){
		return mIsAmazonDevice?"AndroidSdkAdm":"AndroidSdkGcm";
	}
}

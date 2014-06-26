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

/**
 * Represents a factory which creates Registrations according the PNS supported on device, and also provides some PNS specific utility methods
 */
public final class PnsSpecificRegistrationFactory {
	
	public enum AndroidDeviceType
	{
		gcm, adm, nokiax
	}
		
	/**
	 * Keeps the single instance
	 */
	private static final PnsSpecificRegistrationFactory mInstance=new PnsSpecificRegistrationFactory();
	
	/**
	 * If it is Amazon device
	 */
	private boolean mIsAmazonDevice;
	
	private AndroidDeviceType type;
	
	
	/**
	 * Creates a new instance of PnsSpecificRegistrationFactory
	 */
	private PnsSpecificRegistrationFactory() {
		// https://developer.amazon.com/public/solutions/devices/kindle-fire/specifications/01-device-and-feature-specifications
		//mIsAmazonDevice=android.os.Build.MANUFACTURER.compareToIgnoreCase("Amazon")==0;
	    String manufacturer = android.os.Build.MANUFACTURER;
		if(manufacturer.compareToIgnoreCase("Amazon") == 0)
		{
			type = AndroidDeviceType.adm;
		}
		else if(manufacturer.compareToIgnoreCase("Nokia") == 0)
		{
			type = AndroidDeviceType.nokiax;
		}
		else
		{
			type = AndroidDeviceType.gcm;
		}
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
		switch(type)
		{
			case nokiax:
				return new NokiaXNativeRegistration(notificationHubPath);
			case adm:
				return new AdmNativeRegistration(notificationHubPath);
			default:
				return new GcmNativeRegistration(notificationHubPath);
		}
			
/*		return mIsAmazonDevice?
				new AdmNativeRegistration(notificationHubPath):
					new GcmNativeRegistration(notificationHubPath);
*/
	}
	
	/**
	 * Creates template registration according the PNS supported on device
	 * @param notificationHubPath The Notification Hub path
	 */
	public TemplateRegistration createTemplateRegistration(String notificationHubPath){
		switch(type)
		{
			case nokiax:
				return new NokiaXTemplateRegistration(notificationHubPath);
			case adm:
				return new AdmTemplateRegistration(notificationHubPath);
			default:
				return new GcmTemplateRegistration(notificationHubPath);
		}		
		/*		return mIsAmazonDevice?
				new AdmTemplateRegistration(notificationHubPath):
					new GcmTemplateRegistration(notificationHubPath);
*/					
	}
	
	/**
	 * Indicates if a registration xml is a Template Registration
	 * @param xml	The xml to check
	 */
	public boolean isTemplateRegistration(String xml){
		String regx = null;
		switch(type)
		{
			case nokiax:
				regx = NokiaXTemplateRegistration.NOKIAX_TEMPLATE_REGISTRATION_CUSTOM_NODE;
				break;
			case adm:
				regx = AdmTemplateRegistration.ADM_TEMPLATE_REGISTRATION_CUSTOM_NODE;
				break;
			default:
				regx = GcmTemplateRegistration.GCM_TEMPLATE_REGISTRATION_CUSTOM_NODE;
				break;
		}		
	
		return xml.contains("<" + regx);
/*		
		return xml.contains("<" + (
				mIsAmazonDevice?
						AdmTemplateRegistration.ADM_TEMPLATE_REGISTRATION_CUSTOM_NODE: 
							GcmTemplateRegistration.GCM_TEMPLATE_REGISTRATION_CUSTOM_NODE));
*/							
	}
	
	/**
	 * Returns PNS handle field name according the PNS supported on device
	 */
	public String getPNSHandleFieldName(){
		switch(type)
		{
			case nokiax:
				return NokiaXNativeRegistration.NOKIAX_HANDLE_NODE;
			case adm:
				return AdmNativeRegistration.ADM_HANDLE_NODE;
			default:
				return GcmNativeRegistration.GCM_HANDLE_NODE;	
		}
		//return mIsAmazonDevice?AdmNativeRegistration.ADM_HANDLE_NODE:GcmNativeRegistration.GCM_HANDLE_NODE;
	}
	
	/**
	 * Returns API origin value according the PNS supported on device
	 */
	public String getAPIOrigin(){
		switch(type)
		{
			case nokiax:
				return "AndroidSdkNokiaX";
			case adm:
				return "AndroidSdkAdm";
			default:
				return "AndroidSdkGcm";	
		}	
		//return mIsAmazonDevice?"AndroidSdkAdm":"AndroidSdkGcm";
	}
}

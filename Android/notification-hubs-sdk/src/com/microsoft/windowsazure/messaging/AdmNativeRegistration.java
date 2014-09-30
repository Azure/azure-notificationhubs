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

import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * Represents ADM native registration
 */
public class AdmNativeRegistration extends Registration {

	/**
	 * Custom payload node name for native registrations
	 */
	private static final String ADM_NATIVE_REGISTRATION_CUSTOM_NODE = "AdmRegistrationDescription";
	
	/**
	 * Custom node name for PNS handle
	 */
	static final String ADM_HANDLE_NODE = "AdmRegistrationId";

	/**
	 * Creates a new native registration
	 * @param notificationHubPath	The notification hub path
	 */
	AdmNativeRegistration(String notificationHubPath) {
		super(notificationHubPath);
		mRegistrationType = RegistrationType.adm;
	}

	@Override
	protected String getSpecificPayloadNodeName() {
		return ADM_NATIVE_REGISTRATION_CUSTOM_NODE;
	}

	@Override
	protected void appendCustomPayload(Document doc, Element registrationDescription) {
		appendNodeWithValue(doc, registrationDescription, ADM_HANDLE_NODE, getPNSHandle());
	}

	@Override
	protected void loadCustomXmlData(Element payloadNode) {
		setPNSHandle(getNodeValue(payloadNode, ADM_HANDLE_NODE));
		setName(DEFAULT_REGISTRATION_NAME);
	}
}

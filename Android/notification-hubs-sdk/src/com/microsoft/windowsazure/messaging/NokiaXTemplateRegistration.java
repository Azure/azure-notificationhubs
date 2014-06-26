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
 * Represents NokiaX template registration
 */

public class NokiaXTemplateRegistration extends TemplateRegistration{

	/**
	 * Custom payload node name for template registrations
	 */
	static final String NOKIAX_TEMPLATE_REGISTRATION_CUSTOM_NODE = "NokiaXTemplateRegistrationDescription";
	
	/**
	 * Custom node name for PNS handle
	 */
	private static final String NOKIAX_HANDLE_NODE = "NOKIAXRegistrationId";

	/**
	 * Creates a new template registration
	 * @param notificationHubPath	The notification hub path
	 */
	NokiaXTemplateRegistration(String notificationHubPath) {
		super(notificationHubPath);
	}
	
	@Override
	protected String getSpecificPayloadNodeName() {
		return NOKIAX_TEMPLATE_REGISTRATION_CUSTOM_NODE;
	}
	
	@Override
	protected void appendCustomPayload(Document doc, Element templateRegistrationDescription) {
		appendNodeWithValue(doc, templateRegistrationDescription, NOKIAX_HANDLE_NODE, getPNSHandle());
		super.appendCustomPayload(doc,templateRegistrationDescription);
	}

	@Override
	protected void loadCustomXmlData(Element payloadNode) {
		setPNSHandle(getNodeValue(payloadNode, NOKIAX_HANDLE_NODE));
		super.loadCustomXmlData(payloadNode);
	}
}

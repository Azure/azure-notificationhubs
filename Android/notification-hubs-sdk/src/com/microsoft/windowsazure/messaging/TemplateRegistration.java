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

import org.w3c.dom.CDATASection;
import org.w3c.dom.CharacterData;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

/**
 * Represents a template registration
 */
public abstract class TemplateRegistration extends Registration {

	/**
	 * The template body
	 */
	private String mBodyTemplate;

	/**
	 * Creates a new template registration
	 * 
	 * @param notificationHubPath	The notification hub path
	 */
	TemplateRegistration(String notificationHubPath) {
		super(notificationHubPath);
	}

	@Override
	protected void appendCustomPayload(Document doc, Element templateRegistrationDescription) {
		appendBodyTemplateNode(doc, templateRegistrationDescription);
		appendNodeWithValue(doc, templateRegistrationDescription, "TemplateName", getName());
	}

	/**
	 * Appends the template body to a registration xml
	 * 
	 * @param doc
	 * @param templateRegistrationDescription
	 */
	private void appendBodyTemplateNode(Document doc, Element templateRegistrationDescription) {
		if (!Utils.isNullOrWhiteSpace(getBodyTemplate())) {
			Element bodyTemplate = doc.createElement("BodyTemplate");
			templateRegistrationDescription.appendChild(bodyTemplate);

			CDATASection bodyTemplateCDATA = doc.createCDATASection(getBodyTemplate());
			bodyTemplate.appendChild(bodyTemplateCDATA);
		}
	}

	@Override
	protected void loadCustomXmlData(Element payloadNode) {
		NodeList bodyTemplateElements = payloadNode.getElementsByTagName("BodyTemplate");
		if (bodyTemplateElements.getLength() > 0) {
			NodeList bodyNodes = bodyTemplateElements.item(0).getChildNodes();
			for (int i = 0; i < bodyNodes.getLength(); i++) {
				if (bodyNodes.item(i) instanceof CharacterData) {
					CharacterData data = (CharacterData) bodyNodes.item(i);
					mBodyTemplate = data.getData();
					break;
				}
			}
		}

		setName(getNodeValue(payloadNode, "TemplateName"));
	}

	/**
	 * Gets the template body
	 */
	public String getBodyTemplate() {
		return mBodyTemplate;
	}

	/**
	 * Sets the template body
	 */
	void setBodyTemplate(String bodyTemplate) {
		mBodyTemplate = bodyTemplate;
	}

	/**
	 * Gets the template name
	 */
	public String getTemplateName() {
		return getName();
	}
}

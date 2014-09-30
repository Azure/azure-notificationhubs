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

import static com.microsoft.windowsazure.messaging.Utils.isNullOrWhiteSpace;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * Represents BAIDU template registration
 */
public class BaiduTemplateRegistration extends TemplateRegistration {

	/**
	 * The Baidu User Id
	 */
	protected String mUserId;
	
	/**
	 * The Baidu Channel Id
	 */
	protected String mChannelId;

	/**
	 * Custom payload node name for template registrations
	 */
	static final String BAIDU_TEMPLATE_REGISTRATION_CUSTOM_NODE = "BaiduTemplateRegistrationDescription";
	
	/**
	 * Baidu User ID.
	 */
	private static final String BAIDU_USER_ID = "BaiduUserId";
	
	/**
	 * Baidu Channel ID.
	 */
	private static final String BAIDU_CHANNEL_ID = "BaiduChannelId";
	
	/**
	 * Custom node name for PNS handle
	 */
	private static final String BAIDU_HANDLE_NODE = "BaiduUserId-BaiduChannelId";

	/**
	 * Creates a new template registration
	 * @param notificationHubPath	The notification hub path
	 */
	BaiduTemplateRegistration(String notificationHubPath) {
		super(notificationHubPath);
		mRegistrationType = RegistrationType.baidu;
	}
	
	/**
	 * Gets the Baidu user Id.
	 */
	public String getUserId() {
		return mUserId;
	}

	/**
	 * Sets the Baidu user Id.
	 */
	void setUserId(String pUserId) {
		mUserId = pUserId;
	}
	
	/**
	 * Gets the Baidu channel Id.
	 */
	public String getChannelId() {
		return mChannelId;
	}

	/**
	 * Sets the Baidu channel Id.
	 */
	void setChannelId(String pChannelId) {
		mChannelId = pChannelId;
	}

	/**
	 * Sets the PNS specific identifier and extract the userId and channelId out of it
	 * the format of pnsHandel for Baidu is: userId-channelId
	 */
	@Override
	void setPNSHandle(String pNSHandle) {
		// @TODO: change
		if (isNullOrWhiteSpace(pNSHandle))
			return;

		mPNSHandle = pNSHandle;
		String[] baiduInfo = pNSHandle.split("-");
		
		String userId = baiduInfo[0];
		
		if (isNullOrWhiteSpace(userId)) {
			throw new AssertionError("Baidu userId is inalid!");
			} 
		setUserId(userId);
		
		String channelId = baiduInfo[1];
		if (isNullOrWhiteSpace(userId)) {
			throw new AssertionError("Baidu channelId is inalid!");
			}
		setChannelId(channelId);
	}

	@Override
	protected String getSpecificPayloadNodeName() {
		return BAIDU_TEMPLATE_REGISTRATION_CUSTOM_NODE;
	}

	@Override
	protected void appendCustomPayload(Document doc, Element templateRegistrationDescription) {
		appendNodeWithValue(doc, templateRegistrationDescription, BAIDU_USER_ID, getUserId());
		appendNodeWithValue(doc, templateRegistrationDescription, BAIDU_CHANNEL_ID, getChannelId());
		super.appendCustomPayload(doc,templateRegistrationDescription);
	}

	@Override
	protected void loadCustomXmlData(Element payloadNode) {
		setPNSHandle(getNodeValue(payloadNode, BAIDU_HANDLE_NODE));
		super.loadCustomXmlData(payloadNode);
	}	
}
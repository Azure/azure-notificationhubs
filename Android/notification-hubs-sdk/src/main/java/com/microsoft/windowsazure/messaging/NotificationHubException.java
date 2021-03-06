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
 * Represents an exception communication with the notification
 */
public class NotificationHubException extends Exception {
	private static final long serialVersionUID = -2417498840698257022L;

	private int mStatusCode;
	
	/**
	 * Creates a NotificationHubException
	 * @param error	The error message
	 * @param statusCode	The status code that the server return
	 */
	NotificationHubException(String error, int statusCode) {
		super(error);
		mStatusCode = statusCode;
	}

	/**
	 * Gets the status code that the server returned
	 */
	public int getStatusCode() {
		return mStatusCode;
	}

}

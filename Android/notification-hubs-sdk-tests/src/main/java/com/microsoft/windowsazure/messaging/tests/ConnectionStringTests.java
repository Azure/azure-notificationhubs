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

package com.microsoft.windowsazure.messaging.tests;

import java.net.URI;

import com.microsoft.windowsazure.messaging.ConnectionString;

import android.test.InstrumentationTestCase;

public class ConnectionStringTests extends InstrumentationTestCase {
	
	public void testCreateConnectionWithFullAccessString() {
		String cs = ConnectionString.createUsingSharedAccessKeyWithFullAccess(URI.create("http://myUrl.com"), "secret123");
		
		assertEquals("Endpoint=http://myUrl.com;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=secret123", cs);
	}
	
	public void testCreateConnectionWithListenAccessString() {
		String cs = ConnectionString.createUsingSharedAccessKeyWithListenAccess(URI.create("http://myUrl.com"), "secret123");
		
		assertEquals("Endpoint=http://myUrl.com;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=secret123", cs);
	}
	
	public void testCreateConnectionWithCustomAccessString() {
		String cs = ConnectionString.createUsingSharedAccessKey(URI.create("http://myUrl.com"), "MyKeyName", "secret123");
		
		assertEquals("Endpoint=http://myUrl.com;SharedAccessKeyName=MyKeyName;SharedAccessKey=secret123", cs);
	}
	
	public void testCreateConnectionWithInvalidValues() {
		try {
			ConnectionString.createUsingSharedAccessKey(null, "keyName", "keyValue");
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			ConnectionString.createUsingSharedAccessKey(URI.create("http://myServer.com"), null, "keyValue");
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
		
		try {
			ConnectionString.createUsingSharedAccessKey(URI.create("http://myServer.com"), "keyName", null);
			fail("invalid parameters");
		} catch (IllegalArgumentException e) {
		}
	}
}
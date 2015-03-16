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

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Connection string parser
 */
class ConnectionStringParser {
	private enum ParserState {
		EXPECT_KEY, EXPECT_ASSIGNMENT, EXPECT_VALUE, EXPECT_SEPARATOR
	}

	private String _value;
	private int _pos;
	private ParserState _state;

	/**
	 * Parses a connection string
	 * @param connectionString	The connection string to parse
	 * @return	A Map with the properties and values defined in the connection string
	 */
	public static Map<String, String> parse(String connectionString) {
		ConnectionStringParser connectionStringParser = new ConnectionStringParser(connectionString);
		return connectionStringParser.parse();
	}

	private ConnectionStringParser(String value) {
		this._value = value;
		this._pos = 0;
		this._state = ParserState.EXPECT_KEY;
	}

	private Map<String, String> parse() {
		HashMap<String, String> result = new HashMap<String, String>();
		String key = null;
		String value = null;
		while (true) {
			this.skipWhitespaces();

			if (this._pos == this._value.length() && this._state != ParserState.EXPECT_VALUE) {
				break;
			}

			switch (this._state) {
			case EXPECT_KEY:
				key = this.extractKey();
				this._state = ParserState.EXPECT_ASSIGNMENT;
				break;

			case EXPECT_ASSIGNMENT:
				this.skipOperator('=');
				this._state = ParserState.EXPECT_VALUE;
				break;

			case EXPECT_VALUE:
				value = this.extractValue();
				this._state = ParserState.EXPECT_SEPARATOR;
				result.put(key, value);
				key = null;
				value = null;
				break;
			default:
				this.skipOperator(';');
				this._state = ParserState.EXPECT_KEY;
				break;
			}
		}

		if (this._state == ParserState.EXPECT_ASSIGNMENT) {
			throw this.createException(this._pos, "Missing character %s", "=");
		}

		return result;
	}

	private IllegalArgumentException createException(int position, String errorString, Object... args) {
		errorString = String.format(errorString, args);
		errorString = String.format("Error parsing connection string: %s. Position %s", errorString, this._pos);

		errorString = String.format("Invalid connection string: %s.", errorString);

		return new IllegalArgumentException(errorString);
	}

	private void skipWhitespaces() {
		while (this._pos < this._value.length() && Character.isWhitespace(this._value.charAt(this._pos))) {
			this._pos++;
		}
	}

	private String extractKey() {
		int pos = this._pos;
		char c = this._value.charAt(this._pos++);
		String text;

		if (c == '"' || c == '\'') {
			text = this.extractString(c);
		} else {
			if (c == ';' || c == '=') {
				throw this.createException(pos, "Missing key");
			}
			while (this._pos < this._value.length()) {
				c = this._value.charAt(this._pos);
				if (c == '=') {
					break;
				}
				this._pos++;
			}
			text = this._value.substring(pos, this._pos).trim();
		}
		if (text.length() == 0) {
			throw this.createException(pos, "Empty key");
		}
		return text;
	}

	private String extractString(char quote) {
		int pos = this._pos;
		while (this._pos < this._value.length() && this._value.charAt(this._pos) != quote) {
			this._pos++;
		}

		if (this._pos == this._value.length()) {
			throw this.createException(this._pos, "Missing character", quote);
		}

		return this._value.substring(pos, this._pos++);
	}

	private void skipOperator(char operatorChar) {
		if (this._value.charAt(this._pos) != operatorChar) {
			throw this.createException(this._pos, "Missing character", operatorChar);
		}

		this._pos++;
	}

	private String extractValue() {
		String result = "";

		if (this._pos < this._value.length()) {
			char c = this._value.charAt(this._pos);

			if (c == '\'' || c == '"') {
				this._pos++;
				result = this.extractString(c);
			} else {
				int pos = this._pos;
				boolean flag = false;
				while (this._pos < this._value.length() && !flag) {
					c = this._value.charAt(this._pos);
					char c2 = c;
					if (c2 == ';') {
						if (this.isStartWithKnownKey()) {
							flag = true;
						} else {
							this._pos++;
						}
					} else {
						this._pos++;
					}
				}
				result = this._value.substring(pos, this._pos).trim();
			}
		}
		return result;
	}

	private boolean isStartWithKnownKey() {
		Locale defaultLocale = Locale.getDefault();

		return this._value.length() <= this._pos + 1 || this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("endpoint")
				|| this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("stsendpoint")
				|| this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("sharedsecretissuer")
				|| this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("sharedsecretvalue")
				|| this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("sharedaccesskeyname")
				|| this._value.substring(this._pos + 1).toLowerCase(defaultLocale).startsWith("sharedaccesskey");
	}
}

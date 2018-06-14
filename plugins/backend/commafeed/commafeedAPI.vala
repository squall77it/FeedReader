//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.CommaFeedAPI : GLib.Object {

	private CommaFeedUtils m_utils;
	private CommaFeedConnection m_connection;
	private string baseUri;
	private DataBaseReadOnly m_db;

	//private Json.Array m_unreadcounts;
	//private GLib.StringBuilder message;
	//public string m_commafeed_url { get; private set; }
	//private string m_commafeed_sessionid;
	//private uint64 m_commafeed_apilevel;

	/**  --- CommaFeed API -----------------------------------------------------
	 */
	public CommaFeedAPI (CommaFeedUtils utils, DataBaseReadOnly db)
	{
		Logger.info("CommaFeed backend: API Init");

		m_db = db;
		m_utils = utils;
		m_connection = new CommaFeedConnection(m_utils);

		baseUri = m_utils.getURL();
	}

	/** --- User API Subset ----------------------------------------------------*/

	/** --- POST - user/login -- Login and create a Session --------------------
	 *
	 * --data { "name": 	"string",		--> login username
	 * 			"password": "string" }		--> login password
	 *
	 * --header "Content-Type: application/json"
	 * --header "Accept: application/json"
	 *
	 * Response Code --> 200 - Response Body --> no content
	 * Response Code --> 401 - Response Body --> wrong username or password
	 */
	public LoginResponse userLogin()
	{
		Logger.info("CommaFeed backend: API login");

		if(!Utils.ping(m_utils.getUnmodifiedURL()))
			return LoginResponse.NO_CONNECTION;

		string username = m_utils.getUser();
		string password = m_utils.getPassword();
		string url = m_utils.getURL();

		if (url == "" && username == "" && password == "")
			return LoginResponse.ALL_EMPTY;

		if (url == "")
			return LoginResponse.MISSING_URL;

		if (username == "")
			return LoginResponse.MISSING_USER;

		if (password == "")
			return LoginResponse.MISSING_PASSWD;

		if (GLib.Uri.parse_scheme(url) == null)
			return LoginResponse.INVALID_URL;

		var object = new Json.Object();
		object.set_string_member("name", username);
		object.set_string_member("password", password);

		return m_connection.login(baseUri + "user/login", object);
	}




}

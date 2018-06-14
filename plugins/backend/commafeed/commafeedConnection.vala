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

public class FeedReader.CommaFeedConnection {

	private CommaFeedUtils m_utils;
	private GLib.Settings m_settingsTweaks;
	private Soup.CookieJar soup_cookiejar;

	public CommaFeedConnection(CommaFeedUtils utils)
	{
		Logger.info("CommaFeed backend: Connection Init");

		m_utils = utils;
		m_settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
		soup_cookiejar = new Soup.CookieJar();
	}

	public LoginResponse login(string path, Json.Object object)
	{
		Logger.info("CommaFeed backend: Connection login");

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		var generator = new Json.Generator();
		generator.set_root(root);

		string json = generator.to_data(null);

		var soup_message = new Soup.Message("POST", path);

		if (m_settingsTweaks.get_boolean("do-not-track"))
			soup_message.request_headers.append("DNT", "1");

		soup_message.request_headers.append("Accept", "application/json");
		soup_message.set_request("application/json", Soup.MemoryUse.COPY, json.data);

		var soup_session = new Soup.Session();
		soup_session.user_agent = Constants.USER_AGENT;
		soup_session.add_feature(soup_cookiejar);

		var status = soup_session.send_message(soup_message);

		if (status == 200)
		{
			Logger.info("Connection Success");
			return LoginResponse.SUCCESS;
		}
		else if (status == 401)
		{
			Logger.error("Wrong Username or Password");
			return LoginResponse.WRONG_LOGIN;
		}
		else if (soup_message.tls_errors != 0 && !m_settingsTweaks.get_boolean("ignore-tls-errors"))
		{
			Logger.info("TLS errors " + Utils.printTlsCertificateFlags(soup_message.tls_errors));
			return LoginResponse.CA_ERROR;
		}
		else if ((string)soup_message.response_body.flatten().data == null ||
				 (string)soup_message.response_body.flatten().data == "")
		{
			Logger.error("No response - status code: %s" .printf(Soup.Status.get_phrase(soup_message.status_code)));
			return LoginResponse.NO_CONNECTION;
		}
		else
		{
			Logger.error("Unknown Error");
			return LoginResponse.UNKNOWN_ERROR;
		}
	}
}

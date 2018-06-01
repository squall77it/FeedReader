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

public class FeedReader.CommaFeedUtils : GLib.Object {

	GLib.Settings m_settings;
	Password m_password;
	Password m_htaccess_password;

	public CommaFeedUtils(GLib.SettingsBackend? settings_backend, Secret.Collection secrets)
	{
		Logger.info("CommaFeed backend: Utils new");

		m_settings = new GLib.Settings("org.gnome.feedreader.commafeed");
		if(settings_backend != null)
			m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.commafeed", settings_backend);
		else
			m_settings = new GLib.Settings("org.gnome.feedreader.commafeed");

		var password_schema =
			new Secret.Schema("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							  "URL", Secret.SchemaAttributeType.STRING,
							  "Username", Secret.SchemaAttributeType.STRING);

		m_password = new Password(secrets, password_schema, "FeedReader: commafeed login", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = getURL();
			attributes["Username"] = getUser();
			return attributes;
		});

		var htAccessSchema =
			new Secret.Schema("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							  "URL", Secret.SchemaAttributeType.STRING,
							  "Username", Secret.SchemaAttributeType.STRING,
							  "htaccess", Secret.SchemaAttributeType.BOOLEAN);

		m_htaccess_password = new Password(secrets, htAccessSchema, "FeedReader: commafeed login", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = getURL();
			attributes["Username"] = getHtaccessUser();
			attributes["htaccess"] = "true";
			return attributes;
		});
	}


	public void setURL(string url)
	{
		Logger.info("CommaFeed backend: Utils setURL");

		Utils.gsettingWriteString(m_settings, "url", url);
	}


	public string getUnmodifiedURL()
	{
		Logger.info("CommaFeed backend: Utils getUnmodifiedURL");

		return Utils.gsettingReadString(m_settings, "url");
	}


	public string getURL()
	{
		Logger.info("CommaFeed backend: Utils getURL");

		string tmp_url = Utils.gsettingReadString(m_settings, "url");
		if(tmp_url != "") {
			if(!tmp_url.has_suffix("/"))
				tmp_url = tmp_url + "/";

			if(!tmp_url.has_suffix("/rest/"))
				tmp_url = tmp_url + "rest/";

			if(!tmp_url.has_prefix("http://") && !tmp_url.has_prefix("https://"))
				tmp_url = "https://" + tmp_url;
		}

		Logger.debug("CommaFeed URL: " + tmp_url);

		return tmp_url;
	}


	public void setUser(string user)
	{
		Logger.info("CommaFeed backend: Utils setUser");

		Utils.gsettingWriteString(m_settings, "username", user);
	}


	public string getUser()
	{
		Logger.info("CommaFeed backend: Utils getUser");

		return Utils.gsettingReadString(m_settings, "username");
	}


	public void setPassword(string password, Cancellable? cancellable = null)
	{
		Logger.info("CommaFeed backend: Utils setPassword");

		m_password.set_password(password, cancellable);
	}


	public string getPassword(Cancellable? cancellable = null)
	{
		Logger.info("CommaFeed backend: Utils getPassword");

		return m_password.get_password(cancellable);
	}


	public void setHtAccessUser(string ht_user)
	{
		Logger.info("CommaFeed backend: Utils setHtaccessUser");

		Utils.gsettingWriteString(m_settings, "htaccess-username", ht_user);
	}


	// FIXME: Typo: getHtaccessUser instead of getHtAccessUser
	public string getHtaccessUser()
	{
		Logger.info("CommaFeed backend: Utils setHtAccessUser");

		return Utils.gsettingReadString(m_settings, "htaccess-username");
	}


	public void setHtAccessPassword(string password, Cancellable? cancellable = null)
	{
		Logger.info("CommaFeed backend: Utils setHtaccessPassword");

		m_htaccess_password.set_password(password, cancellable);
	}


	// FIXME: Issue: "Not return the cancellable string".
	public void getHtAccessPassword(Cancellable? cancellable = null)
	{
		Logger.info("CommaFeed backend: Utils getHtAccessPassword");

		m_htaccess_password.get_password(cancellable);
	}


	public void resetAccount(Cancellable? cancellable = null)
	{
		Logger.info("CommaFeed backend: Utils resetAccount");

		Utils.resetSettings(m_settings);
		m_password.delete_password(cancellable);
		m_htaccess_password.delete_password(cancellable);
	}


/*
	public bool saveIcon(string feed_id, uint8[] feedFavicon)
	{
		string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		if(!path.query_exists())
		{
			try
			{
				path.make_directory_with_parents();
			}
			catch(GLib.Error e)
			{
				Logger.debug("CommaFeedUtils - saveIcon: " + e.message);
			}
		}

		string local_filename = icon_path + feed_id + ".ico";

		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			try
			{
				FileUtils.set_contents(local_filename,
										(string) feedFavicon,
										feedFavicon.length);
			}
			catch(GLib.FileError e)
			{
				Logger.error("CommaFeedUtils - saveIcon: " + e.message);
			}
		}

		return true;
	}
*/
}

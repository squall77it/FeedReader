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

//--------------------------------------------------------------------------------------
// This is the plugin that extends the feedreader-daemon.
// It's job is to fetch all the categories, feeds, tags and articles from the server
// and write them to the data-base. And then notify the UI about the added content
//--------------------------------------------------------------------------------------

public class FeedReader.CommaFeedInterface : Peas.ExtensionBase, FeedServerInterface {



	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;

	private Gtk.Entry m_authUserEntry;
	private Gtk.Entry m_authPasswordEntry;
	private Gtk.Revealer m_revealer;

	private bool m_need_htaccess = false;


	//--------------------------------------------------------------------------------------
	// This method gets executed right after the plugin is loaded. Do everything
	// you need to set up the plugin here.
	//--------------------------------------------------------------------------------------
	public void init(GLib.SettingsBackend? settings_backend, Secret.Collection secrets, DataBaseReadOnly db, DataBase db_write)
	{
		//TODO: Implement init
	}


	//--------------------------------------------------------------------------------------
	// Return the the website/homepage of the project
	//--------------------------------------------------------------------------------------
	public string getWebsite()
	{
		Logger.info("CommaFeed backend: Interface getWebsite");

		return "https://www.commafeed.com/";
	}


	//--------------------------------------------------------------------------------------
	// Return an unique id for the backend. Basically a short form of the name:
	// Tiny Tiny RSS -> "ttrss"
	// Local Backend -> "local"
	//--------------------------------------------------------------------------------------
	public string getID()
	{
		Logger.info("CommaFeed backend: Interface getID");

		return "commafeed";
	}


	//--------------------------------------------------------------------------------------
	// Return flags describing the type of Service
	// - LOCAL
	// - HOSTED
	// - SELF_HOSTED
	// - FREE_SOFTWARE
	// - PROPRIETARY
	// - FREE
	// - PAID_PREMIUM
	// - PAID
	//--------------------------------------------------------------------------------------
	public BackendFlags getFlags()
	{
		Logger.info("CommaFeed backend: Interface getFlags");

		return (BackendFlags.SELF_HOSTED | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}


	//--------------------------------------------------------------------------------------
	// Return the login UI inside a Gtk.Box (username- and password-entries)
	// Return 'null' if use web-login
	//--------------------------------------------------------------------------------------
	public Gtk.Box? getWidget()
	{
		Logger.info("CommaFeed backend: Interface getWidget");

		var url_label = new Gtk.Label(_("CommaFeed URL:"));
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		url_label.set_xalign(1.0f);
		url_label.set_yalign(0.5f);
		user_label.set_xalign(1.0f);
		user_label.set_yalign(0.5f);
		password_label.set_xalign(1.0f);
		password_label.set_yalign(0.5f);

		url_label.set_hexpand(true);
		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_urlEntry = new Gtk.Entry();
		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_urlEntry.activate.connect(() => { login(); });
		m_userEntry.activate.connect(() => { login(); });
		m_passwordEntry.activate.connect(() => { login(); });

		m_passwordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		grid.attach(url_label, 0, 0, 1, 1);
		grid.attach(m_urlEntry, 1, 0, 1, 1);
		grid.attach(user_label, 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 1, 1, 1);
		grid.attach(password_label, 0, 2, 1, 1);
		grid.attach(m_passwordEntry, 1, 2, 1, 1);

		// http auth stuff -----------------------------------------------------
		var auth_user_label = new Gtk.Label(_("Username:"));
		var auth_password_label = new Gtk.Label(_("Password:"));

		auth_user_label.set_xalign(1.0f);
		auth_user_label.set_yalign(0.5f);
		auth_password_label.set_xalign(1.0f);
		auth_password_label.set_yalign(0.5f);

		auth_user_label.set_hexpand(true);
		auth_password_label.set_hexpand(true);

		m_authUserEntry = new Gtk.Entry();
		m_authPasswordEntry = new Gtk.Entry();
		m_authPasswordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_authPasswordEntry.set_visibility(false);

		m_authUserEntry.activate.connect(() => { login(); });
		m_authPasswordEntry.activate.connect(() => { login(); });

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(auth_user_label, 0, 0, 1, 1);
		authGrid.attach(m_authUserEntry, 1, 0, 1, 1);
		authGrid.attach(auth_password_label, 0, 1, 1, 1);
		authGrid.attach(m_authPasswordEntry, 1, 1, 1, 1);

		var frame = new Gtk.Frame(_("HTTP Authorization"));
		frame.set_halign(Gtk.Align.CENTER);
		frame.add(authGrid);
		m_revealer = new Gtk.Revealer();
		m_revealer.add(frame);
		// ---------------------------------------------------------------------

		var logo = new Gtk.Image.from_icon_name("feed-service-commafeed", Gtk.IconSize.MENU);

		var loginLabel = new Gtk.Label(_("Please log in to your CommaFeed server and enjoy using FeedReader"));
		loginLabel.get_style_context().add_class("h2");
		loginLabel.set_justify(Gtk.Justification.CENTER);
		loginLabel.set_lines(3);

		var loginButton = new Gtk.Button.with_label(_("Login"));
		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => { login(); });

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.valign = Gtk.Align.CENTER;
		box.halign = Gtk.Align.CENTER;
		box.pack_start(loginLabel, false, false, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(grid, true, true, 10);
		box.pack_start(m_revealer, true, true, 10);
		box.pack_end(loginButton, false, false, 20);

		//TODO: Implement m_utils.getUnmodifiedURL(), m_utils.getUser(), m_utils.getPassword()
		//m_urlEntry.set_text(m_utils.getUnmodifiedURL());
		//m_userEntry.set_text(m_utils.getUser());
		//m_passwordEntry.set_text(m_utils.getPassword());

		return box;
	}


	//--------------------------------------------------------------------------------------
	// Return the name of the service-icon (non-symbolic).
	//--------------------------------------------------------------------------------------
	public string iconName()
	{
		Logger.info("CommaFeed backend: Interface iconName");

		return "feed-service-commafeed";
	}


	//--------------------------------------------------------------------------------------
	// Return the name of the service as displayed to the user
	//--------------------------------------------------------------------------------------
	public string serviceName()
	{
		Logger.info("CommaFeed backend: Interface serviceName");

		return "CommaFeed";
	}


	//--------------------------------------------------------------------------------------
	// Return wheather the plugin needs a webview to log in via oauth.
	//--------------------------------------------------------------------------------------
	public bool needWebLogin()
	{
		Logger.info("CommaFeed backend: Interface needWebLogin");

		return false;
	}


	//--------------------------------------------------------------------------------------
	// Only important for self-hosted services.
	// If the server is secured by htaccess and a second username and password
	// is required, show the UI to enter those in this methode.
	// If htaccess won't be needed do nothing here.
	//--------------------------------------------------------------------------------------
	public void showHtAccess()
	{
		Logger.info("CommaFeed backend: Interface showHtAccess");

		m_revealer.set_reveal_child(true);
	}


	//--------------------------------------------------------------------------------------
	// Methode gets executed before logging in. Write all the data gathered
	// into gsettings (password, username, access-key).
	//--------------------------------------------------------------------------------------
	public void writeData()
	{
		//TODO: Implement write loggin data to gsettings
	}


	//--------------------------------------------------------------------------------------
	// Do stuff after a successful login
	//--------------------------------------------------------------------------------------
	public async void postLoginAction()
	{
		Logger.info("CommaFeed backend: Interface poastLoginAction");

		return;
	}


	//--------------------------------------------------------------------------------------
	// Only needed if "needWebLogin()" retruned true. Return URL that should be
	// loaded to log in via website.
	//--------------------------------------------------------------------------------------
	public string buildLoginURL()
	{
		Logger.info("CommaFeed backend: Interface buildLoginURL");

		return "";
	}


	//--------------------------------------------------------------------------------------
	// Extract access-key from redirect-URL from webview after loggin in with
	// the webview.
	// Return "true" if extracted sucessfuly, "false" otherwise.
	//--------------------------------------------------------------------------------------
	public bool extractCode(string redirectURL)
	{
		Logger.info("CommaFeed backend: Interface extractCode");

		return false;
	}


	//--------------------------------------------------------------------------------------
	// Does the service you are implementing support tags?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportTags()
	{
		Logger.info("CommaFeed backend: Interface supportTags");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// If the daemon should to an initial sync after logging in.
	// For all online services: true
	// Only for local backend: false
	//--------------------------------------------------------------------------------------
	public bool doInitSync()
	{
		Logger.info("CommaFeed backend: Interface doInitSync");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// What is the symbolic icon-name of the service-logo?
	// Return a string with the name, not the complete path.
	// For example: "feed-service-demo-symbolic"
	//--------------------------------------------------------------------------------------
	public string symbolicIcon()
	{
		Logger.info("CommaFeed backend: Interface symbolicIcon");

		return "feed-service-commafeed-symbolic";
	}


	//--------------------------------------------------------------------------------------
	// Return a name the account of the user can be identified with.
	// This can be the real name of the user, the email-address
	// or any other personal information that identifies the account.
	//--------------------------------------------------------------------------------------
	public string accountName()
	{
		Logger.info("CommaFeed backend: Interface accountName");

		//TODO: Implement m_utils.getUser()
		return ""; //m_utils.getUser();
	}


	//--------------------------------------------------------------------------------------
	// If the service can be self-hosted or has multiple providers
	// you can return the URL of the server here. Preferably without "http://www."
	//--------------------------------------------------------------------------------------
	public string getServerURL()
	{
		Logger.info("CommaFeed backend: Interface getServerURL");

		//TODO: Implement m_utils.getURL()
		return ""; //m_utils.getURL();
	}


	//--------------------------------------------------------------------------------------
	// Many services have different ways of telling if a feed is uncategorized.
	// OwnCloud-News and Tiny Tiny RSS use the id "0", while feedly and InoReader
	// use an empty string ("").
	// Return what this service uses to indicate that the feed does not belong
	// to any category.
	//--------------------------------------------------------------------------------------
	public string uncategorizedID()
	{
		Logger.info("CommaFeed backend: Interface uncategorizedID");

		return "";
	}


	//--------------------------------------------------------------------------------------
	// Sone services have special categories that should not be visible when empty
	// e.g. feedly has a category called "Must Read".
	// Argument: ID of a category
	// Return: wheather the category should be visible when empty
	//--------------------------------------------------------------------------------------
	public bool hideCategoryWhenEmpty(string catID)
	{
		Logger.info("CommaFeed backend: Interface hideCagetoryWhenEmtpy");

		//TODO: What??? False???
		return catID == "0";
	}


	//--------------------------------------------------------------------------------------
	// Does the service support categories at all? (feedbin is weird :P)
	//--------------------------------------------------------------------------------------
	public bool supportCategories()
	{
		Logger.info("CommaFeed backend: Interface supportCategories");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// Does the service support add/remove/rename of categories and feeds?
	//--------------------------------------------------------------------------------------
	public bool supportFeedManipulation()
	{
		Logger.info("CommaFeed backend: Interface supportFeedManipulation");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// Does the service allow categories as children of other categories?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportMultiLevelCategories()
	{
		Logger.info("CommaFeed backend: Interface supportMultiLevelCategories");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// Can one feed be part of more than one category?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportMultiCategoriesPerFeed()
	{
		Logger.info("CommaFeed backend: Interface supportMultiCategoriesPerFeed");

		return false;
	}


	public bool syncFeedsAndCategories()
	{
		Logger.info("CommaFeed backend: Interface syncFeedsAndCategories");

		//TODO: There is no explaination
		return true;
	}


	//--------------------------------------------------------------------------------------
	// Does changing the name of a tag also change it's ID?
	// InoReader tagID's for example look like this:
	// "user/1005921515/label/tagName"
	// So if the name changes the ID changes accordingly. This needs special treatment.
	// Return "true" if this is the case, otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool tagIDaffectedByNameChange()
	{
		Logger.info("CommaFeed backend: Interface tagIDaffectedByNameChange");

		return false;
	}


	//--------------------------------------------------------------------------------------
	// Delete all passwords, keys and user-information.
	// Do not delete feeds or articles from the data-base.
	//--------------------------------------------------------------------------------------
	public void resetAccount()
	{
		Logger.info("CommaFeed backend: Interface resetAccount");

		//TODO: Implement m_utils.resetAccount();
	}


	//--------------------------------------------------------------------------------------
	// State wheater the service syncs articles based on a maximum count
	// or uses something else (OwnCloud uses the last synced articleID)
	//--------------------------------------------------------------------------------------
	public bool useMaxArticles()
	{
		Logger.info("CommaFeed backend: Interface useMaxArticles");

		// TODO: Verify if must be true or false
		return true;
	}

	//--------------------------------------------------------------------------------------
	// Log in to the account of the service. If there is no need or API to sign in,
	// check all passwords or keys and make sure the service is reachable and works.
	// Possible return values are:
	// - SUCCESS
	// - MISSING_USER
	// - MISSING_PASSWD
	// - MISSING_URL
	// - ALL_EMPTY
	// - UNKNOWN_ERROR
	// - FIRST_TRY
	// - NO_BACKEND
	// - WRONG_LOGIN
	// - NO_CONNECTION
	// - NO_API_ACCESS
	// - UNAUTHORIZED
	// - CA_ERROR
	// - PLUGIN_NEEDED
	//--------------------------------------------------------------------------------------
	public LoginResponse login()
	{
		Logger.info("CommaFeed backend: Interface login");

		//TODO: Implement m_api.userLogin()
		return LoginResponse.UNKNOWN_ERROR; //m_api.userLogin();
	}


	//--------------------------------------------------------------------------------------
	// If it is possible to log out of the account of the service, do so here.
	// If not, do nothing and return "true".
	//--------------------------------------------------------------------------------------
	public bool logout()
	{
		Logger.info("CommaFeed backend: Interface logout");

		return true;
	}


	//--------------------------------------------------------------------------------------
	// Check if the service is reachable.
	// You can use the method Utils.ping() if the service doesn't provide anything.
	//--------------------------------------------------------------------------------------
	public bool serverAvailable()
	{
		Logger.info("CommaFeed backend: Interface serverAvailable");

		//TODO: Implement Utils.ping(m_utils.getUnmodifiedURL());
		return true; //Utils.ping(m_utils.getUnmodifiedURL());
	}


	//--------------------------------------------------------------------------------------
	// Method to set the state of articles to read or unread
	// "articleIDs": comma separated string of articleIDs e.g. "id1,id2,id3"
	// "read": the state to apply. ArticleStatus.READ or ArticleStatus.UNREAD
	//--------------------------------------------------------------------------------------
	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		Logger.info("CommaFeed backend: Interface setArticleIsRead");

		//TODO: Implement m_api.updateArticleUnread(articleIDs, read);
	}


	//--------------------------------------------------------------------------------------
	// Method to set the state of articles to marked or unmarked
	// "articleID": single articleID
	// "read": the state to apply. ArticleStatus.MARKED or ArticleStatus.UNMARKED
	//--------------------------------------------------------------------------------------
	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		Logger.info("CommaFeed backend: Interface setArticleIsMarked");

		//TODO: Verify the implementation
/*		string feedId = m_db.getFeedIDofArticle(articleID);

		if (marked == ArticleStatus.MARKED)
		{
			m_api.entryStar(articleID, int.parse(feedId), true);
		}
		else
		{
			m_api.entryStar(articleID, int.parse(feedId), false);
		}
*/	}


	//--------------------------------------------------------------------------------------
	// Mark all articles of the feed as read
	//--------------------------------------------------------------------------------------
	public void setFeedRead(string feedID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Mark all articles of the feeds that are part of the category as read
	//--------------------------------------------------------------------------------------
	public void setCategoryRead(string catID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Mark ALL articles as read
	//--------------------------------------------------------------------------------------
	public void markAllItemsRead()
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Add an existing tag to the article
	//--------------------------------------------------------------------------------------
	public void tagArticle(string articleID, string tagID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Remove an existing tag from the article
	//--------------------------------------------------------------------------------------
	public void removeArticleTag(string articleID, string tagID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Create a new tag with the title of "caption" and return the id of the
	// newly added tag.
	// Hint: some services don't have API to create tags, but instead create them
	// on the fly when tagging articles. In this case just compose the tagID
	// following the schema tha service uses and return it.
	//--------------------------------------------------------------------------------------
	public string createTag(string caption)
	{
		Logger.info("CommaFeed backend: Interface createTag");

		//TODO: Implement m_api.addLabel(caption).to_string();
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Delete a tag completely
	//--------------------------------------------------------------------------------------
	public void deleteTag(string tagID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Rename the tag with the id "tagID" to the new name "title"
	//--------------------------------------------------------------------------------------
	public void renameTag(string tagID, string title)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Subscribe to the URL "feedURL"
	// "catID": the category the feed should be placed into, "null" otherwise
	// "newCatName": the name of a new category the feed should be put in, "null" otherwise
	//--------------------------------------------------------------------------------------
	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		//TODO: Implement this function
		return false;
	}


	public void addFeeds(Gee.List<Feed> feeds)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Remove the feed with the id "feedID" completely
	//--------------------------------------------------------------------------------------
	public void removeFeed(string feedID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Rename the feed with the id "feedID" to "title"
	//--------------------------------------------------------------------------------------
	public void renameFeed(string feedID, string title)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Move the feed with the id "feedID" from its current category
	// to any other category. "currentCatID" is only needed if the
	// feed can be part of multiple categories at once.
	//--------------------------------------------------------------------------------------
	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Create a new category
	// "title": title of the new category
	// "parentID": only needed if multi-level-categories are supported
	// Hint: some services don't have API to create categories, but instead create them
	// on the fly when movin feeds over to them. In this case just compose the categoryID
	// following the schema tha service uses and return it.
	//--------------------------------------------------------------------------------------
	public string createCategory(string title, string? parentID)
	{
		//TODO: Implement this function
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Rename the category with the id "catID" to "title"
	//--------------------------------------------------------------------------------------
	public void renameCategory(string catID, string title)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Move the category with the id "catID" into another category
	// with the id "newParentID"
	// This method is only used if multi-level-categories are supported
	//--------------------------------------------------------------------------------------
	public void moveCategory(string catID, string newParentID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Delete the category with the id "catID"
	//--------------------------------------------------------------------------------------
	public void deleteCategory(string catID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Rename the feed with the id "feedID" from the category with the id "catID"
	// Don't delete the feed entirely, just remove it from the category.
	// Only useful if feed can be part of multiple categories.
	//--------------------------------------------------------------------------------------
	public void removeCatFromFeed(string feedID, string catID)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Import the content of "opml"
	// If the service doesn't provide API to import OPML you can use the
	// OPMLparser-class
	//--------------------------------------------------------------------------------------
	public void importOPML(string opml)
	{
		//TODO: Implement this function
	}


	//--------------------------------------------------------------------------------------
	// Get all feeds, categories and tags from the service
	// Fill up the emtpy LinkedList's that are provided with instances of the
	// model-classes category, feed and article
	//--------------------------------------------------------------------------------------
	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
	{
		//TODO: Implement this function
		return false;
	}


	//--------------------------------------------------------------------------------------
	// Return the total count of unread articles on the server
	//--------------------------------------------------------------------------------------
	public int getUnreadCount()
	{
		//TODO: Implement this function
		return 0;
	}


	//--------------------------------------------------------------------------------------
	// Get the requested articles and write them to the data-base
	//
	// "count":		the number of articles to get
	// "whatToGet":	the kind of articles to get (all/unread/marked/etc.)
	// "since":     how far back to sync articles (null = no limit)
	// "feedID":	get only articles of a secific feed or tag
	// "isTagID":	false if "feedID" is a feed-ID, true if "feedID" is a tag-ID
	//
	// It is recommended after getting the articles from the server to use the signal
	// "writeArticles(Gee.List<Article> articles)"
	// to automatically process them in the content-grabber, write them to the
	// data-base and send all the signals to the UI to update accordingly.
	// But if the API suggests a different approach you can everything on your
	// own (see ttrss-backend).
	//--------------------------------------------------------------------------------------
	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		//TODO: Implement this function
	}

}


//--------------------------------------------------------------------------------------
// Boilerplate code for the plugin. Replace "demoInterface" with the name
// of your interface-class.
//--------------------------------------------------------------------------------------
[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.CommaFeedInterface));
}

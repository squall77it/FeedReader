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

public class FeedReader.tag : GLib.Object {

	private string m_tagID;
	private string m_title;
	private int m_color;

	public tag (string tagID, string title, int color) {
		m_tagID = GLib.Base64.encode(tagID.data);
		m_title = title;
		m_color = color;
	}

	public string getTagID()
	{
		return m_tagID;
	}

	public string getRawTagID()
	{
		return (string)GLib.Base64.decode(m_tagID);
	}

	public string getTitle()
	{
		return m_title;
	}

	public int getColor()
	{
		return m_color;
	}
}

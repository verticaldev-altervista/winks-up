/*
* winks-u.vala - Lightweight enanched Browser
* 
* based on winks 
*
* Copyright (C) 2010 Graham Thomson <graham.thomson@gmail.com>
* Released under the GNU General Public License (GPL) version 2.
* See COPYING
*/

using Gtk; 
using GLib;
using WebKit;
using Soup;

public class winks: Window {
	// constants
	private const bool DEBUG = false;
	private const string TITLE = "winks-up";
	private const string HOME_URL = "http://www.google.com/";
	private const string DEFAULT_PROTOCOL = "http";
	private const string VERSION_STRING = "Winks-up 0.01";

	// regex required
	private Regex protocol_regex;
	private Regex search_check_regex;

	// variables used globally
	private int zoom_level;
	private Session my_session;
	private CookieJarText http_cookies;
	private Entry url_bar;
	private Button back_btn;
	private Button forward_btn;
	private Button home_btn;
	private Button min_btn;	
	private Button exit_btn;

	private WebView web_view;
	private WebSettings web_settings;
	private ScrolledWindow scrolled_window;

	// constructor
	public winks () {
		this.title = winks.TITLE;
		set_default_size (640,480);
		this.set_decorated(false);
		this.maximize();
		//this.web_view.full_content_zoom=true;


		// Setup required Regex objects
		try {
			this.protocol_regex = new Regex (".*://.*");
			this.search_check_regex = new Regex (".*[.].*");
		} 
		catch (RegexError e) {
			critical ("%s", e.message);
		}

		// Load icon for Application
		try {
			var icon_file = File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up/winks.png");
			var config_dir = File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up");
			if (!config_dir.query_exists ()) {
				try{
					config_dir.make_directory_with_parents(null);
					var web_icon = File.new_for_uri ("https://dl.dropboxusercontent.com/u/6053180/w-up/wup.png");
					web_icon.copy (icon_file, FileCopyFlags.NONE);
				} 
				catch (Error e) {
					if(DEBUG)stderr.printf ("Could not create config dir: %s\n", e.message);
				}
			}
			this.icon = new Gdk.Pixbuf.from_file (icon_file.get_path ());
		} 
		catch (Error e) {
			if(DEBUG)stderr.printf ("Could not load application icon: %s\n", e.message);
		}

		// Load/Create storage for cookies
		var cookie_file = File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up/cookies.txt");
		if (!cookie_file.query_exists ()) {
			try {
				cookie_file.create (FileCreateFlags.NONE);
			} 
			catch (Error e) {
				if(DEBUG)stderr.printf ("Could not create cookie jar: %s\n", e.message);
			}
		}
		this.http_cookies = new CookieJarText (cookie_file.get_path (), false);
		
		// create download script
		var dl_file=File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up/dl.sh");
		if (!dl_file.query_exists ()) {
			try {
				FileOutputStream os=dl_file.create (FileCreateFlags.NONE);
				DataOutputStream dos = new DataOutputStream (os);
				dos.put_string("#!/bin/bash \n wget $1 |zenity --progress   --text=\"download $1\" --pulsate --auto-kill\n"); 
				GLib.Process.spawn_command_line_async ("chmod 0777 "+Environment.get_home_dir ()+"/.config/winks-up/dl.sh");
				
			} 
			catch (Error e) {
				if(DEBUG)stderr.printf ("Could not create cookie jar: %s\n", e.message);
			}
		}
		

		create_widgets ();
		connect_signals ();

		// Session stuff (required for cookies)
		this.my_session = get_default_session ();
		this.http_cookies.attach (this.my_session);

		// zoom indicator
		this.zoom_level = 0;
		// zoom type
		this.web_view.set_full_content_zoom (true);

		// move focus onto the url bar
		this.url_bar.grab_focus ();
	}

	// draw what we need
	private void create_widgets () {
		var grid = new Grid ();
	
		this.url_bar = new Entry ();
		url_bar.set_hexpand(true);

		this.back_btn = new Button();
		back_btn.set_label("<");

		this.forward_btn = new Button();
		forward_btn.set_label(">");

		this.home_btn = new Button();
		home_btn.set_label(" Hm ");

		this.min_btn = new Button();
		min_btn.set_label("_");

   		this.exit_btn = new Button();
		exit_btn.set_label("X");

		grid.attach(back_btn,0,1,1,1);
		grid.attach(forward_btn,1,1,1,1);
		grid.attach(home_btn,2,1,1,1);
		grid.attach(url_bar,3,1,1,1);
		grid.attach(min_btn,4,1,1,1);		
		grid.attach(exit_btn,5,1,1,1);
   		
		this.web_settings = new WebSettings ();
		this.web_settings.enable_page_cache = true;
		this.web_settings.user_agent = (this.web_settings.user_agent+" "+VERSION_STRING.replace(" ", "/"));
		this.web_view = new WebView ();
		this.web_view.set_settings (this.web_settings);
		
		this.scrolled_window = new ScrolledWindow (null, null);
		this.scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		this.scrolled_window.add (this.web_view);
		
		var main_area = new Box (Gtk.Orientation.VERTICAL, 0);
		main_area.pack_start(grid, false, true, 0);
		main_area.pack_end (this.scrolled_window,true,true,0);
		this.add (main_area);
	}

	// deal with signals
	private void connect_signals () {
		this.destroy.connect (Gtk.main_quit);
		this.exit_btn.clicked.connect(Gtk.main_quit);
		this.home_btn.clicked.connect (()=>{this.web_view.open(winks.HOME_URL);});
		this.min_btn.clicked.connect (this.iconify);
		this.back_btn.clicked.connect (this.web_view.go_back);
		this.forward_btn.clicked.connect (this.web_view.go_forward);
		this.key_press_event.connect (on_key_pressed);
		this.url_bar.activate.connect (on_activate);

		this.url_bar.activate.connect (on_activate);
		this.web_view.title_changed.connect ((source, frame, title) => {
			this.title = "%s - %s".printf (title, winks.TITLE);
		});
		this.web_view.load_committed.connect ((source, frame) => {
			this.url_bar.text = frame.get_uri ();
		});
		this.web_view.new_window_policy_decision_requested.connect ((source, frame, request, action, decision) => {
			web_view.open (request.get_uri ());
			//GLib.Process.spawn_command_line_async ("./w-up "+request.get_uri ());
			return true;
		});

		this.web_view.mime_type_policy_decision_requested.connect ((frame, request, mime, decision) =>{
			if(DEBUG)print("Mime:%s\n",mime); 
			if (mime!="text/html"){
				try{
					if(DEBUG)print( "Download:%s\n",request.get_uri ());
					GLib.Process.spawn_command_line_async (Environment.get_home_dir ()+"/.config/winks-up/dl.sh "+request.get_uri ());
				}
				catch (Error e) {
					if(DEBUG)stderr.printf ("Error to run download script: %s\n", e.message);
				}
				return false;
			}
			return true;
		});
		
		this.web_view.navigation_policy_decision_requested.connect (
			(source, frame, request, action, decision) => {
				// Find out if we have a cookie for this request
				string found_cookie = this.http_cookies.get_cookies(request.message.get_uri(), true);
				if (found_cookie != null) {
					if(DEBUG)print ("Found Cookie: %s\n", found_cookie);
					request.message.request_headers.append("Cookie", found_cookie);
				}
				else {
					if(DEBUG)print ("No Cookie for: %s\n", request.get_uri ());
				}
				// return true
				decision.use ();
				return true;
			}	
		);
		this.web_view.load_started.connect ((source, frame) => {
			this.url_bar.set_progress_fraction (0.0);
		});
		this.web_view.load_progress_changed.connect ((source, progress) => {
			string the_progress = ("0."+progress.to_string ()).substring(0,3);
			this.url_bar.set_progress_fraction (the_progress.to_double ());
		});
		this.web_view.load_finished.connect ((source, frame) => {
			this.url_bar.set_progress_fraction (0.0);
		});
	}

	private bool on_key_pressed (Widget source, Gdk.EventKey key) {

		if (key.str[0] == 27) {
			this.url_bar.text = "";
			this.url_bar.grab_focus ();
			this.web_view.zoom_level = 1;
			this.web_view.set_full_content_zoom (true);
			return true;
		}

		if ((key.state & 4)!=0 ) {
			if (key.str == "+") {
				this.web_view.set_full_content_zoom (true);
				this.web_view.zoom_in();
				return true;
			}
			if (key.str == "-") {
				this.web_view.set_full_content_zoom (true);
				this.web_view.zoom_out();
				return true;
			}
		}
		return false;
	}
	
	// load a url using soup
	private void load_url (string url) {
		// try some session stuff here
		var message = new Soup.Message ("GET", url);
		// Find out if we have a cookie for this request
		string found_cookie = this.http_cookies.get_cookies(message.get_uri(), true);
		if (found_cookie != null) {
			if(DEBUG)print ("Found Cookie: %s\n", found_cookie);
			message.request_headers.append("Cookie", found_cookie);
		}
		else {
			if(DEBUG)print ("No Cookie for: %s\n", url);
		}
		this.my_session.send_message (message);

		// now open the url
		this.web_view.load_html_string ((string)message.response_body.data, url);
		this.web_view.open (url);
	}

	// deal with someone activating the url/command bar
	private void on_activate () {
		var url = this.url_bar.text;
		var alias=url.split(" ");
		if (alias[0]=="alias"){
			try{
				if(DEBUG)print ("found alias %s - %s\n",alias[1],alias[2]);
				var alias_file=File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up/alias");
				OutputStream ostream=alias_file.append_to(FileCreateFlags.NONE);
				DataOutputStream dos = new DataOutputStream (ostream);
				dos.put_string("%s=%s\n".printf (alias[1],alias[2])); 
				url=alias[2];
				this.url_bar.text=url;
			 } 
			 catch (Error e) {
				if(DEBUG)stderr.printf ("Could not create alias file: %s\n", e.message);
			}
		}
		//check alias
		url=this.chk_alias(url);
		
		// we have a url or search
		if (!this.protocol_regex.match (url)) {
			if (!this.search_check_regex.match (url)) {
				url = "http://www.google.com/search?q="+url;
			}
			else {
				url = "%s://%s".printf (winks.DEFAULT_PROTOCOL, url);
			}
		}
		// load the url
		load_url (url);
		this.scrolled_window.grab_focus ();
	}
	
	//alias 
	private  string chk_alias(string url){
		string newurl=url;
		File file = File.new_for_path (Environment.get_home_dir ()+"/.config/winks-up/alias");
		try {
			FileInputStream @is = file.read ();
			DataInputStream dis = new DataInputStream (@is);
			string line;

			while ((line = dis.read_line ()) != null) {
				var alias=line.split("=");
				if (newurl==alias[0]){
					if(DEBUG)print ("request %s:alias %s - url %s\n",url,alias[0],alias[1]);
					newurl=alias[1];
				}
			}
		} 
		catch (Error e) {
			if(DEBUG)stdout.printf ("Error: %s\n", e.message);
		}
		return newurl;
	}
			
	// start the ball rolling
	public void start (string passed_url) {
		show_all ();
		if (this.protocol_regex.match (passed_url)) {
			//load the passed url
			load_url (passed_url);
		} 
		else {
			//load the homepage
			load_url (winks.HOME_URL);
		}
		this.scrolled_window.grab_focus ();
	}

	// main function
	public static int main (string[] args) {
		Gtk.init (ref args);

		var browser = new winks ();

		if (args[1] != null) {
			browser.start (args[1]); 
		} 
		else {
			browser.start (winks.HOME_URL);
		}

		Gtk.main ();

		return 0;
	}
}

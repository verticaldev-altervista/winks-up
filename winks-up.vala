/*
 * winks-up.vala - Lightweight WebKit2GTK browser
 *
 * by vroby <vroby.mai@gmail.com>
 * based on winks by Graham Thomson <graham.thomson@gmail.com>
 * Copyright (C) 2010 Graham Thomson
 * Released under the GNU General Public License (GPL) version 2.
 */

using Gtk;
using GLib;
using WebKit;

public class Winks : Window {
    private const string TITLE = "winksUp";
    private const string HOME_URL = "http://vroby.ddns.net/main.php";
    private const string SEARCH_URL = "https://duckduckgo.com/html/?q=";
    private const string VERSION = "Winks-Up 0.04";

    private double zoom_level;
    private bool is_loading = false;

    private Entry url_bar;
    private Button back_btn;
    private Button forward_btn;
    private Button reload_home_btn;
    private Button home_btn;
    private Button min_btn;
    private Button exit_btn;
    private WebView web_view;
    private ScrolledWindow scrolled_window;
    private Label zoom_label;
    private ProgressBar progress_bar;
    private CookieManager cookie_manager;

    public Winks() {
        this.title = TITLE;
        set_default_size(640, 480);
        this.set_decorated(false);
        this.maximize();

        load_icon();
        create_widgets();
        connect_signals();

        this.zoom_level = 1.0;
        this.url_bar.grab_focus();
    }

    private void load_icon() {
        try {
            var base64_icon = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3ggYCBEYD5sJsAAAA0VJREFUWMPFl71vE1kQwH+zXsfE5C4sVoIiUUCcoByUgQJRoYgCiugAJbRUd+LElRRIfEiA4A+44khJQZPIIApEgSgB0fIhJE7WIZBOfCj75A8C8ccOxXoXr7MhNmcn09jefZ75vZl582b4h40ViXuYd5zBZTgsIvtVdRTVTT+mXb4gkgceJ+HeuOsW1wR46TinFS4BTie2ksaseFZ1Iipc4NxuY/5eFeCF48wJ/NbpRuOMrwIBcH23MadWADR2/ler0hgFaxpdC0Lh1B5jrocAjZj/2+z2Tgz8AMRiUmR03HWLFkBF9dfAeNKYrhuP2VCmojoNYAF4InvX+/hZIvtCAIGh9QZQ1W3NANYGFCArBOhV4rUViuDL0JUrjKmSrVbBtkkMD5P1PMZU2ZbLAeBcvhxZ01WA4q1bqCokEiR27CB14AAifplIHzwIwMDRo/6RevMGarXuAiy/egWqiAgD09MMzM76yeJ5WIODkMnQt2sXAJ/u3IFMJvTQpqkp2LIl/N1/5Aik02TrdcZU2VkskvU8JhYXGX3yBBKJlQCUy3iNHBg4fpzNhw6hqlSePgURNk9NgW2jqpQWFjpLONum3AhjanycobNnYwCAT/fv+4smJ7EcB61UKN68iYjgnDnjh0SVyvPnHQEsXrzI+5kZKq9fA/DzsWPxAOX5eZ+4rw+xLCrPnlHO5VBVUpOTAHiFApRK0R2mUiT6+1ePczrtf6ZSwTUdvouk8vLDh2gjDwDKt29Tf/sW6nWkkfVLDx74iwsFqNfBthmem0NEwv+1ytbz5/npxAnskRE/4RvhWOGB+ocP6OfPQaWilMtBrUY1n//mpSD+tRru1auoKsnt27EyGf8UxYjnuiQnJvxN5vN8vHYt2g+8dJx5hZmuFqJ0mmyphFgW706epHzjRuRGFFj4xZjZdS/BrWL3TPPSEvmm875mIfpe99ODhiQKoOD1GqI1vwKbAcDHdb+ORd6HABY87nUoYhrTR2ES9sHdZTDtzgJVxyFpTKi02b2t71arzkm4F3oga0xB4EK7iRMYjGtg26klCueCKakrg0mHEhlMIsdwjzG/C/yJH45uiwv80Wy8reEU1ZH/1f2K/Pe94XTD5Sv7W1lY+iRtwAAAAABJRU5ErkJggg==";
            var icon_data = GLib.Base64.decode(base64_icon);
            var loader = new Gdk.PixbufLoader();
            loader.write(icon_data);
            loader.close();
            this.icon = loader.get_pixbuf();
        } catch (Error e) {
            stderr.printf("Could not load application icon: %s\n", e.message);
        }
    }

    private void create_widgets() {
        // Navigation bar
        var nav_grid = new Grid();
        nav_grid.set_column_spacing(2);

        this.back_btn = new Button.from_icon_name("go-previous-symbolic", IconSize.BUTTON);
        back_btn.set_tooltip_text("Back");

        this.forward_btn = new Button.from_icon_name("go-next-symbolic", IconSize.BUTTON);
        forward_btn.set_tooltip_text("Forward");

        // Reload button also acts as Stop button
        this.reload_home_btn = new Button.from_icon_name("view-refresh-symbolic", IconSize.BUTTON);
        reload_home_btn.set_tooltip_text("Reload");

        this.home_btn = new Button.from_icon_name("go-home-symbolic", IconSize.BUTTON);
        home_btn.set_tooltip_text("Home");

        this.url_bar = new Entry();
        url_bar.set_hexpand(true);
        url_bar.set_placeholder_text("Enter URL or search term...");
        url_bar.set_input_purpose(Gtk.InputPurpose.URL);

        this.zoom_label = new Label("100%");
        zoom_label.set_width_chars(5);

        this.min_btn = new Button.from_icon_name("window-minimize-symbolic", IconSize.BUTTON);
        min_btn.set_tooltip_text("Minimize");

        this.exit_btn = new Button.from_icon_name("window-close-symbolic", IconSize.BUTTON);
        exit_btn.set_tooltip_text("Close");

        nav_grid.attach(back_btn, 0, 0, 1, 1);
        nav_grid.attach(forward_btn, 1, 0, 1, 1);
        nav_grid.attach(reload_home_btn, 2, 0, 1, 1);
        nav_grid.attach(home_btn, 3, 0, 1, 1);
        nav_grid.attach(url_bar, 4, 0, 1, 1);
        nav_grid.attach(zoom_label, 5, 0, 1, 1);
        nav_grid.attach(min_btn, 6, 0, 1, 1);
        nav_grid.attach(exit_btn, 7, 0, 1, 1);

        // WebView
        this.web_view = new WebView();

        var settings = web_view.get_settings();
        settings.enable_webgl = true;
        settings.enable_page_cache = true;
        settings.enable_developer_extras = true;
        settings.user_agent = settings.user_agent + " " + VERSION;
        web_view.set_settings(settings);

        // Progress bar (hidden by default)
        this.progress_bar = new ProgressBar();
        progress_bar.set_show_text(false);
        progress_bar.set_no_show_all(true);

        ScrolledWindow sw = new ScrolledWindow(null, null);
        sw.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        sw.vexpand = true;
        sw.hexpand = true;
        sw.add(web_view);
        this.scrolled_window = sw;

        var main_area = new Box(Orientation.VERTICAL, 0);
        main_area.pack_start(nav_grid, false, true, 0);
        main_area.pack_start(progress_bar, false, true, 0);
        main_area.pack_end(sw, true, true, 0);
        this.add(main_area);
    }

    private void connect_signals() {
        this.destroy.connect(Gtk.main_quit);
        this.exit_btn.clicked.connect(Gtk.main_quit);
        this.min_btn.clicked.connect(this.iconify);

        // Navigation
        this.back_btn.clicked.connect(() => web_view.go_back());
        this.forward_btn.clicked.connect(() => web_view.go_forward());
        this.reload_home_btn.clicked.connect(on_reload_home);
        this.home_btn.clicked.connect(() => web_view.load_uri(HOME_URL));

        // URL bar
        this.url_bar.activate.connect(on_activate);

        // Keyboard
        this.key_press_event.connect(on_key_pressed);

        // WebView signals
        web_view.load_changed.connect(on_load_changed);
        web_view.notify["estimated-load-progress"].connect(() => {
            progress_bar.set_fraction(web_view.estimated_load_progress);
        });
        web_view.notify["is-loading"].connect(on_loading_changed);
        web_view.notify["uri"].connect(() => {
            if (web_view.uri != null)
                url_bar.text = web_view.uri;
        });
        web_view.notify["title"].connect(() => {
            if (web_view.title != null)
                this.title = "%s — %s".printf(web_view.title, TITLE);
        });

        // Update nav button sensitivity
        web_view.notify["can-go-back"].connect(() => {
            back_btn.set_sensitive(web_view.can_go_back());
        });
        web_view.notify["can-go-forward"].connect(() => {
            forward_btn.set_sensitive(web_view.can_go_forward());
        });

        // Handle new windows in same tab
        web_view.decide_policy.connect(on_decide_policy);

        // Custom context menu
        web_view.context_menu.connect(on_context_menu);

        // Ctrl+scroll for zoom
        web_view.scroll_event.connect(on_scroll);

        // Downloads
        web_view.get_context().download_started.connect(on_download_started);

        // Cookies — persistent SQLite storage
        this.cookie_manager = web_view.get_context().get_cookie_manager();
        var config_dir = Path.build_filename(Environment.get_user_config_dir(), "winks-up");
        DirUtils.create_with_parents(config_dir, 0755);
        cookie_manager.set_persistent_storage(
            Path.build_filename(config_dir, "cookies.db"),
            CookiePersistentStorage.SQLITE
        );

        // Initialize button states
        back_btn.set_sensitive(false);
        forward_btn.set_sensitive(false);
    }

    private void on_reload_home() {
        if (is_loading) {
            web_view.stop_loading();
        } else {
            web_view.reload();
        }
    }

    private void on_load_changed(LoadEvent load_event) {
        if (load_event == LoadEvent.FINISHED) {
            url_bar.text = web_view.uri;
        }
    }

    private void on_loading_changed() {
        is_loading = web_view.is_loading;
        if (is_loading) {
            reload_home_btn.set_image(
                new Image.from_icon_name("process-stop-symbolic", IconSize.BUTTON));
            reload_home_btn.set_tooltip_text("Stop");
            progress_bar.set_visible(true);
        } else {
            reload_home_btn.set_image(
                new Image.from_icon_name("view-refresh-symbolic", IconSize.BUTTON));
            reload_home_btn.set_tooltip_text("Reload");
            progress_bar.set_visible(false);
            progress_bar.set_fraction(0.0);
        }
    }

    private void on_activate() {
        string text = url_bar.text.strip();
        if (text == "") return;

        string url;
        if (!text.has_prefix("http://") && !text.has_prefix("https://")) {
            if (text.contains(".") && !text.contains(" ")) {
                url = "http://" + text;
            } else {
                url = SEARCH_URL + Uri.escape_string(text);
            }
        } else {
            url = text;
        }
        web_view.load_uri(url);
        scrolled_window.grab_focus();
    }

    private bool on_key_pressed(Gdk.EventKey key) {
        // ESC — focus and clear URL bar
        if (key.keyval == Gdk.Key.Escape) {
            url_bar.text = "";
            url_bar.grab_focus();
            return true;
        }

        if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            switch (key.keyval) {
                case Gdk.Key.plus:
                case Gdk.Key.equal:
                    zoom_in();
                    return true;
                case Gdk.Key.minus:
                    zoom_out();
                    return true;
                case Gdk.Key.@0:
                    zoom_reset();
                    return true;
                case Gdk.Key.r:
                case Gdk.Key.R:
                    web_view.reload();
                    return true;
                case Gdk.Key.q:
                case Gdk.Key.Q:
                    Gtk.main_quit();
                    return true;
            }
        }

        if (key.keyval == Gdk.Key.F5) {
            web_view.reload();
            return true;
        }

        if (key.keyval == Gdk.Key.Delete
            && (key.state & Gdk.ModifierType.CONTROL_MASK) != 0
            && (key.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
            clear_cookies();
            return true;
        }

        if (key.keyval == Gdk.Key.F11) {
            var gdk_win = this.get_window();
            if (gdk_win != null && (gdk_win.get_state() & Gdk.WindowState.FULLSCREEN) != 0)
                this.unfullscreen();
            else
                this.fullscreen();
            return true;
        }

        return false;
    }

    private void zoom_in() {
        zoom_level = double.min(zoom_level + 0.1, 3.0);
        web_view.set_zoom_level((float)zoom_level);
        update_zoom_label();
    }

    private void zoom_out() {
        zoom_level = double.max(zoom_level - 0.1, 0.3);
        web_view.set_zoom_level((float)zoom_level);
        update_zoom_label();
    }

    private void zoom_reset() {
        zoom_level = 1.0;
        web_view.set_zoom_level((float)zoom_level);
        update_zoom_label();
    }

    private void update_zoom_label() {
        zoom_label.set_text("%.0f%%".printf(zoom_level * 100.0));
    }

    private bool on_scroll(Gdk.EventScroll event) {
        if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            if (event.direction == Gdk.ScrollDirection.UP) {
                zoom_in();
                return true;
            } else if (event.direction == Gdk.ScrollDirection.DOWN) {
                zoom_out();
                return true;
            }
        }
        return false;
    }

    private bool on_decide_policy(PolicyDecision decision, PolicyDecisionType type) {
        if (type == PolicyDecisionType.NEW_WINDOW_ACTION) {
            var nav_decision = decision as NavigationPolicyDecision;
            if (nav_decision != null) {
                var nav_action = nav_decision.get_navigation_action();
                string uri = nav_action.get_request().uri;
                decision.ignore();
                // Defer load so WebKit properly records back-forward history
                Idle.add(() => {
                    web_view.load_uri(uri);
                    return false;
                });
                return true;
            }
        } else if (type == PolicyDecisionType.RESPONSE) {
            var response_decision = decision as ResponsePolicyDecision;
            if (response_decision != null) {
                var response = response_decision.get_response();
                if (response != null) {
                    var mime_type = response.get_mime_type();
                    if (mime_type != null && !web_view.can_show_mime_type(mime_type)) {
                        response_decision.download();
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private void on_download_started(Download download) {
        download.decide_destination.connect((suggested_filename) => {
            var file_chooser = new FileChooserDialog(
                "Save File", this, FileChooserAction.SAVE,
                "_Cancel", ResponseType.CANCEL,
                "_Save", ResponseType.ACCEPT
            );
            file_chooser.set_do_overwrite_confirmation(true);

            string name = (suggested_filename != null && suggested_filename != "")
                ? suggested_filename
                : extract_filename_from_uri(download.get_request().uri);
            file_chooser.set_current_name(name);

            if (file_chooser.run() == ResponseType.ACCEPT) {
                try {
                    download.set_destination(Filename.to_uri(file_chooser.get_filename(), null));
                } catch (Error e) {
                    stderr.printf("Error setting download destination: %s\n", e.message);
                }
            }
            file_chooser.destroy();
            return true;
        });

        download.failed.connect((error) => {
            stderr.printf("Download failed: %s\n", error.message);
        });
    }

    private string extract_filename_from_uri(string uri) {
        var last_slash = uri.last_index_of("/");
        if (last_slash >= 0 && last_slash < uri.length - 1) {
            var name = uri.substring(last_slash + 1);
            return Uri.unescape_string(name) ?? name;
        }
        return "download";
    }

    private void clear_cookies() {
        var data_manager = web_view.get_context().get_website_data_manager();
        data_manager.clear.begin(WebsiteDataTypes.COOKIES, 0, null, (obj, res) => {
            try {
                data_manager.clear.end(res);
            } catch (Error e) {
                stderr.printf("Error clearing cookies: %s\n", e.message);
            }
        });
    }

    private bool on_context_menu(ContextMenu context_menu, Gdk.Event event, HitTestResult hit_test) {
        var menu = new Gtk.Menu();

        if (hit_test.context_is_link() && hit_test.link_uri != null) {
            var open_item = new Gtk.MenuItem.with_label("Open Link");
            open_item.activate.connect(() => web_view.load_uri(hit_test.link_uri));
            menu.append(open_item);

            var copy_link = new Gtk.MenuItem.with_label("Copy Link Address");
            copy_link.activate.connect(() => {
                Clipboard.get(Gdk.SELECTION_CLIPBOARD).set_text(hit_test.link_uri, -1);
            });
            menu.append(copy_link);

            var save_link = new Gtk.MenuItem.with_label("Save Link As…");
            save_link.activate.connect(() => {
                web_view.get_context().download_uri(hit_test.link_uri);
            });
            menu.append(save_link);

            menu.append(new SeparatorMenuItem());
        }

        if (hit_test.context_is_image() && hit_test.image_uri != null) {
            var copy_img = new Gtk.MenuItem.with_label("Copy Image Address");
            copy_img.activate.connect(() => {
                Clipboard.get(Gdk.SELECTION_CLIPBOARD).set_text(hit_test.image_uri, -1);
            });
            menu.append(copy_img);

            var save_img = new Gtk.MenuItem.with_label("Save Image As…");
            save_img.activate.connect(() => {
                web_view.get_context().download_uri(hit_test.image_uri);
            });
            menu.append(save_img);

            menu.append(new SeparatorMenuItem());
        }

        var reload_item = new Gtk.MenuItem.with_label("Reload");
        reload_item.activate.connect(() => web_view.reload());
        menu.append(reload_item);

        var copy_url = new Gtk.MenuItem.with_label("Copy Page URL");
        copy_url.activate.connect(() => {
            if (web_view.uri != null)
                Clipboard.get(Gdk.SELECTION_CLIPBOARD).set_text(web_view.uri, -1);
        });
        menu.append(copy_url);

        menu.append(new SeparatorMenuItem());

        var inspect_item = new Gtk.MenuItem.with_label("Inspect Element");
        inspect_item.activate.connect(() => web_view.get_inspector().show());
        menu.append(inspect_item);

        menu.show_all();
        menu.popup_at_pointer(event);

        return true; // suppress default context menu
    }

    public void start(string passed_url) {
        show_all();
        if (passed_url != null && (passed_url.has_prefix("http://") || passed_url.has_prefix("https://"))) {
            web_view.load_uri(passed_url);
        } else {
            web_view.load_uri(HOME_URL);
        }
        scrolled_window.grab_focus();
    }

    public static int main(string[] args) {
        Gtk.init(ref args);

        var browser = new Winks();
        if (args.length > 1) {
            browser.start(args[1]);
        } else {
            browser.start(HOME_URL);
        }

        Gtk.main();
        return 0;
    }
}

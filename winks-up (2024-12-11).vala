using Gtk;
using GLib;
using WebKit;

public class Winks : Window {
    private const bool DEBUG = true;
    private const string TITLE = "winksUp";
    private const string HOME_URL = "http://www.startpage.com/";
    private const string VERSION_STRING = "Winks-Up 0.03";

    private double zoom_level;

    private Entry url_bar;
    private Button back_btn;
    private Button forward_btn;
    private Button home_btn;
    private Button min_btn;
    private Button exit_btn;
    private WebView web_view;
    private ScrolledWindow scrolled_window;

    public Winks() {
        this.title = TITLE;
        set_default_size(640, 480);
        this.set_decorated(false);
        this.maximize();

        try {
            var icon_file = File.new_for_path(Environment.get_home_dir() + "/.config/w-up/w-up.png");
            var config_dir = File.new_for_path(Environment.get_home_dir() + "/.config/w-up");
            if (!config_dir.query_exists()) {
                try {
                    config_dir.make_directory_with_parents(null);
                    var web_icon = File.new_for_uri("https://dl.dropboxusercontent.com/u/6053180/w-up/w-up.png");
                    web_icon.copy(icon_file, FileCopyFlags.NONE);
                } catch (Error e) {
                    stderr.printf("Could not create config dir: %s\n", e.message);
                }
            }
            this.icon = new Gdk.Pixbuf.from_file(icon_file.get_path());
        } catch (Error e) {
            stderr.printf("Could not load application icon: %s\n", e.message);
        }

        create_widgets();
        connect_signals();

        this.zoom_level = 1.0;
        this.url_bar.grab_focus();
    }

    private void create_widgets() {
        var grid = new Grid();

        this.url_bar = new Entry();
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

        grid.attach(back_btn, 0, 1, 1, 1);
        grid.attach(forward_btn, 1, 1, 1, 1);
        grid.attach(home_btn, 2, 1, 1, 1);
        grid.attach(url_bar, 3, 1, 1, 1);
        grid.attach(min_btn, 4, 1, 1, 1);
        grid.attach(exit_btn, 5, 1, 1, 1);

        this.web_view = new WebView();
        this.scrolled_window = new ScrolledWindow(null, null);
        this.scrolled_window.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        this.scrolled_window.add(this.web_view);

        var main_area = new Box(Gtk.Orientation.VERTICAL, 0);
        main_area.pack_start(grid, false, true, 0);
        main_area.pack_end(this.scrolled_window, true, true, 0);
        this.add(main_area);
    }

    private void connect_signals() {
        this.destroy.connect(Gtk.main_quit);
        this.exit_btn.clicked.connect(Gtk.main_quit);
        this.home_btn.clicked.connect(() => { this.web_view.load_uri(HOME_URL); });
        this.min_btn.clicked.connect(this.iconify);
        this.back_btn.clicked.connect(this.web_view.go_back);
        this.forward_btn.clicked.connect(this.web_view.go_forward);
        this.url_bar.activate.connect(on_activate);
        this.web_view.load_changed.connect((source, event) => {
            if (event == WebKit.LoadEvent.FINISHED) {
                this.url_bar.text = this.web_view.get_uri();
            }
        });

        this.web_view.decide_policy.connect((view, decision, decision_type) => {
            if (decision_type == WebKit.PolicyDecisionType.NEW_WINDOW_ACTION) {
                var nav_decision = decision as WebKit.NavigationPolicyDecision;
                if (nav_decision != null) {
                    this.web_view.load_uri(nav_decision.request.uri);
                    decision.ignore();
                    return true;
                }
            }
            return false;
        });
    }

    private void on_activate() {
        var url = this.url_bar.text;
        if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
            url = "http://" + url;
        }
        load_url(url);
    }

    private void load_url(string url) {
        this.web_view.load_uri(url);
    }

    public void start(string passed_url) {
        show_all();
        if (passed_url != null && passed_url.has_prefix("http")) {
            load_url(passed_url);
        } else {
            load_url(HOME_URL);
        }
        this.scrolled_window.grab_focus();
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

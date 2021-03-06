## Common for all subdomains
##
sub vcl_recv {

	#return(pipe);
	
	# Enable smart refreshing
	# Remember your header Cache-Control must be set something else than no-cache
	# Otherwise everything will miss
	if (req.http.Cache-Control ~ "no-cache" && client.ip ~ purge) {
		set req.hash_always_miss = true;
	}
	
	## This section is really unreliable.
	## I don't understand what's happening here
	## Somebody wiser should write a clean and easy to understand article

	# Some generic URL manipulation, useful for all templates that follow
	# First remove the Google Analytics added parameters, useless for our backend
	if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
		set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
		set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
		set req.url = regsub(req.url, "\?&", "?");
		set req.url = regsub(req.url, "\?$", "");
	}

	# Some generic URL manipulation, useful for all templates that follow
	# First remove URL parameters used to track effectiveness of online marketing campaigns
	#if (req.url ~ "(\?|&)(utm_[a-z]+|gclid|cx|ie|cof|siteurl|fbclid)=") {
	#	set req.url = regsuball(req.url, "(utm_[a-z]+|gclid|cx|ie|cof|siteurl|fbclid)=[-_A-z0-9+()%.]+&?", "");
	#	set req.url = regsub(req.url, "[?|&]+$", "");
	#}
	
	## Cookies
	# Cookie notice
	# I'm using this, so it can't be removed?
	# Really, I don't a clue what removing here even means
	#set req.http.Cookie = regsuball(req.http.Cookie, "Cookie_notice_accepted=[^;]+(; )?", "");

	# Remove the "has_js" Cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

	# Remove any Google Analytics based Cookies
	#set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "_gali=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "_gid=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

	# Remove Caos, locally stored GA
	set req.http.Cookie = regsuball(req.http.Cookie, "caosLocalGA=[^;]+(; )?", "");
	set req.http.Cookie = regsuball(req.http.Cookie, "caosLocalGA_gid=[^;]+(; )?", "");

	# Remove the Quant Capital Cookies (added by some plugin, all __qca)
	set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

	# Remove the wp-settings-1 Cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");

	# Remove the wp-settings-time-1 Cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");

	# Remove the wp test Cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_Cookie=[^;]+(; )?", "");

	# Remove the phpBB Cookie. This will help us cache bots and anonymous users.
	#set req.http.Cookie = regsuball(req.http.Cookie, "style_Cookie=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "phpbb3_psyfx_track=[^;]+(; )?", "");

	# Remove the PHPSESSID in members area Cookie
	set req.http.Cookie = regsuball(req.http.Cookie, "PHPSESSID=[^;]+(; )?", "");

	# Remove DoubleClick offensive Cookies
	set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");

	# Remove the AddThis Cookies
	set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");

	# Remove Woocommerce Cookies, all three
	set req.http.Cookie = regsuball(req.http.Cookie, "woocommerce_cart_hash=[^;]+(; )?", "");
	set req.http.Cookie = regsuball(req.http.Cookie, "woocommerce_items_in_cart=[^;]+(; )?", "");
	set req.http.Cookie = regsuball(req.http.Cookie, "wp_woocommerce_session_=[^;]+(; )?", "");

	# Remove PMPro
	#set req.http.Cookie = regsuball(req.http.Cookie, "pmpro_visit=[^;]+(; )?", "");

	# _wp_session
	set req.http.Cookie = regsuball(req.http.Cookie, "_wp_session=[^;]+(; )?", "");
	
	# Moodle, this doesn't work and that's one reason why Moodle doesn't come along with Varnish
	#set req.http.Cookie = regsuball(req.http.Cookie, "MoodleSession=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "MoodleTest=[^;]+(; )?", "");
	#set req.http.Cookie = regsuball(req.http.Cookie, "MOODLEID=[^;]+(; )?", "");

	# Something my Wordpress-setups set up
	
	if (req.http.Cookie ~ "__distillery") {
		unset req.http.Cookie; 
	}
	if (req.http.Cookie ~ "mp_") {
		unset req.http.Cookie;
	}
	
	if (req.http.Cookie ~ "basepress") {
		unset req.http.Cookie;
	}
	
	if (req.http.Cookie ~ "_pk_") {
		unset req.http.Cookie;
	}

	# drop Cookies and params from static assets. Have we done this in virtual hosts? Must check.
	if (req.url ~ "\.(ico|txt|xml|mp3|html|htm)(\?.*|)$") {
		unset req.http.Cookie;
		set req.url = regsub(req.url, "\?.*$", "");
	}

	# Are there Cookies left with only spaces or that are empty?
	if (req.http.Cookie ~ "^ *$") {
		unset req.http.Cookie;
	}
	
	else {
		# If there is any cookies left (a session or NO_CACHE cookie), do not
		# cache the page. Pass it on to Apache directly.
			return (pass);
		}

	# Do not pass other Cookies
        if (!req.http.Cookie) {
                unset req.http.Cookie;
        }

	## Now we do everything per domains which are declared in all-vhost.vcl

}

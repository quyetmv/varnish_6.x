## Wordpress ##
sub vcl_recv {
  if (req.http.host == "katiska.info" || req.http.host == "www.katiska.info") {
		set req.backend_hint = default;

	## just for this virtual host
	# for stop caching uncomment
	#return(pass);
	# for dumb TCL-proxy uncomment
	#return(pipe);
	
	## just an example. For me Nginx is doing this.
	## If you are using SSL and it doesn't forward http to https when URL is given without protocol
	#if ( req.http.X-Forwarded-Proto !~ "(?i)https" ) {
	#	set req.http.X-Redir-Url = "https://" + req.http.host + req.url;
	#	return ( synth( 750 ));
	#}
	#set req.http.X-Forwarded-Proto = "https";
	
	# I don't need this because I'm using Fail2ban, but this can be used more like a safetynet
#	if(vsthrottle.is_denied(req.http.X-Forwarded-For, 2, 1s) && (req.url ~ "xmlrpc|wp-login.php|\?s\=")) {
#		return (synth(413, "Too Damn Much"));
#	}

	# Prevent users from making excessive POST requests that aren't for admin-ajax
	if(vsthrottle.is_denied(req.http.X-Forwarded-For, 15, 10s) && ((!req.url ~ "\/wp-admin\/|(xmlrpc|admin-ajax)\.php") && (req.method == "POST"))){
		return (synth(413, "Too Damn Much"));
	}
	
	# Normalize hostname to avoid double caching
	set req.http.host = regsub(req.http.host,
	"^katiska\.info$", "www.katiska.info");

	# drops amp; IDK if really needed, but there is no point even try because Google is caching AMP-pages
	if (req.url ~ "/amp/") {
		return (pass);
	}
	
	# drops stage site totally
#	if (req.url ~ "/stage") {
#		return (pipe);
#	}

	# drops Mailster
	if (req.url ~ "/postilista/") {
		return (pass);
	}

	# Needed for Monit
	if (req.url ~ "/pong") {
		return (pipe);
	}
	
	# AWStats
#	if (req.url ~ "cgi-bin/awsstats.pl") {
#		return (pass);
#	}

	# Allow purging from ACL
	if (req.method == "PURGE") {
		if (!client.ip ~ purge) {
			return(synth(405, "This IP is not allowed to send PURGE requests."));
		}
	# If allowed, do a cache_lookup -> vlc_hit() or vlc_miss()
		return(purge);
	}

	# Only deal with "normal" types
	if (req.method != "GET" &&
	req.method != "HEAD" &&
	req.method != "PUT" &&
	req.method != "POST" &&
	req.method != "TRACE" &&
	req.method != "OPTIONS" &&
	req.method != "PATCH" &&
	req.method != "DELETE") {
	# Non-RFC2616 or CONNECT which is weird. */
	# Why send the packet upstream, while the visitor is using a non-valid HTTP method? */
		return(synth(405, "Non-valid HTTP method!"));
	}

	# Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
	if (req.http.Upgrade ~ "(?i)websocket") {
		return(pipe);
	}

	## Do not Cache: special cases ##

	# Do not cache AJAX requests.
	if (req.http.X-Requested-With == "XMLHttpRequest") {
		return(pass);
	}

	# Post requests will not be cached
	if (req.http.Authorization || req.method == "POST") {
		return(pass);
	}
	
	# Pass Let's Encrypt
	if (req.url ~ "^/\.well-known/acme-challenge/") {
		return (pass);
	}
	
	## Wordpress ##

	# Don't cache post and edit pages
	if (req.url ~ "/wp-(post.php|edit.php)") {
		return(pass);
	}

	# Don't cache logged-in user
	if ( req.http.Cookie ~ "wordpress_logged_in|resetpass" ) {
		return(pass);
	}
	
	# Pass contact form, RSS feed and must use plugins of Wordpress
	if (req.url ~ "/(tiedustelut|feed|mu-)") {
		return(pass);
	}

	#Hit everything else
	if (!req.url ~ "/wp-(login|admin|cron)|logout|administrator|resetpass") {
		unset req.http.Cookie;
		return(hash);
	}
	
	## Everything else ##
	
	# Cache all others requests if they reach this point
	return(hash);

  }
}

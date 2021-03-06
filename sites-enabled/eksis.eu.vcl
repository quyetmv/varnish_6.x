## Wordpress ##
sub vcl_recv {
  if (req.http.host == "eksis.eu" || req.http.host == "www.eksis.eu") {
		set req.backend_hint = default;

	## just for this virtual host
	# for stop caching uncomment
	#return(pass);
	# for dumb TCL-proxy uncomment
	#return(pipe);
	
	## just an example. For me Nginx is doing this.
	# If you are using SSL and it doesn't forward http to https when URL is given without protocol
	#if ( req.http.X-Forwarded-Proto !~ "(?i)https" ) {
	#	set req.http.X-Redir-Url = "https://" + req.http.host + req.url;
	#return ( synth( 750 ));
	#}
	#set req.http.X-Forwarded-Proto = "https";
	
	# Normalize hostname to avoid double caching
	set req.http.host = regsub(req.http.host,
	"^eksis\.eu$", "www.eksis.eu");

	# drops amp; IDK if really needed, but there is no point even try because Google is caching AMP-pages
	if (req.url ~ "/amp/") {
		return (pass);
	}
	
	# drops stage site totally
	if (req.url ~ "/stage") {
		return (pipe);
	}

	# drops Mailster
	if (req.url ~ "/postilista/") {
		return (pass);
	}

	# Needed for Monit
	if (req.url ~ "/pong") {
		return (pipe);
	}

	# Allow purging from ACL
	if (req.method == "PURGE") {
	if (!client.ip ~ purge) {
		 return(synth(405, "This IP is not allowed to send PURGE requests."));
	}
	# If allowed, do a cache_lookup -> vlc_hit() or vlc_miss()
	return (purge);
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
	return (synth(404, "Non-valid HTTP method!"));
	}

	# Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
	if (req.http.Upgrade ~ "(?i)websocket") {
	return (pipe);
	}

	### Do not Cache: special cases ###

	# Do not cache AJAX requests.
	if (req.http.X-Requested-With == "XMLHttpRequest") {
	return(pass);
	}

	# Post requests will not be cached
	if (req.http.Authorization || req.method == "POST") {
	return (pass);
	}
	
	# Pass Let's Encrypt
	if (req.url ~ "^/\.well-known/acme-challenge/") {
	return (pass);
	}

	## Wordpress etc ##

	# Don't cache post and edit pages
	if (req.url ~ "/wp-(post.php|edit.php)") {
	return(pass);
	}

	# Don't cache logged-in user
	if ( req.http.Cookie ~ "wordpress_logged_in|resetpass" ) {
	return( pass );
	}
	
	# Page of contact form
	if (req.url ~ "/(tiedustelut)") {
	return (pass);
	}

	# Did not cache the RSS feed
	if (req.url ~ "/feed") {
	return (pass);
	}

	# Must Use plugins I reckon
	if (req.url ~ "/mu-.*") {
	return (pass);
	}

	#Hit everything else
	if (!req.url ~ "/wp-(login|admin|cron)|logout|administrator|resetpass") {
	unset req.http.Cookie;
	}
	
	## General filtering

	# Large static files are delivered directly to the end-user without
	# waiting for Varnish to fully read the file first.
	# Varnish 4 fully supports Streaming, so see do_stream in vcl_backend_response() to witness the glory.
	if (req.url ~ "^[^?]*\.(mp[34]|wav)(\?.*)?$") {
	unset req.http.Cookie;
	return (hash);
	}

	# Cache all static files by Removing all Cookies for static files
	# Remember, do you really need to cache static files that don't cause load? Only if you have memory left.
	# Here I decide to cache these static files. For me, most of them are handled by the CDN anyway.
	if (req.url ~ "^[^?]*\.(ico|txt|xml|mp3|html|htm)(\?.*)?$") {
		unset req.http.Cookie;
		return (hash);
	}
	
	# Do not cache HTTP authentication and HTTP Cookie
	if (req.http.Authorization || req.http.Cookie) {
		return (pass);
	}
	
	# Cache all others requests if they reach this point
	return (hash);

  }
}


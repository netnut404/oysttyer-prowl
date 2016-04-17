##
##	ttytter-prowl.pl
##
##	Forward Twitter friends posts to Prowl via ttytter
##
##	Scott Schulz @ http://ScottSchulz.us
##
##	Based on sample code provided by:
##		Cameron Kaiser @ http://www.floodgap.com/software/ttytter/
##		Zachary West (prowl.pl) @ http://prowl.weks.net/static/prowl.pl
##			Copyright (c) 2009, Zachary West
##			All rights reserved.

#  Configuration
$Lib_appname = "GnuSocial";
$Lib_event = "NewPost";
$Lib_priority = 0;

$Lib_master = "$ENV{'HOME'}/twt.bookmark";
if(open(S, $Lib_master)) {
	$last_id = 0+scalar(<S>);
	print $stdout "LIB: init last id: $last_id\n";
	close(S);
}

$Lib_apikey = '';
if (open(APIKEYFILE, $ENV{'HOME'} . "/.prowlkey")) {
	$Lib_apikey = <APIKEYFILE>;
	chomp $Lib_apikey;
	close(APIKEYFILE); 
} else {
	print $stdout "Unable to open prowl key file\n";
}

use LWP::UserAgent;

$handle = sub {
	my $ref = shift;

	#  If you are using this client to follow others and forward
	#  items to your iPhone, then you probably want to disable this
#	return 0 if ($ref->{'user'}->{'protected'} eq 'true');

	my $string = &descape($ref->{'user'}->{'screen_name'}) .
	" says: " .
	&descape($ref->{'text'}) . "\n";

	# URL encode our arguments
	$Lib_appname =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$Lib_event =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$string =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

	# Generate our HTTP request.
	my ($userAgent, $request, $response, $requestURL);
	$userAgent = LWP::UserAgent->new;
	$userAgent->agent("ssFollowbot/1.0");

	$requestURL = sprintf("https://prowlapp.com/publicapi/add?apikey=%s&application=%s&event=%s&description=%s&priority=%d",
					$Lib_apikey,
					$Lib_appname,
					$Lib_event,
					$string,
					$Lib_priority);

	$request = HTTP::Request->new(GET => $requestURL);

	$response = $userAgent->request($request);

	if ($response->is_success) {
		print $stdout "Notification successfully posted.\n";
	} elsif ($response->code == 401) {
		print $stdout "Notification not posted: incorrect API key.\n";
	} else {
		print $stdout "Notification not posted: " . $response->content . "\n";
	}
	
	&defaulthandle($ref);
	return 1;
};

$conclude = sub {
	print $stdout "LIB: writing out: $last_id\n";
	if(open(S, ">$Lib_master")) {
		print S $last_id;
		close(S);
	} else {
		print $stdout "LIB: failure to write: $!\n";
	}
	&defaultconclude;
};

package FCGI::Spawn;

use vars qw($VERSION);
BEGIN {
  $VERSION = '0.15'; 
  $FCGI::Spawn::Default = 'FCGI::Spawn';
}

=head1 NAME

 FCGI::Spawn - process manager/application server for FastCGI protocol.

=head1 SYNOPSIS

Minimum unrecommended way to illustrate it working:

	use FCGI::Spawn;
	my $spawn = FCGI::Spawn->new();
	$spawn -> spawn;

Never put this in production use. This should be run as the web server's user id ( or another if umask isn't 022 ) and the web server should be configured to request its FastCGI on the default socket file name, the /tmp/spawner.sock. Consider to run as user other than web server's and setting up the proper sock_chmod/sock_chown parameters necessity. In the case if you request via TCP care should be taken on network security like DMZ/VPN/firewalls setup instead of sock_* parameters.

Tried to get know satisfaction with bugzilla... There's no place to dig out that Bugzilla doesn't work out with FastCGI other than Bugzilla's own Bugzilla though.

Tried the same with WebGUI.org. The versions since 6.9 went to require the mod_perl2 strictly. OK, but version 6.8 does work well at least as does at http://alpha.vereshagin.org.
This is my ./run for daemontools by http://cr.yp.to:

	#!/usr/bin/perl -w
	use strict;
	use warnings;
	
	use lib '/path/to/modules';
	
	use WebGUI;
	use Image::Magick;
	
	use Carp; $SIG{__DIE__} = sub{ print @_; print Carp::longmess };
	
	$ENV{FCGI_SOCKET_PATH} = "/path/to/spawner.sock";
	eval( "use FCGI::Spawn;" );
	
	my $fcgi = new CGI; eval ${ FCGI::Spawn::plsrc( '/the/path/to/some.pl.fpl' ) }; undef $fcgi;
	
	my $spawn = FCGI::Spawn->new({ n_processes => 7, sock_chown => [qw/-1 10034/],
						sock_chmod => 0660, max_requests => 200,
	        });
	$spawn -> spawn;

And, the minimum suggested way to spawn your FastCGI Perl scripts is as follows:

	#!/usr/bin/perl -w
	$ENV{FCGI_SOCKET_PATH} = "/path/to/spawner.sock";
	eval( "use FCGI::Spawn;" );
	my $spawn = FCGI::Spawn->new({ n_processes => 7
	        });
	$spawn -> spawn;

Here is the one more easy way to posess the daemontools facilities:

	$ cat ./env/FCGI_SOCKET_PATH
	/tmp/spawner.sock
	$ cat ./run
	#!/bin/sh
	exec 2>&1
	exec envdir ./env su fcgi -c '
	  ./fcgi-run 
	'
	$ cat ./fcgi-run
	#!/usr/bin/perl -w
	use FCGI::Spawn;
	my $spawn = FCGI::Spawn->new();
	$spawn -> spawn;

A few more notes:

** You MUST use eval() for inclusion. I assume you need your own socket file name AND it must be tweakeable from inside of Perl. This is because of setting up the socket communication in the CGI::Fast, which is the part of Perl core distribution, right in the BEGIN block, e. g. right before the compilation. But the one should restrictively point the socket file location right before the BEGIN block of the CGI::Fast. Well, without CGI::Fast there shouldn't be workable POST queries contents parsing, as it was up to FCGI::Spawn version 0.12.

** You should beware about CGI::Fast IS NOT included at the moment this module is being used, e. g. IS ABSENT in the %INC global hash. Because of that same reason.

** CGI scripts must be tweaked to use $FCGI::Spawn::fcgi instead of new CGI or CGI->new. In other case they will not be able to process HTTP POST. Hope your code obfuscators are not that complex to allow such a tweak. ;-) At least it is obvious for FastCGI scripts to require FastCGI object if you use your application in any FastCGI environmanet.

Thanks for understanding.

=head2 Why daemontools?

They have internal log-processing and automatical daemon restart on fault. Sure they posess control like stop/restart. Check em out and see. But those are not strictly necessary.
Another reason is that i'm not experienced much with Perl daemons building like getting rid of STD* file handles and SIG* handling.

=head2 Why not mod_perl/mod_perl2/mod_fcgid?

=over

=item * Memory consumption

With FCGI::Spawn every fork weghts less in your "top". Thus it is less hard to see the system load while forks' memory being swapped out and losing its copy-on-write kernel facility. Every fork stops sharing its memory in this case.

=item * Memory sharing

With mod_fcgid, the compiled Perl code is not being shared among forks by far.

=item * Too much need for root

The startup.pl providing the memory sharing among forks is aimed to be run as root, at least when you need to listen binded to ports numbered less than 1024, for example, 80. And, the root user ( the human ) is often too busy to check if that massive code is secure enough to be run as root system user ( the effective UID ) Thus, it's no much deal to accelerate Perl on mod_perl steroids if the startup.pl includes rather small code for reuse.

Root is needed to recompile the Perl sources, at least with the useful Registry handler. It is obvious to gracefully restart Apache once per N minutes and this is what several hosting panel use to do but it is not convinient to debug code that is migrated from developer's hosting to production's  as it is needed to be recompiled on webmaster's demand that use to happen to be no sense for server's admin. And, with no ( often proprietary ) hosting panel software onboard, Apache doesn't even gracefully restart on a regular basis without special admin care taken at server setup time. On the uptime had gone till the need of restart after launch it is not an admin favor to do this, even gracefully. Apache::Reload can save from this but it's not a production feature, too.

=item * File serving speed loss

Apache itself is well known to serve the static files too slowly. Despite the promises of "we do this too" on sendfile and kqueue features.

=item * More stuff on your board

The unclear differences between the bundled PerlHandler-s environments among with the more compiled code amount populate your %INC from Apache:: and ModPerl:: namespaces.

=back

=head2 Why still mod_perl?

=over

=item * the Habit

.

=item * Apache::DBI

Persistent connections feature makes it slightly faster for skip connect to DB stage on every request.

=item * Apache::Request

HTTP input promises to be much more effective than the CGI.pm's one, used in CGI::Fast, too. You may need also more information about request, like full incoming headers, too. Those are obvious to be contained in the Apache internal structures rather than outsourced with application protocol from web server.

=back

=head2 Why not simply FCGI::ProcManager?

It seems to require too much in Perl knowledge from regular system administrator ( same as for startup.pl audit goes here ), in comparison to php's fastcgi mode. Even with that, it is not as mock as FCGI::Spawn for software developer. You will need to be me if you will need its features, if you are a sysadmin, while I'm the both. 

=head1 DESCRIPTION

The overall idea is to make Perl server-side scripts as convinient for novice and server administrators as PHP in FastCGI mode.

FCGI::Spawn is used to serve as a FastCGI process manager. Besides  the features the FCGI::ProcManager posess itself, the FCGI::Spawn is targeted as web server admin understandable instance for building the own fastcgi server with copy-on-write memory sharing among forks and with single input parameters like processes number and maximum requests per fork.

Another thing to mention is that it is able to execute any file pointed by Web server ( FastCGI requester ). So we have the daemon that is hot ready for hosting providing :-)

The definitive care is taken in FCGI::Spawn on security. Besides the inode settings on local UNIX socket taken as input parameter, it is aware to avoid hosting users from changing the max_requests parameter meant correspondent to MaxRequests Apache's forked MPM parameter, and the respective current requests counter value as well.

The aforementioned max_requests parameter takes also care about the performance to avoid forks' memory leaks to consume all the RAM accounted on your hardware.

For shared hosting it is assumed that system administrator controls the process manager daemon script contents with those user hardware consumption limits and executes it with a user's credentials. E. g., the user should be able to send signal to the daemon to initiate graceful restart on his/her demand ( this is yet to be done ) or change the settings those administrator can specifically allow in the daemon starter script without restart ( both of those features are about to be done in the future ). For example, user may want to recompile the own sources and quickly change the clean_inc_hash for this.

The call stack lets you set up your own code reference for your scripts execution.  

Seeking for convention between high preformance needs that the perl compile cache possesses and the convinience of debugging with recompilation on every request that php provides, the clean_inc_subnamespace	feature allows you not to recompile the tested source like those of DBI and frameworks but focus the development on your application development only, limiting the recompilation with your application(s) namespace(s) only. This may be useful in both development environment to make the recompilation yet faster and on a production host to make the details of code adaptaion to hosting clear in a much less time needed. This is new feature in v. 0.14

Every other thing is explained in FCGI::ProcManager docs.

=head1 PREREQUISITES

Be sure to have FCGI::ProcManager.

=head1 METHODS

class or instance

=head2 new({hash parameters})

Constructs a new process manager.  Takes an option hash of the sock_name and sock_chown initial parameter values, and passes the entire hash rest to ProcManager's constructor.
The parameters are:

=over

=item * $ENV{FCGI_SOCKET_PATH} 

should be set before module compilation, to know where the socket resides. Can be in the host::port or even :port notation for TCP, as FCGI's remote.fpl states. Default: /tmp/spawner.sock.

You can set environment value with your shell like this:

FCGI_SOCKET_PATH=/var/lib/fcgi.sock ./fcgi.pl

or you can enclose it into the eval() like that:

$ENV{FCGI_SOCKET_PATH}  = '/var/lib/fcgi.sock';
eval( "use FCGI::Spawn;" ); die $@ if $@;

=item * sock_chown 

is the array reference which sets the parameters for chown() builtin on newly created socket, when needed. Default: none.

=item * readchunk 

is the buffer size for user's source reading in plsrc function. Default: 4096.

=item * maxlength 

is the maximumum user's file size for the same. Default: 100000.

=item * max_requests 

is the maximum requests number served by every separate fork. Default: 20.

=item * stats 

Whether to do or do not the stat() on every file on the %INC to recompile on change by mean of removal from %INC. Default: 1.

=item * stats_policy 

Array reference that defines what kind of changes on the every module file stat()'s change to track and in what order. Default: FCGI::Spawn::statnames_to_policy( 'mtime' ) ( statnames_to_policy function is described below ).

=item * clean_inc_hash 

when set to 1 points to clean out the requested via FastCGI file from %INC after every procesed request.

when set to 2 points to clean out  after every procesed request the every %INC change that the FastCGI requested file did.

Default: 0.

=item * clean_main_space

when set to true points to clean out the %main:: changes ( unset the global variables ) at the same time. Default: 0.

=item * clean_inc_subnamespace

Points which namespace, and beneath, should be cleaned in the moment between callouts ( e. g., Bugzilla, WebGUI, MyApp::MyClass etc., depending upon what is your applications name ).

when is a scalar, makes the %INC to clean if the begin of the key equals to it.

when is array reference, treats every element as a scalar and does the same for every item, just the same if it was the scalar itself

You can use :: namespace separator, as well as / as it is in the %INC, both MyApp::MyNS and MyApp/MyNS are pretty valid. You can use full file names, like this: 'path/required_lib.pl' for this argument, too.

As of high-load systems it is strongly discouraged that the hosting user ( who can happen to be a really bad programmer ) to control this parameter, as it can lead to the same as clean_inc_hash=2 and can steal server performance at the moment just unwanted for system administrator. ulimit is a good thing to keep from such a bothering too, but it's just not always sufficient alone.

Default: empty.

=item * callout 

is the code reference to include the user's file by your own. Its input parameters are the script name with full path and the FastCGI object, the CGI::Fast instance. This is the default ( the plsrc() returns the file's contents, and eval() executes them ):

	{
		my( $sn, $fcgi ) = @_;
		my $plsrc=plsrc $sn;
		eval $$plsrc;
	}

using this as an example, one can provide his/her own inclusion stuff. Default is to use trivial do() builtin this way:

  sub{  
    do shift;
  }

=back

Every other parameter is passed "as is" to the FCGI::ProcManager's constructor. Except for addition about the  n_processes, which defaults to 5.

=head2 spawn

Fork a new process handling request like that being processed by web server.

=head2 callout

performs user's code execution. Isolates the max_requests and current requests counter values from changing in the user's source.

=head2 plsrc

Static function. Reads the supplied parameter up to "maxlength" bytes size chunked by "readchunk" bufer size and returns string reference. Deprecated and will be removed in future versions.

=head2 statnames_to_policy( 'mtime', 'ctime', ... );

Static function. Convert the list of file inode attributes' names checked by stat() builtin to the list of numbers for it described in the perldoc -f stat .  In the case if the special word 'all' if met on the list, all the attributes are checked besides 'atime' (8). Also, you can define the order in which the stats are checked to reload perl modules: if the change is met, no further checks of this list for particular module on particular request are made as a decision to recompile that source is already taken. This is the convionient way to define the modules reload policy, the 'stat_policy' object property, among with the need in modules' reload itself by the 'stats' property checked as boolean only.

=head1 Thanks, Bugs, TODOs, Pros and Contras ( The Etcetera )

=head2 The Inclusion

I had many debates and considerations about inclusion the end user scripts. Here's my own conclusions:

=over

=item the default is to: do()

should be the best but not verbose enough and very definitive about exceptions. But the major in this is that it isolates $fcgi request lexical variable, so it is made global of this package.

=item require()

makes the every fork failed to incorporate the user's source to die() which is painful under heavy load.

=item system() or exec()

makes your FastCGI server to act as the simple CGI, except POST input is unavailable. Useful for debugging.

=item  Mentioned plsrc() and eval() sub

reads user's source sized up to "maxlength" by buffers chunks of "readchunk" initial parameters. And, eval()'s it. Deprecated and will be removed in future versions. One can write it by self defining the:

=item your own CODE ref

is able to be set by the "callout" initial parameter and/or "callout" object property.

=back

=head2 The Bugs

Fresh bugs, fixes and features are to be available on git://github.com/petr999/fcgi-spawn.git .

=head2 Tested Environments

Nginx everywhere.
Troubles met on passing %ENV variables responsible for CGI input, most of them concern POST requests: the HTTP_ prefix for *CONTENT_* and undescendence of configuration context with fastcgi_param-s.

=over

=item * FreeBSD and local UNIX sockets

.

=item * Win32 and TCP sockets

No surprise, Cygwin rocks. No ActiveState Perl can do this, sorry --- as it can't FCGI::ProcManager which is a must. And, surprise, the response time difference over CGI is dramatically better because of it's way more expensive on resources to launch a new process on this platform ( Cygwin emulates fork()s with native threads those are much faster ).

=back

=head2 The TODOs

=over

=item * %SIG

The UNIX signals processing is on its way in consequent releases. At least we should process the USR1 or so to recompile the all of the sources onboard, another signals to recompile only the part of them. This should provide the graceful restart feature.

=item * CGI

it's way hard to adopt to CGI::Fast's BEGIN block. Gonna skip it out with CGI::Minimal. Should be even cooler to replace CGI.pm with XS alternate.

=item * DBI

Should be nice to overload DBI like the Apache::DBI does.

=item * Adoptable forks number

Should be nice to variate the n_processes due to the average system load, rest of the free RAM, etc.

=item * RC (init) script 

FCGI::ProcManager is able to put its pid file where you should need it. RC and/or SMF startup scripts  and packages for the particular OS are the "Right Thing" (tm). :-)

=item * Frameworks compliance

Bring FCGI::ProcManager improvements like max_requests into complex applications with their own daemons like Catalyst.

=item * Lightweight cache for objects that CGI scripts may use.

Cache things those are not necessary to be reloaded on every request even if it is to be done with CGI. Those should be objects like XSLT processors created from the permanenmtly stored XSL stylesheet file so the program can remain CGI-compliant as such a cache is not mandatory but can be enhanced with this feature to get more performance under FCGI::Spawn with no need in additional daemons like Memcached and requirement for them to be able to keep native objects ( which the XML/XSL document and XSLT processor are).

=item * CGI.pm alterbative to get rid of CGI programs patching

it's not always allowed to change the CGI program source so care should be taken of different CGI.pm that takes $FCGI::Spawn::fcgi when it's necessary.

=item * Namespace cleaning

Service should take care of cleaning the variables from namespaces other than %main:: . This is the only thing that is left to do to get Bugzilla with FastCGI that is officially not possible.

=item * Test with other HTTP servers ( FastCGI requesters )

Any aside help would be appreciated.

=item * Hosting panels integration

Free software forking/branching is an obvious stuff, hosting panels are not exclusion, at least those of them which are free software. I'm absolutely sure CGI speedup is wanted by clients as well as unloading the hosting server's CPUs from Perl compilation/exec on every request for servers' administrators.

=item * Debugging

On a developer's machine it is nothing impossible to make debugging the same standard way as perldoc perldebug states, especially with n_processes => 0. It's not yet in because the CGI::Fast redefines STD* handles upon every request. It makes things easy but should be more tweakable.

=item * Compile the modules cache on the first request

Should be obvious for developer's host to keep from compiling each and every module on startup if it is known that developer will take on different tasks through all of the uptime. But during the uptime ( work hours ) YMMV about the need in FCGI::Spawn-served application(s) and they can appear to be used.  So the idea is to evaluate some modules inclusion upon the first request, perform it without fork(), and share the compile cache later among forks. This will save some memory on a developer's machine with no need to change daemon settings and start it again.

=back

=head2 Thanks

SkyRiver Studios for original fund of Perl(bugzilla) deployment on high loaded system.

Yuri@Reunion and MoCap.Ru for use cases, study review and suggestions on improvement.

=head1 AUTHOR, LICENSE

Peter Vereshagin <peter@vereshagin.org>, http://vereshagin.org .

License: same as FCGI::ProcManager's one.

=cut


use strict;
use warnings;

use File::Basename;
use FCGI::ProcManager;
use base qw/Exporter/;

our @EXPORT_OK = qw/statnames_to_policy/;

our $fcgi;

BEGIN {
	die "CGI::Fast made its own BEGIN already!" if defined $INC{'CGI/Fast.pm'};
	$ENV{FCGI_SOCKET_PATH} = '/tmp/spawner.sock' if not exists $ENV{FCGI_SOCKET_PATH};
	if( -e $ENV{FCGI_SOCKET_PATH} ){
		(
			[ -S $ENV{FCGI_SOCKET_PATH} ]
			&&
			unlink $ENV{FCGI_SOCKET_PATH}
		)	or die "Exists ".$ENV{FCGI_SOCKET_PATH}.": not a socket or unremoveable";
	}
	eval( "use CGI::Fast;" );
}

my $readchunk=4096;
my $maxlength=100000;

sub plsrc {
	my $sn = shift;
	unless( open PLSRC, $sn ){ exit $!; exit; }
	my $plsrc="";
	while( my $rv = read( PLSRC, my $buf, $readchunk ) ){
		unless( defined $rv ){ exit $!; exit; }
		$plsrc .= $buf; exit if length( $plsrc ) > $maxlength;  
	} close PLSRC;
	return \$plsrc;
}

my $defaults = { 
	n_processes => 5,
	max_requests =>	20,
	clean_inc_hash	=> 	0,
	clean_main_space	=> 0,
	clean_inc_subnamespace	=> [],
	callout	=>	sub{
		do shift;
		#	my( $sn, $fcgi ) = @_;
		#	my $plsrc=plsrc $sn;
		#	eval $$plsrc;
	},
	stats	=> 1,
	stats_policy	=> statnames_to_policy( 'mtime' ),
	state	=> {},
};

sub statnames_to_policy {
	my %policies = qw/dev 0 ino 1 mode 2 nlink 3 uid 4 gid 5 rdev 6 size 7 atime 8 mtime 9 ctime 10 blksize 11 blocks 12/;
	#	grep(  { $_ eq 'all' } @_ )
	#	?	[ 1..7, 9..12 ]
	#	: 
	[ map( { $policies{ $_ } } @_ ) ];
}

sub new {
	my $class = shift;
	my( $new_properties, $properties );
	if( $properties = shift ){
		$properties = { %$defaults, %$properties };
	} else {
		$properties = $defaults;
	}
	my $proc_manager = FCGI::ProcManager->new( $properties );
	my $sock_name = $ENV{FCGI_SOCKET_PATH};
	if( defined $properties->{sock_chown} ){
		chown( @{ $properties->{sock_chown} }, $sock_name )
		or die $!;
	}
	if( defined $properties->{sock_chmod} ){
		chmod( $properties->{sock_chmod}, $sock_name )
		or die $!;
	}
	defined $properties->{readchunk} and $readchunk = $properties->{readchunk};
	defined $properties->{maxlength} and $maxlength = $properties->{maxlength};

	$class->make_clean_inc_subnamespace( $properties );

	$proc_manager->pm_manage();
	$properties->{proc_manager} = $proc_manager;
	bless $properties, $class;
}

sub make_clean_inc_subnamespace {
	my( $this, $properties ) = @_;
	my $cisns = $properties->{ clean_inc_subnamespace };
	if( '' eq ref $cisns ){
		$cisns = [ $cisns ];
	}
	foreach( @$cisns ) {
		$_ =~ s!::!/!g
			if '' eq ref $_
	}
	$properties->{ clean_inc_subnamespace } = $cisns;
}

sub callout {
	my $self = shift;
	&{$self->{callout}}( @_ );
}

sub clean_inc_particular {
	my $this= shift;
	map { 
		my $subnamespace_to_clean = $_;
		map { delete $INC{ $_ } } 
			grep {  $subnamespace_to_clean eq substr $_, 0, length $subnamespace_to_clean  }
				keys %INC 
	} @{ $this->{ clean_inc_subnamespace	} };
}

sub spawn {
	my $this = shift;
	my( $proc_manager, $max_requests, ) = map { $this -> {$_} } qw/proc_manager max_requests/;
	$this->set_state( 'fcgi_spawn_main', { %main:: } ) if $this->{clean_main_space}; # remember global vars set for cleaning in loop
	$this->set_state( 'fcgi_spawn_inc', { %INC } ) if $this->{clean_inc_hash} == 2; # remember %INC to wipe out changes in loop
	$this->set_state_stats if $this->{stats}; # remember %INC to wipe out changes in loop
	my $req_count=0;
	while( $fcgi = new CGI::Fast ) {
 		$proc_manager->pm_pre_dispatch();
		my $sn = $ENV{SCRIPT_FILENAME};
		my $dn = dirname $sn;
		my $bn = basename $sn;
		chdir $dn;
		if( $req_count ){

			$this->prespawn_dispatch( $fcgi, $sn );

		}
		# Commented code is real sugar for nerds ;)
		# map { $ENV{ $_ } = $ENV{ "HTTP_$_" } } qw/CONTENT_LENGTH CONTENT_TYPE/
  	#  if $ENV{ 'REQUEST_METHOD' } eq 'POST';	# for nginx-0.5
		# do $sn ; #or print $!.$bn; # should die on unexistent source file
		#	my $plsrc=plsrc $sn;	# should explanatory not
		#	eval $$plsrc;
		$this->callout( $sn, $fcgi );
		$req_count ++;
		exit if $req_count > $max_requests;
		$this->postspawn_dispatch;
 		$proc_manager->pm_post_dispatch();
	}
}
sub get_inc_stats{
	my %inc_state = map { my $stat = [ stat $_ ]; 
	#	undef $stat->[8];  
		$_ => $stat;  
	} values %INC;
	return \%inc_state;
}
sub set_state_stats {
	my $this = shift;
	my $stats = get_inc_stats;
	$this->set_state( 'stats', $stats );
}
sub delete_inc_by_value{
	my $module = shift;
	my @keys_arr = keys %INC;
	foreach my $key ( @keys_arr ){
		my $value = $INC{ $key };
		delete $INC{ $key } if $value eq $module;
	}
}
sub postspawn_dispatch {
	my $this = shift;
	$this->set_state_stats;
}
sub prespawn_dispatch {
	my ( $this, $fcgi, $sn ) = @_;
	$fcgi->initialize_globals; # to get rid of CGI::save_request consequences
	delete $INC{ $sn } if exists( $INC{ $sn } ) and $this->{clean_inc_hash} == 1 ; #make %INC to forget about the script included
	#map { delete $INC{ $_ } if not exists $fcgi_spawn_inc{ $_ } } keys %INC 
	if( $this->{clean_inc_hash} == 2 ){ #if %INC change is unwanted at all
		my $fcgi_spawn_inc = $this->get_state( 'fcgi_spawn_inc' );
		%INC = %$fcgi_spawn_inc ;
	}
	$this->clean_inc_particular;
	$this->clean_inc_modified if $this->{ stats };
	if( $this->{clean_main_space} ){ # actual cleaning vars
		foreach ( keys %main:: ){ 
			delete $main::{ $_ } unless $this->defined_state( 'fcgi_spawn_main', $_ ) ;
		}
	}
}
sub clean_inc_modified {
	my $this = shift;
	my $old_stats = $this->get_state( 'stats' );
	my $new_stats = get_inc_stats;
	my $policy = $this->{ stats_policy };
	foreach my $module ( keys %$new_stats ){
		my $modified = 0;
		if( defined $old_stats->{ $module } ){
			my $new_stat = $new_stats->{ $module };
			my $old_stat = $old_stats->{ $module };
			foreach my $i ( @$policy ){
				my $new_element = $new_stat->[ $i ];
				my $old_element = $old_stat->[ $i ];
				$modified = 1 if $new_element != $old_element;
				last if $modified;
			} 
		}
		delete_inc_by_value( $module ) if $modified;
	}
}
sub defined_state{
	my( $this, $key ) = @_;
	defined $this->{ state }->{ $key };
}
sub get_state {
	my( $this, $key ) = @_;
	$this->{ state }->{ $key };
}
sub set_state {
	my( $this, $key, $val ) = @_;
	$this->{ state }->{ $key } = $val;
}

1;

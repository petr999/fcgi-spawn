package FCGI::Spawn;

use vars qw($VERSION);
BEGIN {
  $VERSION = '0.14'; 
  $FCGI::Spawn::Default = 'FCGI::Spawn';
}

=head1 NAME

 FCGI::Spawn - process manager/application server for FastCGI protocol.

=head1 SYNOPSIS

Minimum unrecommended way to illustrate it working:

	use FCGI::Spawn;
	my $spawn = FCGI::Spawn->new();
	$spawn -> spawn;

Never put this in production use. This should be run as the web server's user id ( or another if umask isn't 022 ) and the web server should be configured to request its FastCGI on the default socket file name, the /tmp/spawner.sock. Consider to run as user other than web server's and setting up the proper sock_chmod/sock_chown parameters necessity.

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

Root needed to recompile the Perl sources, at least with the useful Registry handler.

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

HTTP input promises to be much more effective than the CGI.pm's one, used in CGI::Fast, too.

=back

=head2 Why not simply FCGI::ProcManager?

It seems to require too much in Perl knowledge from regular system administrator ( same as for startup.pl audit goes here ), in comparison to php's fastcgi mode. Even with that, it is not as mock as FCGI::Spawn for software developer. You will need to be me if you will need its features, if you are a sysadmin, while I'm the both. 

=head1 DESCRIPTION

FCGI::Spawn is used to serve as a FastCGI process manager. Besides  the features the FCGI::ProcManager posess itself, the FCGI::Spawn is targeted as web server admin understandable instance for building the own fastcgi server with copy-on-write memory sharing among forks and with single input parameters like processes number and maximum requests per fork.

Another thing to mention is that it is able to execute any file pointed by Web server ( FastCGI requester ). So we have the daemon that is hot ready for hosting providing :-)

The definitive care is taken in FCGI::Spawn on security. Besides the inode settings on local UNIX socket taken as input parameter, it is aware to avoid hosting users from changing the max_requests parameter meant correspondent to MaxRequests Apache's forked MPM parameter, and the respective current requests counter value as well.

The aforementioned max_requests parameter takes also care about the performance to avoid forks' memory leaks to consume all the RAM accounted on your hardware.

For shared hosting it is assumed that system administrator controls the process manager daemon script contents with those user hardware consumption limits and executes it with a user's credentials. E. g., the user should be able, to send signal to the daemon to initiate graceful restart on his/her demand ( this is yet to be done ) or change the settings those administrator can specifically allow in the daemon starter script without restart ( both of those features are about to be done in the future ). For example, user may want to recompile the own sources and quickly change the clean_inc_hash for this.

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

should be set before module compilation, to know where the socket resides. Default: /tmp/spawner.sock.

=item * sock_chown 

is the array reference which sets the parameters for chown() on newly created socket, when needed. Default: none.

=item * readchunk 

is the buffer size for user's source reading in plsrc function. Default: 4096.

=item * maxlength 

is the maximumum user's file size for the same. Default: 100000.

=item * max_requests 

is the maximum requests number served by every separate fork. Default: 20.

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

using this as an example, one can provide his/her own inclusion stuff.

=back

Every other parameter is passed "as is" to the FCGI::ProcManager's constructor. Except for addition about the  n_processes, which defaults to 5.

=head2 spawn

Fork a new process handling request like that being processed by web server.

=head2 callout

performs user's code execution. Isolates the max_requests and current requests counter values from changing in the user's source.

=head2 plsrc

Static function. Reads the supplied parameter up to "maxlength" bytes size chunked by "readchunk" bufer size and returns string reference. Used by default callout.

=head1 Thanks, Bugs, TODOs, Pros and Contras ( The Etcetera )

=head2 The Inclusion

I had many debates and considerations about inclusion the end user scripts. Here's my own conclusions:

=over

=item do()

should be the best but not verbose enough and very definitive about exceptions. But the major in this is that it updates the %INC so the user's changes on his/her requested Perl source file will not be recompiled every time. Of course you can clean_inc_hash but YMMV about %INC modification.

=item require()

makes the every fork failed to incorporate the user's source to die which is painful under heavy load.

=item system() or exec()

makes your FastCGI server to act as the simple CGI, except POST input is unavailable. Useful for debugging.

=item the default anonymous sub

reads user's source sized up to "maxlength" by buffers chunks of "readchunk" initial parameters. And, eval()'s it.

=item your own CODE ref

is able to be set by the "callout" initial parameter.

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

No surprise, Cygwin rocks. No mistake on TCP, Nginx doesn't handle Cygwin's local sockets. But it was my wrong documented TODO about TCP on 0.13 version, FCGI::Spawn does work out there its regular way ( as FCGI_* environment variables are set in proper way, on behalf of CGI::Fast ).
No ActiveState Perl can do this, sorry --- as it can't FCGI::ProcManager which is a must. And, surprise, the response time difference over CGI is dramatically better because of it's way more expensive on resources to launch a new process on this platform.

=back

=head2 The TODOs

=over

=item * %SIG

The UNIX signals processing is on its way in consequent releases. At least we should process the USR1 or so to recompile the all of the sources onboard, another signals to recompile only the part of them. This should provide the graceful restart feature.

=item * CGI

it's way hard to adopt to CGI::Fast's BEGIN block. Gonna skip it out. Should be even cooler to replace CGI.pm with XS alternate.

=item * DBI

Should be nice to overload DBI like the Apache::DBI does.

=item * Adoptable forks number

Should be nice to variate the n_processes due to the average system load, rest of the free RAM, etc.

=item * RC (init) script 

FCGI::ProcManager is able to put its pid file where you should need it. RC and SMF and packages are the "Right Thing" (tm). :-)

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
		my( $sn, $fcgi ) = @_;
		my $plsrc=plsrc $sn;
		eval $$plsrc;
	},
};

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
	my( $proc_manager, $max_requests ) = map { $this -> {$_} } qw/proc_manager max_requests/;
	my %fcgi_spawn_main = %main:: if $this->{clean_main_space}; # remember global vars set for cleaning in loop
	my %fcgi_spawn_inc = %INC if $this->{clean_inc_hash} == 2; # remember %INC to wipe out changes in loop
	my $req_count=1;
	while( my $fcgi = new CGI::Fast ) {
 		$proc_manager->pm_pre_dispatch();
		my $sn = $ENV{SCRIPT_FILENAME};
		my $dn = dirname $sn;
		my $bn = basename $sn;
		chdir $dn;
		# Commented code is real sugar for nerds ;)
		# map { $ENV{ $_ } = $ENV{ "HTTP_$_" } } qw/CONTENT_LENGTH CONTENT_TYPE/
  	#  if $ENV{ 'REQUEST_METHOD' } eq 'POST';	# for nginx-0.5
		# do $sn ; #or print $!.$bn; # should die on unexistent source file
		#	my $plsrc=plsrc $sn;	# should explanatory not
		#	eval $$plsrc;
		$this->callout( $sn, $fcgi );
		$req_count ++;
		exit if $req_count > $max_requests;
 		$proc_manager->pm_post_dispatch();
		$fcgi->initialize_globals; # to get rid of CGI::save_request consequences
		delete $INC{ $sn } if exists( $INC{ $sn } ) and $this->{clean_inc_hash} == 1 ; #make %INC to forget about the script included
		#map { delete $INC{ $_ } if not exists $fcgi_spawn_inc{ $_ } } keys %INC 
		%INC = %fcgi_spawn_inc if $this->{clean_inc_hash} == 2; #if %INC change is unwanted at all
		$this->clean_inc_particular;
		if( $this->{clean_main_space} ){ # actual cleaning vars
			foreach ( keys %main:: ){ 
				delete $main::{ $_ } unless defined $fcgi_spawn_main{ $_ } ;
			}
		}
	}
}

1;

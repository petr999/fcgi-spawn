package FCGI::Spawn::TestKit;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use Try::Tiny;
use Carp;
use File::Basename;
use Const::Fast;

$Carp::Verbose = 1;

has( qw/name    is ro   required 1    isa Str builder init_name/ );
has( qw/tests   is ro   required 1    isa ArrayRef lazy 1
  builder init_tests_list/, );
has( qw/failure    is rw   isa Str    default/ => '', );

__PACKAGE__->meta->make_immutable;

const( my $kits => { 
  'cgi_fast' => { qw/extends spawnable/, 'init_hash' => {
    qw/self_skip 1 push_tests/ => [
      qw/basic_cf serialize serialize_cf serialize_post_cf save_env/,
  ], }, },
  'cgi_fast_mod_perl' => { qw/extends spawnable/,
    'init_hash' => { qw/self_skip 1 push_tests/ => [
      qw/basic serialize serialize_cf/,
  ], }, },
  'mod_perl' => { qw/extends spawnable/,
    'init_hash' => { qw/self_skip 1 push_tests/ => [
      qw/basic serialize serialize_post serialize_mp2 serialize_post_mp2/,
  ], }, },
  'clean_inc_sub_ns' => { qw/extends spawnable/, 'init_hash' => {
    'push_tests' => [ qw/stats_cisns/, ], }, },
  map( { $_ => { qw/extends spawnable/, }; }
    qw/clean_main log_rotate max_requests pre_load save_env un_clean_main
        call_out un_save_env/,
  ),
  'fcgi' => { qw/extends spawnable/, 'init_hash' => { qw/self_skip 1
      push_tests/ => [ qw/basic serialize serialize_post/, ], }, },
  'initial' => { 'init_hash' => { 'tests'
    =>  [ qw/config_file shm test_utils kill_proc_dead socket bin/, ], }, },
  'stats' => { qw/extends spawnable/, 'init_hash' => { 'push_tests' => [
    qw/stats_mod/,
  ], }, },
  'x_stats' => { qw/extends spawnable/, 'init_hash' => { 'push_tests' => [
    qw/x_stats_dependence x_stats_cached/, 
  ], }, },
  'time_limit' => { qw/extends spawnable/, 'init_hash' => { 'push_tests' => [
    qw/time_limit_term_ignore time_limit_kill time_limit_parallel
      time_limit_kill_parallel/,
  ], }, },
} );

sub init_name{
  my $self = shift;
  croak unless my $class = ref( $self );
  my $name = pop @{ [ split /::/, $class ] };
  $name =~ s/(.)([A-Z])/$1_$2/g; $name = lc $name;
  return $name;
}

sub init_tests_list{
  croak( "Init tests list in a subclass please" );
}

sub make_class_name{
  my $name = shift;
  my $class_name = concat_class_name(  __PACKAGE__, $name );
}

sub concat_class_name{
  my( $base, $name ) = @_;
  my $base_ref = ref( $base );
  if( defined( $base_ref ) and length( $base_ref ) ){ $base = $base_ref; }
  my $class_name = ( defined( $name ) and length( $name ) )
    ? join '', map{ ucfirst $_ } split /_/, $name : '';
  $class_name = length( $class_name ) ? $base."::$class_name" : $base;
}

sub perform{
  foreach my $name ( @{ [ @_ ] } ){
    $name = basename( $name );
    $name =~ s/^\d+-(.+)\.t$/$1/; # for perform( __FILE__ );
    my $kit = retr_obj_by_name( $name );
    $kit -> testify;
  }
  done_testing();
}

sub try_use_class{
  my $class_name = shift;
  my $inc_key = join( '/', split /::/, $class_name).'.pm';
  unless( grep{ defined $INC{ join '/', $_ => $inc_key } } @INC
    ){ eval( "use $class_name;" ); croak $@ if $@; }
}

sub testify{
  my $self = shift;
  my $tests = $self -> get_tests;
  foreach my $test( @$tests ){
    diag( "Test: $test" );
    my( $rv => $fatal, ) = $self -> try_test( $test );
    last if $fatal;
    # sleep 10;
  }
  $self -> inner();
}

sub try_test{
  my( $self, $test ) = @_;
  my $name = $self -> get_name;
  my( $rv => $fatal, ) = ( 0 => 0, );
  try{
    ( $rv => $fatal, ) = $self -> try_out( $test );
  } catch {
    $self -> set_failure( "$_" );
    my $failure = $self -> get_failure;
    ok( 0 => "Test '$name' failed: $failure", );
    $fatal = 1;
  };
  return ( $rv => $fatal, );
}

sub serv_mods{
  my $self = shift;
  const( my $modules => [ qw/FCGI IPC::MM FCGI::Client CGI/ ], );
  my $rv;
  foreach my $module( @$modules ){
    $rv = use_ok( $module );
    last unless $rv;
  }
  ( $rv => not $rv, );
}

sub try_out{
  my( $self, $test ) = @_;
  my( $rv => $fatal, ) = ( 0 => 0, );
  if( $self -> can( $test ) ){
    ( $rv => $fatal, ) = $self -> $test;
  } else {
    my $class = concat_class_name( 'FCGI::Spawn::Tests' => $test, );
    my $obj = $self -> test_obj( $class );
    ( $rv => $fatal, ) = $obj -> check_out;
  }
  return( $rv => $fatal, );
}

sub test_obj{
  my( $self, $class ) = ( shift() => shift, );
  try_use_class( $class);
  my $obj = $class -> new( @_ );
}

sub retr_obj_by_name{
  my $name = shift;
  my( $class =>  $kit_obj, @args, );
  if( defined $$kits{ $name } ){
    my $kit = $$kits{ $name };
    my $extends = defined( $$kit{ 'extends' } ) ? $$kit{ 'extends' } : '';
    $class = make_class_name( $extends );
    @args = ( { 'name' => $name, }, );
    if( defined $$kit{ 'init_hash' } ){
      $args[ 0 ] = { %{ $args[ 0 ] }, %{ $$kit{ 'init_hash' }, }, };
    }
  } else {
    $class = make_class_name( $name );
  }
  if( $class ne __PACKAGE__ ){ try_use_class( $class ); }
  $kit_obj = $class -> new( @args );
  return $kit_obj;
}

1;

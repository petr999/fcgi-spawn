use strict;

use JSON;
no strict; # $spawn is a my for fcgi_spawn
$spawn->{ callout } =  sub{ do shift;
  CALLED_OUT: 
  if( defined( $it_is_test ) and $it_is_test ){
    print encode_json( [ qw/it is test/ ] );
    $it_is_test = 0;
  }
};
use strict;

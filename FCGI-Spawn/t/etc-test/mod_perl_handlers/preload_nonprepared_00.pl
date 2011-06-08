use strict;
use warnings;

use Apache::Fake;

sub msg_handler{ print 'HANDLER' }

Apache->request->cleanup_register(\&msg_handler);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Fake',
    'VERSION_FROM' => 'Fake.pm', # finds $VERSION
    'MAN3PODS' => { 'Fake.pm' => '$(INST_MAN3DIR)/Apache::Fake.$(MAN3EXT)' }
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Syndicate::Channel',
    'VERSION_FROM'	=> 'lib/Syndicate/Channel.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Data::Dumper      =>  2.102,
			    File::Basename    =>    2.6,
			    File::Spec        =>   0.82,
			    HTTP::Status      =>   1.26,
			    IO                =>   1.20,
			    IO::File          =>   1.08,
			    IO::Handle        =>   1.21,
			    IO::Seekable      =>   1.08,
			    LWP::Simple       =>   1.35,
			    Parse::RecDescent =>   1.80,
			    Test::Builder     =>   0.13,
			    Test::More        =>   0.42,
			    URI               =>   1.18,
			    URI::Escape       =>   3.20,
			    XML::RSS          =>   0.97,
			    XML::SAX          =>   0.10,
			    XML::SAX::Base    =>   1.02,
			    XML::SAX::Exception=>  1.01,
			    XML::SAX::ParserFactory=> 1.01,
			    XTM::base         =>   0.35,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Syndicate/Channel.pm', # retrieve abstract from module
       AUTHOR     => 'jgylta@online.no, rho@telecoma.net') : ()),
);

__END__


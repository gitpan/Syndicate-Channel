package Syndicate::Channel;

use strict;
use warnings;

require Exporter;
require AutoLoader;

use Syndicate::Channel::item;
use Syndicate::Channel::image;

our @ISA = qw(Exporter);

our $VERSION = '0.10';

=pod

=head1 NAME

Syndicate::Channel - Generalized News Syndication.

=head1 SYNOPSIS

  use Syndicate::Channel;
  
  # Create empty channel object
  $chan = new Syndicate::Channel();
  
  # Create channel from web reference
  $chan = new Syndicate::Channel (uri => 'http://tm.syndication.com/news.tmss');
  
  # Convert to a spesific format  
  $rss = new Syndicate::Channel::RSS ($chan);
  
  # Print out content
  $rss->toString(type => '1.0');

=head1 DESCRIPTION

This class provides an interface for channel modules and delivers basic 
functionality to create a default channel. It is meant to be used together
with subclasses which methods general enough for all classes are implemented
here.

When creating a channel object, this class is usually used to automatically determine
the type of object to be created, like so:

  # Convert a RSS channel to a TMSS channel

  use Syndicate::Channel;
  my $tmsschan = new Syndicate::Channel
  	(url =>"http://bolic.it.bond.edu.au/streams/webdev.tmss");
  my $rsschan = new Syndicate::Channel::RSS($tmsschan);
  print $tmsschan->toString(type => '1.0');

  # Create a channel from existing data and print it as RSS
  # This assumes @webarticles contains the required data for creating the items.
  # This may have been gathered from a database or search in a folder etc.
  
  ....
  use Syndicate::Channel;
  my $chan = new Syndicate::Channel();
  $chan->title('Andrew Grants DirtBike Digest');
  $chan->description('Andrew gives you his weekly view of dirtbikes.');
  $chan->link('http://www.andrewgrant.org/dirt/syndicate/default.asp');

  foreach my $article (@webarticles) {
    my $item = new Syndicate::Channel::item();
    $item->title($article->getTitle);
    $item->link($article->getLink);
    $item->description($article->getDescription);
    $chan->addItem($item);
  }

  print ( new Syndicate::Channel::RSS($chan) ).toString( type => '1.0' );

  
  # Creating a webpage with content from a channel file
  
  use Syndicate::Channel;
  my $chan = new Syndicate::Channel(url =>"http://tmss.mystreams.org/webdev.tmss");

  print "<h1>".$chan->title()."</h1>\n";
  foreach my $item (@{$chan->getItems()}) {
    print "<a href=\"".$item->url."\">".$item->title."</a>";
  }
  

=head2 Ontologies

Ontologies are extensions to the default functionality provided by this package.
Every ontology adds properties.
An example of such ontology is the Dublin Core (DC) which adds properties like
I<copyright> and I<author> to the channel, channel items or the channel image.
The following statement

  $chan->ontology('dc', 'http://purl.org/dc/elements/1.1/');

adds such an ontology together with a prefix to our channel.

=head1 CONSTRUCTORS

The constructor tries to create a specific channel object from the available
plugin modules based on the given input. If the type can not be identified
automatically, a generic channel object (L<Syndicate::Channel::Generic>) is returned.

Examples:

   # Create empty channel object of the type Syndicate::Channel::Generic
   $chan = new Syndicate::Channel();

   # By creating a channel object from content, the type is determined based
   # upon the given content. eg. A RSS file will return a RSS Channel object

   # Create channel from web reference
   $chan = new Syndicate::Channel (uri => 'http://tm.syndication.com/news.tmss');

   # Create channel from file
   $chan = new Syndicate::Channel (file => 'channels/news.tmss');

   # Create channel from text stream in variables
   $chan = new Syndicate::Channel (text => $content);

   # Create empty channel object from specified extension module
   $chan = new Syndicate::Channel (format => 'modulename');

   # Try to create channel object with given stream content
   $chan = new Syndicate::Channel::RSS        ($content);
   $chan = new Syndicate::Channel::TMSS       ($content);
   $chan = new Syndicate::Channel::..others.. ($content);

=head1 METHODS

Channels in particular formats (subclasses of this class) might provide extended methods
on their own. Following methods are common to all channel incarnations:

=over

=item B<title>

I<$title> = I<$channel>->title()

I<$channel>->title('Channel Title')

This is the method for setting and retrieving the title of a channel. The 
method allways returns the current value.

=item B<link>

I<$link> = I<$channel>->link()

I<$channel>->link('Channel link')

This is the method for setting and retrieving the url of the content source. 
The method always returns the current value.

=item B<description>

I<$description> = I<$channel>->description()

I<$channel>->description('Channel description')

This is the method for setting and retrieving a description for the channel. 
The method always returns the current value.

=item B<image>

I<$image> = I<$channel>->image()

I<$channel>->image( new Syndicate::Channel::image() )

This method allows retrieving/setting of an image for the channel. The image
is a L<Syndicate::Channel::image> object.

=back


=head2 Channel Item Management

These methods deal with managing items for a channel:

=over

=item B<addItems>

I<$channel>->addItems( new Syndicate::Channel::item() )

Method for adding one or more items to a channel. The items must be
objects of the L<Syndicate::Channel::item> class.

=item B<getItems>

I<$channel>->getItems()

returns list of L<Syndicate::Channel::item> objects representing each of the 
items associated with that channel.

=item B<setItems>

I<$channel>->setItems( new Syndicate::Channel::item() )

removes all existing items associated with the channel and adds the given
item(s). 

setItems() removes all items associated with the channel.

=item B<removeItem>

I<$channel>->removeItem( I<$item> )

Removes the given item from the channel.

=back

=head2 Ontologies

=over

=item B<ontology>

I<$channel>->ontology (I<$prefix>, I<$uri>)

This adds an ontology to the channel. You have to specify a prefix and a URI
for the ontology.

To remove an ontology, call the method with '' as value, like
  
  $chan->ontology('dc', '');

This will remove the dc ontology and all properties associated with that 
ontology from the channel.


I<$uri> = I<$channel>->ontology (I<$prefix>)

This retrieves the URI for the given ontology prefix.

I<%ontos> = I<$channel>->ontology()

Returns a hash representing the ontologies with the prefix as the key and
the URI as the value. (Note, this is inverse with how RSS stores its values).

=item B<property>

I<$channel>->property (prefix => I<$pre>, field => I<$field>, 'value' => I<$val>)

Adds a property to the channel. As with the C<ontology> method, a value of '' removes
the property from the channel.

Example:

  $chan->property (prefix => 'dc', field => 'author', 'value' => 'Bob Altman');


I<$channel>->property (prefix => 'pre', field => 'field') 

returns the value associated with a field and ontology. 

Example:

  $author = $chan->property (prefix => 'dc', field => 'author');


I<$channel>->property (prefix => 'pre')

Returns a hash with the fields associated with the ontology.

I<$channel>->delProperty (I<$prefix>);

Deletes all channel properties associated with that ontology connected to the
prefix.

=item B<toString>

print I<$channel>->toString (type => 'val')

Returns a simple string representation of the channel. The types available depend upon
the modules in use. FIXME!!

=back

=head1 AUTHORS

Copyright 2002, Jan Gylta <jgylta@online.no>, Robert Barta <rho@telecoma.net>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# This can be rewritten to be faster without checking rss for new object etc.

sub new {
  my $class  = shift;
  my %options = @_;

  my $content;
  
  if ($options{uri}) {
    use LWP::Simple;
    $content = get($options{uri});
  } elsif ($options{file}) {
    use LWP::Simple;
    $content = get("file:".$options{file});
  } elsif ($options{text}) {
    $content = $options{text};
  } elsif ($options{format}) {
    # ignore it here, not content relevant
  } elsif (%options) {
    die "Syndicate::Channel: Unknown option '%options'";
  }
  
  #could be rewritten to speed up detection
  
  my $self;
  if ($content) { # simple detection of what we got here
    eval {    # assume it is RSS
      use Syndicate::Channel::RSS;
      $self = new Syndicate::Channel::RSS ($content);
    }; if ($@) {
      eval {
	use Syndicate::Channel::TMSS;
	$self = new Syndicate::Channel::TMSS ($content);
      }; if ($@) {
	die "Syndicate::Channel: unable to parse/load content ($@)";
      }
    }
  } elsif ($options{format}) {
    if ($options{format} eq 'none' || $options{format} eq 'generic') {
      use Syndicate::Channel::Generic;
      return new Syndicate::Channel::Generic;
    } elsif ($options{format} eq 'tmss') {
      return new Syndicate::Channel::TMSS;
    } elsif ($options{format} eq 'rss') {
      return new Syndicate::Channel::RSS;
    }
  } else {
    use Syndicate::Channel::Generic;
    return new Syndicate::Channel::Generic;
  }
  return $self;
}

sub title {
  die "title method not overloaded\n";
}
sub link {
  die "link method not overloaded\n";
}
sub description {
  die "description not overloaded\n";
}

sub addItem {
  die "addItem method not overloaded\n";
}
sub getItems {
  die "getItems method not overloaded\n";
}
sub removeItem {
  die "removeItem method not overloaded\n";
}
sub ontology {
  die "ontology method not overloaded\n";
}

sub delOntology {
  die "delOntology method not overloaded\n";
}
sub property {
  die "property method not overloaded\n";
}

sub delProperty {
  die "delOntology method not overloaded\n";
}

# This method poupulates the object with the content of a different Syndication object
# its inherited to all subclasses.

sub populate {
  my $self = shift;
  my $content = shift;

  if (defined $content->title() ) {
    $self->title( $content->title() ); 
  }
  if (defined $content->description() ) {
    $self->description( $content->description() );
  }
  if (defined $content->link() ) {
    $self->link( $content->link() );
  }
  # Ontologies
  my %ontologies = $content->ontology();
  while (my ($key, $value) = each %ontologies ) {
    $self->ontology($key, $value);
  }
  # Properties
  while (my ($key, $ignore) = each %ontologies ) {
    my %properties = $content->property (prefix => $key);
    while (my ($field, $value) = each %properties ) {
      $self->property (prefix => $key,
		       field  => $field,
		       value  => $value
		      );
    }
  }
  # Items
  foreach my $item ($content->getItems()) {
    $self->addItem($item);
  }

  use Data::Dumper;
warn "===================adding image ".Dumper $content;
  if (defined $content->image() ) {
    $self->image( $content->image() );
  }
}



1;
__END__

package Syndicate::Channel::RSS;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use XML::RSS;
use Syndicate::Channel;

@ISA = qw(Exporter AutoLoader Syndicate::Channel);
@EXPORT = qw( );
our $VERSION = '0.10';

=pod

=head1 NAME

Syndicate::Channel::RSS - Channel Syndication, RSS Driver

=head1 DESCRIPTION

This class implements the abstract interface provided in 
L<Syndicate::Channel> based on RSS.

For more information about RSS see XML::RSS

=head1 INTERFACE

=head2 Constructor

I<$channel> = new Syndicate::Channel::RSS ();

Creates an empty RSS Channel object.

I<$channel> = new Syndicate::Channel::RSS ( I<any Syndicate::Channel::* object> );

Creates a RSS Channel object populated with the values from the given
channel object.

I<$channel> = new Syndicate::Channel::RSS ( I<content> );

If the content contains a RSS data stream, fills the RSS channel with its data.

=head2 Methods

This class implements all methods of L<Syndicate::Channel>, plus the following

=over

=item B<toString>

I<$channel>->toString(type => I<any subformat>);

This methods generates a string containing an RSS representation. Following
subformats are supported:

=over

=item 1.0: RSS 1.0

=item 0.9: RSS 0.9

=item 0.91: RSS 0.91

=back

=cut

sub new {
  my $class   = shift;
  my $content = shift;

  my $self = bless {rss => new XML::RSS }, $class;

  if (ref ($content) =~ /Syndicate::Channel::.*/) {
    # we got ourself a channel object, lets clone/populate
    $self->populate($content);
  } elsif ($content) { # is is a string, so we parse it
    $self->{rss}->parse($content);
  }
  return $self;
}

sub title {
  my $self = shift;
  my $title = shift;

  if (defined $title) {
    $self->{rss}->channel(title => $title);
  } 
  return $self->{rss}->{channel}->{title};
  
}

sub link {
  my $self = shift;
  my $link = shift;
  	
  if (defined $link) {
    $self->{rss}->channel(link => $link);
    
  } 
  return $self->{rss}->{channel}->{link};
  
}

sub description {
  my $self = shift;
  my $description = shift;

  if (defined $description) {
    $self->{rss}->channel(description => $description);
  } 
  return $self->{rss}->{channel}->{description};
  
}


sub image {
  my $self = shift;
  my $image = shift;

  if (defined $image) {
    #get the properties...
    
    #1. get ontologies (add if nessesary)
    #2. go thru keys and get properties
       		
       		my %modules;
       		my %hash = $self->ontology();
       		while (my ($module, $ignore) = each %hash ) {
       			
       			my %properties = $image->property(prefix =>"$module");
       			$modules{$module} = {%properties};

       		}
       		
       		
       		
	        $self->{rss}->image(
          		title  		=> $image->title(),
          		url    		=> $image->url(),
          		link   		=> $image->link(),
		  	width      	=> $image->width(),
          		height      	=> $image->height(),
          		description 	=> $image->description(),
          		%modules
        	);
       		
       	} else {
    		
    		my $image = new Syndicate::Channel::image();
    		
    		$image->title ( $self->{rss}->{image}->{title} ) ;
    		$image->url ( $self->{rss}->{image}->{url} ) ;
    		$image->link ( $self->{rss}->{image}->{link} ) ;
    		$image->width ( $self->{rss}->{image}->{width} ) ;
    		$image->height ( $self->{rss}->{image}->{height} ) ;
    		$image->description ( $self->{rss}->{image}->{description} ) ;

       		my %hash = $self->ontology();
       		while (my ($module, $ignore) = each %hash ) {
       			
       			my $properties = $self->{rss}->{image}->{$module};

     			while (my ($field, $value) = each %{$properties} ) {
     				$image->property(prefix => $module, field => $field, value => $value);
     			}
 			
       		}
    		return $image;
  	}

}




# rss items don't have images
sub addItem {
	my $self = shift;

	
	my %hash = $self->ontology();

	while (my $item = shift) {
		my %modules;
		while (my ($module, $ignore) = each %hash ) {
			my %properties = $item->property(prefix =>"$module");
		
			if (%properties ne "0") {
				$modules{$module} = {%properties};
			}
		}

		my %newitem;
		if (defined $item->title() ) {
			 $newitem{'title'} = $item->title();
		}
		if (defined $item->link() ) {
			 $newitem{'link'} = $item->link();
		}
			
		if (defined $item->description() ) {
			 $newitem{'description'} = $item->description();
		}
		
		while (my ($module, $value) = each %modules ) {
			$newitem{$module} = $value;
		}
		
		$self->{rss}->add_item (%newitem, %modules);				 
 		
 	}

 	
}




sub getItems {
	
	my $self = shift;
 	my @items;
	foreach my $item (@{$self->{rss}->{'items'}}) {
 		my $newitem = $self->myCreateItem($item);
 		push(@items, $newitem ) ;
 	}
 	return @items;
 
 
}	


## FIXME:: name internal methods as __createItem, not really a convention though

# internal method to create item from rss item
sub myCreateItem {
  my $self = shift;
  my $item = shift;
	
  my $newitem = new Syndicate::Channel::item ();
  $newitem->title( $item->{'title'} );
  $newitem->link( $item->{'link'} );
  $newitem->description( $item->{'description'} );
 	
  my %hash = $self->ontology();
  while (my ($module, $ignore) = each %hash ) {

    my $properties = $item->{$module};
    while (my ($field, $value) = each %{$properties} ) {
      $newitem->property(prefix => $module, field => $field, value => $value);
    }
  }
  return $newitem;
}

sub removeItem {
	my $self = shift;
	my $remove_item = shift;
	
	use Data::Dumper;
	my @newlist;
	foreach my $item (@{$self->{rss}->{'items'}}) {

 		my $newitem = $self->myCreateItem($item);

		if (Dumper($newitem) ne Dumper($remove_item) ) {
			
			push(@newlist, $item ) ;
		}
		 		
 	}
 	$self->{rss}->{'items'} = [@newlist];
}
	
	


sub ontology {
  my $self = shift;
  my $prefix = shift;
  my $value = shift;

  if (defined $value) {

  	if (defined $prefix) {
  		
  		if ($value eq '') {
    			#delete ontology
    			
    			$self->delOntology($prefix);  		
	  	} else {
  			# add ontology
     			
     			$self->{rss}->add_module(prefix => $prefix, 			
  						 uri    => $value);
  			
  		}
  	}
  
  } else {

	if ($prefix) {
  		#return value of ontology
		my %ontologies = %{$self->{rss}->{'modules'}};
		%ontologies = map { $ontologies{$_} => $_ } keys %ontologies;
		
   		return %ontologies->{$prefix};
  		
	} else {
		# return hash of ontologies

		my %ontologies;
		while (my ($key, $value) = each %{$self->{rss}->{modules}}) {
    				$ontologies{$value} = $key;    				
    		}

		return %ontologies;
	}
  }
  
}

sub delOntology {

  my $self = shift;
  my $prefix = shift;

  while (my ($key, $value) = each %{$self->{rss}->{modules}}) {
    if ($value eq $prefix) {
    	delete $self->{rss}->{modules}->{$key};
    }
  };
    
  
  foreach my $item (@{$self->{rss}->{'items'}}) {
  	delete $item->{$prefix};
  }
  
  delete $self->{rss}->{image}->{$prefix};

}

sub property {
  my $self = shift;
  my %params = @_;	

  my $prefix = $params{prefix};
  my $field = $params{field};
  my $value = $params{value};

  if ($prefix) {
  	if (defined $field) {
  	
  		if (defined $value) {
  	
		  	if ($value eq '') {
  				# remove property
  				
		
  				#while (my ($key, $value) = each %{$self->{rss}->channel($prefix)}) {
    				#	if ($field eq $key) {
    				#		print "deleting : $prefix - $key\n";
    						delete $self->{rss}->channel($prefix)->{$field};  
    				#	}
  				#};		
				
  			} else {
				# if added as module...
 		
				if ( $self->{rss}->channel($prefix) == 0) {	
					$self->{rss}->channel($prefix => {
						$field => $value
						}
					);
				
				} else {
					$self->{rss}->channel($prefix)->{$field} = $value;
				}
				

						
  			}
  		} else {
		  	# return value of prefix and field
	  	
		  	if ( $self->{rss}->channel($prefix) == 0 ) { 
		  		return undef;
		  	} else {
		  		
		 	 	return $self->{rss}->channel($prefix)->{$field};
			}
		
		  	
		  	
		  	
			  	
  		}
  	} else {
  		
  		#return hash of fields and values for prefix

		my %ontologies;
		if ($self->{rss}->channel($prefix) != 0 ) { 
			while (my ($key, $value) = each %{$self->{rss}->channel($prefix)}) {
    					$ontologies{$key} = $value;
    			}
    			return %ontologies;
    			
    		} else {
    			return ();
    		}

		

  	}
  } else {
  	# return whole list

	my @list;
	while (my ($ignore, $ontology) = each %{$self->{rss}->{modules}}) {

		my %hashy = $self->property(prefix => $ontology);
		
		while (my ($key, $value) = each %hashy ) {
    			push (@list, [$ontology, $key, $value]);
    		}
    	}
	
	return @list;
		
	
  }
}

	
sub delProperty {
	my $self = shift;
	my %options = @_;
	my $prefix = $options{prefix};

	delete $self->{rss}->channel()->{$prefix};  
  	
}  

sub toString {
  my $self = shift;
  my %options = @_;
  my $type = $options{type};  
  
  if ($type eq '1.0') {
    $self->{rss}->{output} = '1.0';
  } elsif ($type eq '0.9') {
    $self->{rss}->{output} = '0.9';  	
  } elsif ($type eq '0.91') {
    $self->{rss}->{output} = '0.91';
  } else {
  	warn "Unknown format, using default, RSS 1.0";
  	$self->{rss}->{output} = '1.0';
  	
  }
  
  return $self->{rss}->as_string;
	
}

1;

__END__

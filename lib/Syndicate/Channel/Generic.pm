package Syndicate::Channel::Generic;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use Syndicate::Channel;

@ISA = qw(Exporter AutoLoader Syndicate::Channel);
@EXPORT = qw( );
our $VERSION = '0.10';

=pod

=head1 NAME

Syndicate::Channel:Generic - Generic class for a syndication channel

=head1 SYNOPSIS

This channel provides the basic interface for creating a syndication 
channel.

=head1 DESCRIPTION

This is a generic implementation of a channel with minimum 
functionality and no particular representation (eg. RSS) in mind. It 
provides the basic funtionality you need to create and manage a 
syndication channel. 

Once a channel has been created it can be converted into any other 
type of channel available, eg RSS or TMSS channel.

The class is primarily meant to show how a syndication module can be 
implemented. It can however also be used for syndication as it 
implements all the functionality necessary to create a channel, an 
image and the items together with ontologies and properties. A simple
toString method is also provided.


=head1 INTERFACE

=head2 Constructor

I<$channel> = new Syndicate::Channel::Generic ();

This constructor creates an empty channel object based on the 
Generic class.

I<$channel> = new Syndicate::Channel::Generic ( I<$channel2> );

This takes a object derived from L<Syndicate::Channel> and converts it 
to a L<Syndicate::Channel::Generic> object. This can be used for 
converting channel objects between formats.

=head2 Methods

This class implements all methods of L<Syndicate::Channel>. 

The method B<toString>
returns a string representation of the channel in the form of a 
L<Data::Dumper> dump. It takes no parameters.

There are no other special methods available.


=head1 AUTHORS

Copyright 2002, Jan Gylta <jgylta@online.no>, Robert Barta 
<rho@telecoma.net>, All rights reserved.

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.


=cut

sub new {
	my $proto = shift;
	my $content = shift;

	my $class = ref($proto) || $proto;
	my $self  = {};						
	$self->{title}   = undef;
	$self->{link}   = undef;
	$self->{description}   = undef;
	$self->{items} = [];
	$self->{image}   = undef;
	
	bless ($self, $class); 
	
	if (ref ($content) =~ /Syndicate::Channel::.*/) {
		$self->populate($content);
        } elsif ($content) {
  		$self->parse($content);
  	}
	
	return $self;
	
}

sub title {
	my $self = shift;
	my $title = shift;
	defined $title ? $self->{title} = $title : $self->{title};
}

sub link {
	my $self = shift;
	my $link = shift;
	defined $link ? $self->{link} = $link : $self->{link};
	
}

sub description {
	my $self = shift;
	my $description = shift;
	defined $description ? $self->{description} = $description : $self->{description};	
	
}

sub image {
	my $self = shift;
	my $image = shift;
	return defined $image ? $self->{image} = $image : $self->{image};	
}

sub addItem {
	my $self = shift;
	my @items = @_;
	
	foreach my $item (@items) {
		push(@{$self->{items}}, $item ) ;
	}
}

sub setItems {
	my $self = shift;
	my @items = @_;
	$self->{items} = [];
	$self->addItem(@items);
		
}


sub getItems {
	my $self = shift;
	return @{$self->{items}};
}

sub removeItem {
	my $self = shift;
	my @items = @_;
	foreach my $item (@items) {
		
		my $newlist = [];
		
		foreach my $old_item ($self->getItems()) {

			if ($item != $old_item) {
				push(@{$newlist}, $old_item);
			}
			
		}

		$self->{items} = $newlist;
	}
}
		
	
sub ontology {
  my $self = shift;
  my $prefix = shift;
  my $value = shift;

  if (defined $value) {

  	if (defined $prefix) {

  		if ($value eq '') {
			# Delete ontology    			
    			$self->delOntology($prefix);  		
	  	} else {
  			# Add ontology
  			$self->{ontologies}->{$prefix} = $value;
  			
  		}
  	}
  } else {
	if ($prefix) {
  		return $self->{ontologies}->{$prefix}; 
	} else {
		return %{$self->{ontologies}} ;
	}
  }
  
  
}



sub delOntology {
  my $self = shift;
  my $prefix = shift;
  
  #delete from items
  foreach my $item ($self->getItems()) {
  	$item->delProperty (prefix => $prefix);
  }
  
  #delete from image
  if (defined $self->{image}) {
  	$self->{image}->delProperty (prefix => $prefix);
  }
  #delete from channel
  $self->delProperty (prefix => $prefix);
  
  #delete from channel hash
  delete $self->{ontologies}{$prefix};

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
  				
				my @newlist;
				foreach my $element (@{$self->{properties}}) {

					my $p_prefix = $element->[0];
					my $p_field = $element->[1];

					if ( ($p_prefix ne $prefix) || ($p_field ne $field) ) {

						push(@newlist, $element) ;
					}
				}

				$self->{properties} = [@newlist];
				
				
  			} else {
	 			foreach my $pref (keys %{$self->{ontologies}} ) {
					
					if ($pref eq $params{prefix} ) {
 		
				#add
				push(@{$self->{properties}}, [$params{prefix}, $params{field}, $params{value} ] ) ;
				return;

					}
				}
				print $params{prefix}." not found among ontologies, add before setting properties.\n";

			 				
  			}
  		} else {
		  	# return value of prefix and field
		  	
			foreach my $element (@{$self->{properties}}) {
				
				my $p_prefix = $element->[0];
				my $p_field = $element->[1];
				my $p_value = $element->[2];
	
				if ($p_prefix eq $prefix && $p_field eq $field) {
					return $p_value;
				}
			}
			return undef;
			  	
  		}
  	} else {
  		
  		#return hash of fields and values for prefix
	 	my %myhash;
		foreach my $element (@{$self->{properties}}) {
		
			my $p_prefix = $element->[0];
			my $p_field = $element->[1];
			my $p_value = $element->[2];
			
			if ($p_prefix eq $prefix) {
				
				$myhash{$p_field} = $p_value;
			}
		}
		return %myhash;
  	}
  } else {
  	# return whole list
  	return @{$self->{properties}}; 
  }
}

	
sub delProperty {
	my $self = shift;
	my %options = @_;
	my $prefix = $options{prefix};
	
	my @new_list;
	my $property_list = $self->{properties};
	
		foreach my $element (@{$property_list}) {
		my $p_prefix = $element->[0];
		
		if ($p_prefix ne $prefix) {
			push(@new_list, $element) ;
		}
	}
	$self->{properties} = \@new_list;
	
}  	
    	

# parsing object from content
# doubt this works...
sub parse {
	my $self = shift;
	my $content= shift;

	my $VAR1; #$perlObj
    	eval "$content";
    	
    	return $VAR1;	
}

# creating string rep of objetc
sub toString {
  my $self = shift;
	
  use Data::Dumper;
  my $content = Data::Dumper->new( [$self] );
  return $content;
}

__END__
1;


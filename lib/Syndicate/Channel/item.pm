package Syndicate::Channel::item;

=pod

=head1 NAME

Syndicate::Channel::item - Item class

=head1 SYNOPSIS

  my $item = new Syndicate::Channel::item ();
  $item->title('This is the item title');


=head1 DESCRIPTION

This class is a generic implementation of channel items. This is used to
provide a general method of accessing items no matter which type of channel
one is dealing with.

=head1 INTERFACE

=head2 Constructor

  new Syndicate::Channel::item ();

  new Syndicate::Channel::item (title => 'my title',
	                        link  => 'http://link.com', ...
			       );

The available fields in the constructors are

=over

=item I<title>: holds title of item

=item I<link>: link to the main article

=item I<description>: description of item

=back


=head2 Methods

=over

=item B<title>

I<$title> = I<$item>->title()

I<$item>->title('item Title')

This is the method for setting and retrieving the title of a item. The method allways returns the current value.

=item B<link>

I<$link> = I<$item>->link()

I<$item>->link('item link')

This is the method for setting and retrieving the url of the content source. 
The method allways returns the current value.

=item B<description>

I<$description> = I<$item>->description()

I<$item>->description('item description')

This is the method for setting and retrieving a description for the item. 
The method allways returns the current value.

=item B<property>

Same functionality as for the Syndicate::Channel, except its applied for 
the item.

=back

=head1 AUTHORS

Copyright 2002, Jan Gylta <jgylta@online.no>, Robert Barta <rho@telecoma.net>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut

sub new {
	my $proto = shift;					# check for passed class...
	
	my %options = @_;
	
	my $class = ref($proto) || $proto;			# finds refference or passed class ??
	my $self  = {};						# Creates empty object
	
	if (defined $options{title}) {
		 $self->{title} = $options{title};
	} else {
		 $self->{title} = undef;	
	}
	defined $options{description} ? $self->{description} = $options{description} : $self->{description} = undef;
	defined $options{link} ? $self->{link} =  $options{link} : $self->{link} = undef;	
	
	bless ($self, $class);   # sets self as a object and puts it in the current package, whatever that means	
	
	return $self;
	
	
}

sub title {
	my $self  = shift;
	my $title = shift;
	defined $title ? $self->{title} = $title : $self->{title};
}

sub description {
	my $self = shift;
	my $description = shift;
	defined $description ? $self->{description} = $description: $self->{description};
}


sub link {
	my $self = shift;
	my $link = shift;
	defined $link ? $self->{link} = $link : $self->{link};	
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
  				
				#my @newlist;
				foreach my $element (@{$self->{properties}}) {
				use Data::Dumper;

					my $p_prefix = $element->[0];
					my $p_field = $element->[1];

					if ( ($p_prefix ne $prefix) || ($p_field ne $field) ) {

						push(@newlist, $element) ;
					}
				}

				$self->{properties} = [@newlist];
				
				
  			} else {
 		
				#add
				push(@{$self->{properties}}, [$params{prefix}, $params{field}, $params{value} ] ) ;
				return;
			 				
  			}
  		} else {
		  	# return value of prefix and field
		  	my %myhash;
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
				if ($p_value ne "") {
					$myhash{$p_field} = $p_value;
				}
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
	
	my $property_list = $self->{properties};
	
		foreach my $element (@{$property_list}) {
		
		my $p_prefix = $element->[0];
		
		if ($p_prefix ne $prefix) {
			push(@new_list, $element) ;
		}
	}
	$self->{properties} = \@new_list;
	
}

1;

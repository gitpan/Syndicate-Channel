package Syndicate::Channel::image;

=pod

=head1 NAME

Syndicate::Channel::image - Image class (auxiliary package)

=head1 SYNOPSIS

  use Syndicate::Channel::image;
  my $image = new Syndicate::Channel::image ();
  $image->title("Channel Picture");
  $image->url("http://www.images.com/button.gif");

=head1 DESCRIPTION

Objects of this class hold information about an image associated with a 
channel.

=head1 INTERFACE

=head2 Constructor

I<$channel> = new Syndicate::Channel::image ();

I<$channel> = new Syndicate::Channel::image (

                                title       => 'my title', 
				url         => 'http://www.link.com', 
				link   	    => 'http://my.link.com', 
				description => 'Image description', 
				width       => '32',
				height      => '32',
				);

=head2 Methods

=over

=item B<title>

I<$title> = I<$image>->title()

I<$image>->title('image Title')

This is the method for setting and retrieving the title of a image. The 
method allways returns the current value.

=item B<link>

I<$link> = I<$image>->link()

I<$image>->link('http://link.com/')

This is the method for setting and retrieving the link from the image. 
The method allways returns the current value.

=item B<url>

I<$url> = I<$image>->url()

I<$image>->url('http://image.gif')

This is the method for setting and retrieving the url of the image. 
The method allways returns the current value.

=item B<description>

I<$description> = I<$image>->description()

I<$image>->description('image description')

This is the method for setting and retrieving a description for the image. 
The method allways returns the current value.

=item B<width>

I<$width> = I<$image>->width()

I<$image>->width(numeric value)

This is the method for setting and retrieving a width for the image. 
The method allways returns the current value.


=item B<height>

I<$height> = I<$image>->height()

I<$image>->height(numeric value)

This is the method for setting and retrieving a height for the image. 
The method allways returns the current value.

=item B<property>

Same functionality as for the Syndicate::Channel, except its applied for 
the image.

=item B<delproperty>

Same functionality as for the Syndicate::Channel, except its applied for 
the image.


=back


=head1 AUTHORS

Copyright 2002, Jan Gylta <jgylta@online.no>, Robert Barta <rho@telecoma.net>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut

sub new {
	my $proto = shift;					# check for passed class...
	my $class = ref($proto) || $proto;			# finds refference or passed class ??
	my $self  = {};						# Creates empty object
	my %options = @_;
	
	defined $options{title} ? $self->{title} = $options{title} : $self->{title} = undef;
	defined $options{url} ? $self->{url} = $options{url} : $self->{url} = undef;
	defined $options{link} ? $self->{link} = $options{link} : $self->{link} = undef;
	defined $options{width} ? $self->{width} = $options{width} : $self->{width} = undef;
	defined $options{height} ? $self->{height} = $options{height} : $self->{height} = undef;
	defined $options{description} ? $self->{description} = $options{description} : $self->{description} = undef;
	
	bless ($self, $class);   # sets self as a object and puts it in the current package, whatever that means	
	
	return $self;
	
}

sub title {
        my $self = shift;
        my $title = shift;
        defined $title ? $self->{title} = $title : $self->{title};
}


sub url {
        my $self = shift;
        my $url = shift;
        defined $url ? $self->{url} = $url : $self->{url};
}


sub link {
        my $self = shift;
        my $link = shift;
        defined $link ? $self->{link} = $link : $self->{link};
}


sub width {
        my $self = shift;
        my $width = shift;
        defined $width ? $self->{width} = $width : $self->{width};

}

sub height {
        my $self = shift;
        my $height = shift;
        defined $height ? $self->{height} = $height : $self->{height};
}

sub description {
        my $self = shift;
        my $height = shift;
        defined $height ? $self->{description} = $height : $self->{description};
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

__END__


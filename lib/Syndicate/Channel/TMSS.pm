package Syndicate::Channel::TMSS;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK);
 
require Exporter;
require AutoLoader;

use Syndicate::Channel;

use Data::Dumper;

@ISA = qw(Exporter AutoLoader Syndicate::Channel);
@EXPORT = qw( );
our $VERSION = '0.10';

=pod

=head1 NAME

Syndicate::Channel::TMSS - Channel Syndication, TMSS Driver

=head1 DESCRIPTION

This class implements the abstract interface provided in
L<Syndicate::Channel> based on Topic Maps.

=head1 INTERFACE

=head2 Constructor

I<$channel> = new Syndicate::Channel::TMSS ();

Creates an empty TMSS Channel object.

I<$channel> = new Syndicate::Channel::TMSS ( I<any Syndicate::Channel::* object> );

Creates a TMSS Channel object populated with the values from the given 
channel object.

I<$channel> = new Syndicate::Channel::TMSS ( I<content> );

If the content contains a TMSS data stream (see below), fills the TMSS channel
with its data.

=cut

use XTM;
use XTM::XML;
use XTM::AsTMa;

use XTM::Path;

sub new {
  my $class   = shift;
  my $content = shift;

  my $self = bless {}, $class;

  # Set to default scope
  use XTM::PSI;
  $self->{scope} = $XTM::PSI::xtm{'universal_scope'};

  if (ref ($content)) {  # use the abstract methods to clone a TMSS from this channel
    $self->{xtm} = new XTM ( consistency => { merge => [ 'Subject_based_Merging' ] }	);

    my $xtmp = new XTM::Path (default => $self->{xtm});
    # create channel topic, this MUST be there
    my $channel = $xtmp->create ('/topic[instanceOf/topicRef/@href = "#channel"]');
    $self->{xtm}->add ($channel);

    $self->populate($content);
  } elsif ($content) {
    my $type;
    if ($content =~ /^<\?xml/) {
      $type = "XML";
      # Asume we have XML 
      $self->{xtm} = new XTM (tie => new XTM::XML (text => $content),
      				consistency => { merge => [ 'Subject_based_Merging' ] }
      				);
    } else {
      $type = "ATM";
      # Asume ATM
      $self->{xtm} = new XTM (tie => new XTM::AsTMa (text => $content),
      				consistency => { merge => [ 'Subject_based_Merging' ] }
      				);
    }
    
    # Check to make sure we have a channel topic. If not, warn and return undef
    use XTM::Path;
    my $xtmp = new XTM::Path (default => $self->{xtm});
    my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
   
    if ( ref($chan) ne 'XTM::topic') {
    	warn 'Unable to find Channel in supplied content.\n';
    	warn "Content was interpreted as : $type\n";
    	return undef;
    }
    
    
  } else {
    
    # Create "empty" object
    $self->{xtm} = new XTM;

    # create channel topic, this MUST be there
    use XTM::Path;
    my $xtmp = new XTM::Path (default => $self->{xtm});
    my $topic = $xtmp->create ('/topic[instanceOf/topicRef/@href = "#channel"]');

    # add it to map,
    $self->{xtm}->add ($topic);
  }
  return $self;
}

=pod


=head2 Methods

This class implements all methods of L<Syndicate::Channel> plus the following:

=over

=item B<scope>

This method sets or retrieves the current scope of the channel. This can be
used to generate channels with different element content based upon the provided value,
for instance for providing descriptions in different languages or levels.

=cut


sub scope {
  my $self = shift;
  my $scope = shift;
  
  return $scope ? $self->{scope} = $scope : $self->{scope};
}

=pod

=item B<toString>

I<$channel>->toString(type =>'atm');

This method can expect a parameter C<type> which can the following
values. The method will output the channel in that format:

=over

=item C<ATM> : AsTMa

=back

=cut


# Premise:
# Add basename with current scope to channel topic
# Problems:
# Removes all basenames, hence removing other scopes aswell...
#  -> $chan->basenames ( \@myarrayref ); ?? Check docs.

sub title {
  my $self  = shift;
  my $title = shift;

  my $xtmp = new XTM::Path (default => $self->{xtm});
  	
  my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
  if (defined $title) {
    $chan->undefine ('baseNames');
    my $basename = $xtmp->create ('/baseName[scope/topicRef/@href = "'.$self->{scope}.'"][baseNameString/text() = "'.$title.'"]');
    $chan->add__s ($basename);
  } else {
    my ($title) = $xtmp->find ('/baseName[scope/topicRef/@href = "'.$self->{scope}.'"]/text()', $chan);
    return $title;
  }
  return $self->title();
}	

# Premise:
# Add url to channel topic as resourceRef with current scope

sub link {

 	my $self = shift;
	my $link = shift;

  	use XTM::Path;
  	my $xtmp = new XTM::Path (default => $self->{xtm});
  	my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
	
	if (defined $link) {
		#removing possible existing link
		my ($occurrence)= $xtmp->find ('/occurrence[resourceRef/@href][scope/topicRef/@href = "'.$self->{scope}.'"]', $chan);
		if (defined $occurrence) {
			my @myarrayref = grep( $_ ne $occurrence , @{$chan->occurrences} );
			$chan->occurrences ( \@myarrayref );
		}

		my $occr = $xtmp->create ('/occurrence[resourceRef/@href = "'.$link.'"][scope/topicRef/@href = "'.$self->{scope}.'"]');
		$chan->add__s ($occr);
	} else {
		my ($occr) = $xtmp->find ('/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceRef/@href', $chan);
		return $occr;
	}
	return $self->link();


	
}

# Premise:
# Add description as inline (resourceData) under current scope to channel topic

sub description {
	my $self = shift;
	my $description = shift;

  	use XTM::Path;
  	my $xtmp = new XTM::Path (default => $self->{xtm});
  	my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
  		
	if (defined $description) {
		# Delete existing
		my ($occurrence)= $xtmp->find ('/occurrence[resourceData/@href][scope/topicRef/@href = "'.$self->{scope}.'"]', $chan);
		my @myarrayref = grep( $_ ne $occurrence , @{$chan->occurrences} );
		$chan->occurrences ( \@myarrayref );

		#add new
		my $new_occr = $xtmp->create ('/occurrence[resourceData/text() = "'.$description.'"][scope/topicRef/@href = "'.$self->{scope}.'"]');
		$chan->add__s($new_occr);		
		
	} else {
		my ($occurrence) = $xtmp->find ('/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceData/text()', $chan);
		return $occurrence;
	}
	return $self->description();
	
}


## IMAGE ##

#image (channel-image)
#bn: title
#oc (link): http://link
#oc (src): http://link
#in: description
#

sub image {
  my $self = shift;
  my $image = shift;

  my $xtmp = new XTM::Path (default => $self->{xtm});
  my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
	
  #1. get ontologies 
  my @ontologies = $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"]/@id');

  if (defined $image) {	# adding image
    # Remove existing topic and associations to it
    my ($topic) = $xtmp->find ('/topic[instanceOf/topicRef/@href = "#channel-image"]');
    if (defined $topic) {
      my @topics = $xtmp->find ('/association
	                           [member/roleSpec/topicRef/@href = "#holder"]
	                           [member/topicRef/@href = "#'.$topic->id().'"]');
      foreach my $a (@topics) {
	$self->{xtm}->remove( $a->id() );
      }		
      $self->{xtm}->remove( $topic->id() );
    }
    # Add new image topic
    my $image_topic = $xtmp->create ('/topic
		     [instanceOf/topicRef/@href = "#channel-image"]
		     [/baseName[baseNameString/text() = "'.$image->title().'"]
		               [scope/topicRef/@href = "'.$self->{scope}.'"]
		     ]
		     [/occurrence[resourceRef/@href = "'.$image->url().'"]
		                 [instanceOf/topicRef/@href = "src"]
		                 [scope/topicRef/@href = "'.$self->{scope}.'"]
		     ]
		     [/occurrence[resourceRef/@href = "'.$image->link().'"]
		                 [instanceOf/topicRef/@href = "link"]
		                 [scope/topicRef/@href = "'.$self->{scope}.'"]
		     ]
		     [/occurrence[resourceData/text() = "'.$image->description().'"]
		                 [scope/topicRef/@href = "'.$self->{scope}.'"]
		     ]');     
		
##    die "image: ".Dumper $image_topic;

    $self->{xtm}->add($image_topic);
    
    my ($topic_id) = $xtmp->find('topic/@id', $image_topic);
    
    
    # Add properties
    use Data::Dumper;
    my %hash = $self->ontology();
    
    while (my ($module, $ignore) = each %hash ) {
      
      if (grep {$_ eq $module} @ontologies) {
	
	my %properties = $image->property(prefix =>"$module");
	
	while (my ($field, $value) = each %properties ) {
	  my $a = $self->createPropertyAssoc ($value, $field, $module, $image_topic->id() );
	  $self->{xtm}->add($a);
	}
	
      } else {
	warn "Ontology for $module does not exist. Data for $module will be ignored.\n";
      }
      
    }
    
    
    # Deal with height, width
    if ($image->width() ne "") {
      my $a = $self->createPropertyAssoc ($image->width(), "width", "tmss_image_ontology", $chan->id() );
      $self->{xtm}->add($a);
    }
    
    if ($image->height() ne "") {
      my $b = $self->createPropertyAssoc ($image->height(), "height", "tmss_image_ontology", $chan->id() );
      $self->{xtm}->add($b);
    }
    
  } else {
##die "create new image";
		
		# retrieve info
		# get image topic
		# get associated values
		
		
		my $image = new Syndicate::Channel::image();
    		
    		my ($topicID) = $xtmp->find ('/topic[instanceOf/@href = "#channel-image"]/@id');
    		
    		my ($title) = $xtmp->find ('/topic[instanceOf/@href = "#channel-image"]/baseName[scope/topicRef/@href = "'.$self->{scope}.'"]/baseNameString/text()');
   		$image->title ($title ) ;
   		
   		my ($url) = $xtmp->find ('/topic[instanceOf/@href = "#channel-image"]/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"][instanceOf/topicRef/@href = "src"]/resourceRef/@href');
    		$image->url ( $url ) ;
    		
    		my ($link) = $xtmp->find ('/topic[instanceOf/@href = "#channel-image"]/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"][instanceOf/topicRef/@href = "link"]/resourceRef/@href');
    		$image->link ($link) ;
    		
    		my ($description) = $xtmp->find ('/topic[instanceOf/@href = "#channel-image"]/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceData/text()');
    		$image->description ($description) ;
		
		my ($width) = $xtmp->find ('/association
					  [instanceOf/@href = "is-width-property-of"]
					  [member/topicRef/@href = "#tmss_image_ontology"]
					  /member    
					    [roleSpec/topicRef/@href = "#value"]
					      /topicRef/@href');
					     

		my ($height) = $xtmp->find ('/association
					  [instanceOf/@href = "is-height-property-of"]
					  [member/topicRef/@href = "#tmss_image_ontology"]
					  /member    
					    [roleSpec/topicRef/@href = "#value"]
					      /topicRef/@href');
		
					     
		$height=~ s/#//;
		$width =~ s/#//;


    		$image->width ( $width ) ;
    		$image->height ($height) ;
    		
    		use Data::Dumper;
    		
    		foreach my $ontology (@ontologies) {
    		        
			my @assocs = $xtmp->find ('association
			                             [/member
			                                [/roleSpec/topicRef/@href = "#ontology"]
			                                [/topicRef/@href = "#'.$ontology.'"]
			                             ]
			            		     [/member
			            		       [/roleSpec/topicRef/@href = "#holder"]
			                               [/topicRef/@href = "#'.$topicID.'"]
			                             ]');

			
			foreach my $assoc (@assocs) {
				
				#warn Dumper $assoc;
				
				my ($field) = $xtmp->find ('member[/roleSpec/topicRef/@href = "#property"]/topicRef/@href', $assoc);
				my ($value) = $xtmp->find ('member[/roleSpec/topicRef/@href = "#value"]/topicRef/@href', $assoc);

				$field =~ s/#//;
				$value =~ s/#//;
				
				$image->property(
					prefix => $ontology,
					field  => $field,
					value  => $value
			        );
					

				
			}
    			
    		}
    		
    		
    		return $image;
    		
    		
  	}

}


## ONTOLOGY ##

#key (channel-ontology)
#bn: key
#oc: value

#(channel-ontology)
#ontology: key
#channel: channel

sub ontology {
  my $self = shift;

  my $prefix = shift;
  my $value = shift;
  
  my $xtmp = new XTM::Path (default => $self->{xtm});
  my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
  my $chanID = $chan->id();
    
  if (defined $value) {

  	if (defined $prefix) {

  		if ($value eq '') {
    			
    			# Delete assoc with ontology role and key ref

    			
#(is-date-property-of)
#value: 0207070336EDT
#property: date
#ontology: dc
#holder: item01

# RegExp?
# [instanceOf/@href = /#is-.*?-property-of/]

			my @assocs = $xtmp->find ('/association
							[member/roleSpec/topicRef/@href = "#value"]
			 				[member/roleSpec/topicRef/@href = "#property"]
							[member
							  [roleSpec/topicRef/@href = "#ontology"]
							  [topicRef/@href = "#'.$prefix.'"]
							]
							[member/roleSpec/topicRef/@href = "#holder"]');
							
			foreach my $a (@assocs) {
		#		warn "Removing ".$a->id()."\n";
				$self->{xtm}->remove( $a->id() );
			}
			
			my @topics = $xtmp->find ('/topic[@id = "'.$prefix.'"]');
			
			foreach my $t (@topics) {
		#		warn "Removing ".$t->id()."\n";
				$self->{xtm}->remove( $t->id() );
			}
			
	
    			
    		} else {
	  		
	  		# add topic with ontology (see top) and association	  		
	  		
 		
#dc (channel-ontology)
#oc: http://purl.org/dc/elements/1.1/

#missing topicID
		
			my $t = $xtmp->create ('topic[@id = "'.$prefix.'"]
			                             [instanceOf/topicRef/@href = "#channel-ontology"]
			                             [occurrence
			                               [resourceRef/@href = "'.$value.'"]
			                               [scope/topicRef/@href = "'.$self->{scope}.'"]
			                             ]
			                             [baseName
			                               [scope/topicRef/@href = "'.$self->{scope}.'"]
			                               [baseNameString
			                                 [text() = "'.$prefix.'"]
			                               ]
			                             ]');
			$self->{xtm}->add($t);
			my $topicID = $t->id();
#(is-associated-with)
#ontology: dc
#channel: Channel 		
  		
		        $a = $xtmp->create ('association
		        				[instanceOf/topicRef/@href = "#is-associated-with"]
		        				[member
        	                                    	  [roleSpec/topicRef/@href = "#ontology"]
                	                            	  [topicRef/@href = "#'.$topicID.'"]
                        	                    	][member
                                	                  [roleSpec/topicRef/@href = "#channel"]
                                        	    	  [topicRef/@href = "#'.$chanID.'"]
                                            		]');
 			$self->{xtm}->add($a);
 		}
 	} 
 		
 		
  } else {

	if (defined $prefix) {
  		#return value of ontology
          	
          	my ($t) = $xtmp->find ('/topic[@id = "'.$prefix.'"]/occurrence/resourceRef/@href');
          	return $t;
          	
  		
	} else {
		# return hash of ontologies
		
#dc (channel-ontology)
#oc: http://purl.org/dc/elements/1.1/
                my @t = $xtmp->find ('/topic[instanceOf/topicRef/@href = "#channel-ontology"]');
                use Data::Dumper;
                #warn Dumper @t;
                
                my %bigbadhash;
                foreach my $element (@t) {
                
                	my $prefix = $element->id();
                	my ($value) = $xtmp->find('/occurrence/resourceRef/@href' ,$element);
                	
                #	warn "Adding $prefix - $value";
                	$bigbadhash{$prefix} = $value;
                	
                     
                }
		
		return %bigbadhash;
	}
	
  }

}


## ITEMS


#item01 (channel-item)
#bn: title
#oc: link
#in: description
#
#(belongs-to)
#channel: channelID
#item: topicID

sub __getFirstAvailableItem {
	my $self = shift;
        
        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});
	my @items = $xtmp->find ('/topic[instanceOf/topicRef/@href = "#channel-item"]/@id');

	my @sorted = sort { $a cmp $b } @items;

	my $elements = @sorted;
	my $x=0;
	for ($x=0; $x<$elements; $x++) {
		my $item = $sorted[$x];
		$item =~ /^item([0-9]*)$/;
		if ($1 != $x) {
			# We got an available number, $x. 
			my $a = sprintf("%02d",$x);
			return "item".$a;
		}		
	}
	my $a = sprintf("%02d",$x);
	return "item".$a;
}


sub addItem {

	my $self = shift;
        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});
	my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
	my $channelID = $chan->id();


	while (my $item = shift) {

		# create topic

#item01 (channel-item)
#bn:Hunt begins for Afghan assassins
#oc: http://www.cnn.com/2002/WORLD/asiapcf/central/07/07/afghan.assassination/index.html
#in: Afghanistan's transitional President Hamid Karzai has set up a five-member delegation to investigate the assassination of one of the country's three vice presidents.
		
		#get available item name
		my $topicname = $self->__getFirstAvailableItem();
		
		my $topic = $xtmp->create ('/topic
		     [instanceOf/topicRef/@href = "#channel-item"][/@id = "'.$topicname.'"]');
		
		if (defined $item->title()) {
			my $title = $item->title();
			$title=~ s/\"/'/g;
			$topic->add__s( $xtmp->create ('baseName[scope/topicRef/@href = "'.$self->{scope}.'"]/baseNameString[text() = "'.$title.'"]') );
		
		}     
		     
		if (defined $item->link()) {
			$topic->add__s($xtmp->create ('occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceRef[@href = "'.$item->link().'"]') );
		}
		
		if (defined $item->description()) {
			$topic->add__s($xtmp->create ('occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceData[text() = "'.$item->description().'"]') );
		
		}
		
		
		my $topicID = $topic->id();
		
		# associate topic
				
#(belongs-to)
#item: item01
#channel: Channel		

	        my $a = $xtmp->create ('association
				[instanceOf/topicRef/@href = "#belongs-to"]
				[member
                            	  [roleSpec/topicRef/@href = "#item"]
                            	  [topicRef/@href = "#'.$topicID.'"]
	                    	][member
        	                  [roleSpec/topicRef/@href = "#channel"]
                	    	  [topicRef/@href = "#'.$channelID.'"]
                    		]');
		
		$self->{xtm}->add($topic);
		$self->{xtm}->add($a);
		
		
		# add properties

		my @ontologies = $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"]/@id');
		
       		my %hash = $self->ontology();
       		while (my ($module, $ignore) = each %hash ) {
       			
       			if (grep {$_ eq $module} @ontologies) {
       			
       				my %properties = $item->property(prefix =>"$module");
     			
	     			while (my ($field, $value) = each %properties ) {
					my $a = $self->createPropertyAssoc ($value, $field, $module, $topicID);
				        $self->{xtm}->add($a);
       				
       				}
       			} else {
       				warn "Ontology for $module does not exist. Data for $module will be ignored.\n";
       			}
       		}
       		
       	}


 	
}


sub getItems {
	
	my $self = shift;
	my @items;	
		# get assocs with item
		# get topic association
		# get values from properties
		
		# create items

        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});

	# Get list of item topics sorted
	my @itemlist = $xtmp->find ('/topic[instanceOf/topicRef/@href = "#channel-item"]/@id');
	my @sorted = sort { $a cmp $b } @itemlist;

        my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');


	# 1. get (channel-item)
	
	# 2. for each populate and add to list
	
	my @topics = $xtmp->find ('/topic[instanceOf/@href = "#channel-item"]');
	my @ontologies = $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"]/@id');
	
	foreach my $itemID (@sorted) {
		my ($topic) = $xtmp->find ('/topic[instanceOf/topicRef/@href = "#channel-item"][@id = "'.$itemID.'"]');
	
		my $item = new Syndicate::Channel::item();
		
		my ($title) = $xtmp->find ('/baseName[scope/topicRef/@href = "'.$self->{scope}.'"]/text()', $topic);
		my ($link) = $xtmp->find ('/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceRef/@href', $topic);	
		my ($description) = $xtmp->find ('/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceData/text()', $topic);
		$item->title($title);
		$item->link($link);
		$item->description($description);
		
		#properties1
		
		foreach my $ontology (@ontologies) {
    			
			my @assocs = $xtmp->find ('association
			            [member
			                    [roleSpec/topicRef/@href = "#ontology"]
			                    [/topicRef/@href = "#'.$ontology.'"]
			            ]
			            [member
			                    [/roleSpec/topicRef/@href = "#holder"]
			                    [/topicRef/@href = "#'.$topic->id().'"]
			            ]');
			
			foreach my $assoc (@assocs) {


				my ($field) = $xtmp->find ('member[/roleSpec/topicRef/@href = "#property"]/topicRef/@href', $assoc);
				my ($value) = $xtmp->find ('member[/roleSpec/topicRef/@href = "#value"]/topicRef/@href', $assoc);
				
				$field =~ s/^#//;
				$value =~ s/^#//;
				
				$item->property(
					prefix => $ontology,
					field  => $field,
					value  => $value
			        );
					

				
		
			}
		}
	
	push(@items,$item);
	
	}
 	return @items;
 
 
}	


sub removeItem {
	my $self = shift;
	my $remove_item = shift;
	
	# quick and dirty implementation
	# deletes items with matching title
	
	my $title = $remove_item->title();

        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});
        my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');

	
	my @topics = $xtmp->find ('/topic
		[instanceOf/@href = "#channel-item"]
		[baseName
		  [scope/topicRef/@href = "'.$self->{scope}.'"]
		/text() = "'.$title.'"]');
	
	foreach my $t (@topics) {
		my $topicID = $t->id() ;
		$self->{xtm}->remove( $topicID);
		
		# delete the associatios for this topic aswell

		my @a1 = $xtmp->find ('association[/member
		 	[topicRef/@href = "'.$topicID.'"]
		 	[roleSpec/topicRef/@href = "holder"]
		      ]');
		      
		my @a2 = $xtmp->find ('association[instanceOf/topicRef/@href = "#belongs-to"]
		      [/member
		 	[topicRef/@href = "'.$topicID.'"]
		 	[roleSpec/topicRef/@href = "item"]
		      ]');
		      
		foreach my $a (@a1) {
			$self->{xtm}->remove( $a->id() );
		}
					
		foreach my $a (@a2) {
			$self->{xtm}->remove( $a->id() );
		}
	}	
			
	
}
	

sub delOntology {

	my $self = shift;
	my $prefix = shift;

        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});
        my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');


#dc (channel-ontology)
#oc: http://purl.org/dc/elements/1.1/

# Remove the ontology topic    			
	my ($topic1) = $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"][@id = "'.$prefix.'"]');
	

#(is-associated-with)
#ontology: dc
#channel: CNNchannel

	my @assocs = $xtmp->find ('/association
					[instanceOf/@href = "#is-associated-with"]
					[member/roleSpec/topicRef/@href = "#ontology"]
	  			        [member/topicRef/@href = "#'.$prefix.'"]
	 				[member/roleSpec/topicRef/@href = "#channel"]
					[member/topicRef/@href = "#'.$topic1->id().'"]');
	
	
# Wouldn't something like this be better?
#	[member
#	  [/roleSpec/topicRef/@href = "#ontology"]
#         [/topicRef/@href = "#'.$key.'"]
#       ]
# doesn't seem to work though

	foreach my $a (@assocs) {
		$self->{xtm}->remove( $a->id() );
	}
	
	$self->{xtm}->remove( $topic1->id() );

#(is-date-property-of)
#value: 0207070336EDT
#property: date
#ontology: dc
#holder: item01

# RegExp?
# [instanceOf/@href = /#is-.*?-property-of/]

	@assocs = $xtmp->find ('/association
					[member/roleSpec/topicRef/@href = "#value"]
	 				[member/roleSpec/topicRef/@href = "#property"]
					[member/roleSpec/topicRef/@href = "#ontology"]
					[member/topicRef/@href = "#'.$prefix.'"]
					[member/roleSpec/topicRef/@href = "#holder"]');

# This is a bit scetchy, key should be linked to ontology    			

	foreach my $a (@assocs) {
		$self->{xtm}->remove( $a->id() );
	}
				

# Does not delete topic associated with a property as it might be used by something else
}

sub property {
  my $self = shift;
  my %params = @_;	

  my $prefix = $params{prefix};
  my $field = $params{field};
  my $value = $params{value};

        use XTM::Path;
        my $xtmp = new XTM::Path (default => $self->{xtm});
        my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');


  if (defined $prefix) {
  	if (defined $field) {
  	
  		if (defined $value) {
  	
		  	if ($value eq '') {
  				# remove property
  				
  				my @assocs = $xtmp->find ('/association
					[member/roleSpec/topicRef/@href = "#value"]
	 				[member/roleSpec/topicRef/@href = "#property"]
	 				[member/topicRef/@href = "#'.$field.'"]
					[member/roleSpec/topicRef/@href = "#ontology"]
					[member/topicRef/@href = "#'.$prefix.'"]
					[member/roleSpec/topicRef/@href = "#holder"]');

				foreach my $a (@assocs) {
					$self->{xtm}->remove( $a->id() );
				}
						
  				
		
				
  			} else {
								
				
				#check if ontology exists
				
				if (not defined $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"][@id = "'.$prefix.'"]') ) {
					warn "Add the $prefix ontology to the channel first\n";
					return;
				}
				
				#add property		
				
				
				my $a = $self->createPropertyAssoc ($value, $field, $prefix, $chan->id() );
			        $self->{xtm}->add($a);
				
				
  			}
  		} else {
		  	# return value of prefix and field
			
			my ($value) = $xtmp->find ('association[member
								[roleSpec/topicRef/@href = "#ontology"]
								[topicRef/@href = "#'.$prefix.'"]
							     ]
							     [member
								[roleSpec/topicRef/@href = "#holder"]
								[topicRef/@href = "#'.$chan->id().'"]
						             ]
							     [member
								[roleSpec/topicRef/@href = "#property"]
								[topicRef/@href = "#'.$field.'"]
						             ]
						             /member
						               [roleSpec/topicRef/@href = "#value"]
						               /topicRef/@href');
						              
			if (defined $value) {
				$value =~ s/^#//;
				return $value;
			} else {
				return undef;
			}
			
			  	
  		}
  	} else {
  		
  		#return hash of fields and values for prefix

                my ($t) = $xtmp->find ('topic[instanceOf/@href = "#channel-ontology"][@id = "'.$prefix.'"]');
                my $ontologyID = $t->id();
		use Data::Dumper;
		
		my @assocs = $xtmp->find ('association
		  [member
		    [roleSpec/topicRef/@href = "#ontology"]
	 	    [topicRef/@href = "#'.$ontologyID.'"]
	 	  ]
		  [member
		    [roleSpec/topicRef/@href = "#holder"]
	 	    [topicRef/@href = "#'.$chan->id().'"]
	 	  ]');
		
		my %hashy;                

		foreach my $a (@assocs) {
		
			my ($property) = $xtmp->find('/member[/roleSpec/topicRef/@href = "#property"]/topicRef/@href' ,$a);
			my ($value) = $xtmp->find('/member[/roleSpec/topicRef/@href = "#value"]/topicRef/@href' ,$a);
			
			$property =~ s/^#//;
			$value    =~ s/^#//;
		
			if ($value ne "") {
				$hashy{$property} = $value;
			}
		}
		
		return %hashy;

  	}
  } else {
  	# return whole list
        
        
	my @ontologies = $xtmp->find ('/topic[instanceOf/@href = "#channel-ontology"]/@id', $chan);
	
	my @list;
	foreach my $ontology (@ontologies) {
		
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
		
	# delete property
	
	my %hashy = $self->property(prefix => "$prefix");
	
	while (my ($key, $value) = each %hashy ) {
		$self->property(field => "$key", value  => '', prefix => "$prefix");
	}
	
}  



sub toString {
  my $self = shift;
  my %options = @_;
  my $type = $options{type};
  
  if ($type eq 'xml') {
    die "Syndicate::Channel: XML not Implemented";
  } elsif ($type eq 'tmss' or $type eq 'atm') {
    use XTM::Path;
    my $xtmp = new XTM::Path (default => $self->{xtm});
    my ($chan) = $xtmp->find ('/topic[instanceOf/@href = "#channel"]');
		
    my $atmString;

use Data::Dumper;
warn time." in toString".Dumper $self->{xtm};
		
    my @topics = $xtmp->find ('/topic');
    foreach my $topic (@topics) {
			# ID (instancemy)
			my $id = $topic->id();
			my ($instance) = $xtmp->find ('instanceOf/@href', $topic);
			$instance =~ s/#//;
			
			if ($instance eq "http://www.topicmaps.org/xtm/1.0/psi-topic") { next; }
			# bn : basename
			my ($basename) = $xtmp->find ('/baseName[scope/topicRef/@href = "'.$self->{scope}.'"]/text()', $topic);
			
			
			
			# oc (type) : occurrence
			my @ocrs = $xtmp->find ('/occurrence[resourceRef/@href][scope/topicRef/@href = "'.$self->{scope}.'"]', $topic);
			
			my @occurrences;
			foreach my $occurrence (@ocrs) {
				my ($type) = $xtmp->find ('/instanceOf/topicRef/@href', $occurrence);
				my ($value) = $xtmp->find ('/resourceRef/@href', $occurrence);
				$type  =~ s/^#//;
				$value =~ s/^#//;
				
				push (@occurrences, [$type, $value]);
			}
			
			# in: inline
			my ($inline) = my ($occurrence) = $xtmp->find ('/occurrence[scope/topicRef/@href = "'.$self->{scope}.'"]/resourceData/text()', $topic);
			
			
			## Now for the actuall creation ## 
			my $topicString;
			
			$topicString = $topicString."$id ($instance)\n";
			
			if (defined $basename) {
				$topicString = $topicString."bn: $basename\n";
			}
			
			
			
			foreach my $oc (@occurrences) {
# rho: this looks strange, needs fixing				
				if (defined $oc->[0] && $oc->[0] ne "http://www.topicmaps.org/xtm/1.0/#psi-occurrence") {
					$topicString = $topicString."oc ($oc->[0]): $oc->[1]\n";
				} else {
					$topicString = $topicString."oc: $oc->[1]\n";
				}
			}
			
			if (defined $inline) {
				 $topicString = $topicString."in: $inline\n";
			}
			
			$topicString =$topicString."\n";
		
			$atmString= $atmString.$topicString;
		}			
		
		
		my @assocs= $xtmp->find ('/association');
		
		foreach my $assoc (@assocs) {
			
			my $assocString;
			
			my ($instance) = $xtmp->find ('instanceOf/topicRef/@href', $assoc);
			$instance =~ s/^#//;
			
			$assocString = $assocString."($instance)\n";
			my @members = $xtmp->find ('member', $assoc);
		
			foreach my $member (@members) {
				my ($role)  = $xtmp->find ('roleSpec/topicRef/@href', $member);
				my ($value) = $xtmp->find ('topicRef/@href', $member);
				$role =~ s/^#//;
				$value =~ s/^#//;
				$assocString = $assocString."$role: $value\n";
			}
			
			$assocString = $assocString."\n";
			
			$atmString = $atmString.$assocString;
		}		
			 
warn time." end of toString";
		return $atmString;
	}


}


sub createPropertyAssoc {	        
	my $self     = shift;
	my $valium    = shift;
	my $property = shift;
	my $ontology = shift;
	my $holder   = shift;

	
	use XTM::Path;
   	my $xtmp = new XTM::Path (default => $self->{xtm});
    	
    		
        my $a = $xtmp->create ('association
				 [instanceOf/topicRef/@href = "is-'.$property.'-property-of"]
				 [member
				   [roleSpec/topicRef/@href = "#value"]
				   [topicRef/@href = "#'.$valium.'"]
				 ]
				 [member
				   [roleSpec/topicRef/@href = "#property"]
				   [topicRef/@href = "#'.$property.'"]
				 ]
				 [member
				   [roleSpec/topicRef/@href = "#ontology"]
				   [topicRef/@href = "#'.$ontology.'"]
				 ]
				 [member
				   [roleSpec/topicRef/@href = "#holder"]
				   [topicRef/@href = "#'.$holder.'"]
				 ]');
	return $a;
}

=pod

=back

=cut


1;

__END__

require 't/propertytester.pl';

sub genericTest {
	my $format = shift;
  
	use Syndicate::Channel;
	my $chan = new Syndicate::Channel (format => $format);
	  
	if ($format eq 'none' or $format eq 'generic') {
		is (ref ($chan), 'Syndicate::Channel::Generic', 'Creation of $format channel object worked');
	}
	if ($format eq 'rss' ) {
	  	is (ref ($chan), 'Syndicate::Channel::RSS', 'Creation of $format channel object worked');
	}
	if ($format eq "tmss") {
	  	is (ref ($chan), 'Syndicate::Channel::TMSS', 'Creation of $format channel object worked');
	}
	
	$chan->title("my $format title");
	is ($chan->title(), "my $format title", "Title method works ($format)");
	  
	$chan->description("my $format description");
	is ($chan->description(), "my $format description", "Description method works ($format)");
	 
	$chan->link("http://my.$format.link/dotocm");
	is ($chan->link(), "http://my.$format.link/dotocm", "Link method works ($format)");
	
	
	#ontology
	$chan->ontology('bc' => "http://www.$format.xom");
	$chan->ontology('exx' => "http://exx.$format.xom");  
	  
	is ($chan->ontology('bc'), "http://www.$format.xom", "Ontology 1 set ($format)");
	is ($chan->ontology('exx'), "http://exx.$format.xom", "Ontology 2 set ($format)");
	
	$chan->ontology('bc' => '');
	
	is ($chan->ontology('bc'), undef, "Ontology 1 removed ($format)");
	is ($chan->ontology('exx'), "http://exx.$format.xom", "Ontology 2 still there ($format)");
	  
	my %onhash = $chan->ontology();
	is ($onhash{exx}, "http://exx.$format.xom", "Ontology hash works ($format)");
	  
	#properties
	$chan->ontology('dc' => "http://exxsomethingom");  
	$chan->ontology('syn' => "http://exxsomethingom.more"); 
	
	propertytester($chan);
	 
	# image 
	  
	my $image = new Syndicate::Channel::image();
	$image->title("my $format image title");
	$image->url("my $format image url");
	$image->link("my $format image link");
	$image->description("my $format image description");
	$image->width("my $format image width");
	$image->height("my $format image height");
	  
	$image->property (prefix => 'dc', field => 'author', 'value' => 'jan');
	$image->property (prefix => 'syn', field => 'year', 'value' => '2002');
	      
	$chan->image($image);
	  
	my $otherimage = $chan->image();
	is ($otherimage->title(), "my $format image title", "Retrieved title match. ($format)");
	is ($otherimage->url(), "my $format image url", "Retrieved url match. ($format)");
	is ($otherimage->link(), "my $format image link", "Retrieved link match. ($format)");
	is ($otherimage->description(), "my $format image description", "Retrieved description match. ($format)");
	is ($otherimage->width(), "my $format image width", "Retrieved width match. ($format)");
	is ($otherimage->height(), "my $format image height", "Retrieved height match. ($format)");
	  
	is ($otherimage->property (prefix => 'syn', field => 'year'), "2002", "Property retrival works");
	  
	my %myhash = $otherimage->property (prefix => 'dc') ;
	is (%myhash->{author}, "jan", "Hash return works");
	  
	  
	# That leaves the items...
	# Lets first deal with one.
	  
	my $item = new Syndicate::Channel::item();
	$item->title("my item $format title");
	$item->link("my item $format link");
	$item->description("my item $format description");
	  
	$item->property (prefix => 'dc', field => 'author', 'value' => 'jan');
	$item->property (prefix => 'syn', field => 'expires', 'value' => '24');
	
	$chan->addItem($item);
	  
	my ($otheritem) = $chan->getItems();
	    
	is ($otheritem->title(), "my item $format title", "Item title preserved ($format)");    
	is ($otheritem->link(), "my item $format link", "Item link preserved ($format)");    
	is ($otheritem->description(), "my item $format description", "Item description preserved ($format)");    
	    
	is ($otheritem->property (prefix => 'dc', field => 'author'), "jan", "Property 1 works");
	
	my %myhash2 = $otheritem->property (prefix => 'syn') ;
	
	is (%myhash2->{expires}, "24", "Hash return works");
	
	# delete all existing items
	  
	my @itemlist = $chan->getItems();
	foreach my $a_item (@itemlist) {
	  $chan->removeItem($a_item);
	}
	
	my $num = $chan->getItems();
	is ($num, 0, "items removed properly");
	
	# and now multiple...
	
	
	for ($x = 0;$x<5;$x++) {
	  my $newitem = new Syndicate::Channel::item();
	
	  $newitem->title("my item $format - $x title");
	  $newitem->description($x);
	    
	  $chan->addItem($newitem);
	}
	  
	my @itemlist2 = $chan->getItems();

	my $x = 0;
	foreach my $a_item (@itemlist2) {
	    
	  is ($a_item->description(), $x, "item $x added properly");
	  $x += 1;
	}
	  
	# removing number 3
	 
	my $item3 = $itemlist2[3];
	$chan->removeItem($item3);
	
	
	# checking if its gone and the rest is still there
	  
	my @items = $chan->getItems();
	my $found = "false";
	for ($x = 0;$x<4;$x++) {
	  if ($items[$x]->description() == 3) {
	  	$found = "true";
	  }
	}
	  
	is ($found, "false", "Item 3 was removed from list ($format)");
	  
	my $y = 0;
	foreach my $item (@items) {
	  if ($y == 3) {
	    $y++;
	  }
	  is ($item->description(), $y, "item $x is still there");
	  $y++;
	}
	    
}  

1;
sub propertytester {
	
  my $object = shift;
  	
  $object->property (prefix => 'dc', field => 'author', 'value' => 'jan');
  $object->property (prefix => 'dc', field => 'year', 'value' => '2002');
  $object->property (prefix => 'syn', field => 'expires', 'value' => '24');
  
  
  is ($object->property (prefix => 'dc', field => 'author'), "jan", "Property 1 works");
  is ($object->property (prefix => 'dc', field => 'year'), "2002", "Property 2 works");
  is ($object->property (prefix => 'syn', field => 'expires'), "24", "Property 3 works");
  
  
  $object->property (prefix => 'dc', field => 'author', 'value' => '');
  
  is ($object->property (prefix => 'dc', field => 'author'), undef, "Property 1 removed correctly");
  is ($object->property (prefix => 'dc', field => 'year'), "2002", "Property 2 still works");
  is ($object->property (prefix => 'syn', field => 'expires'), "24", "Property 3 still works");
  
  $object->delProperty (prefix => 'syn');
  
  is ($object->property (prefix => 'syn', field => 'expires'), undef, "syn modules removed");
  is ($object->property (prefix => 'dc', field => 'year'), "2002", "Property 2 still works");
    
  my %myhash = $object->property (prefix => 'dc') ;
  is (%myhash->{year}, "2002", "Hash return works");
  
}

1;

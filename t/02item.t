use strict;
use Test::More;
BEGIN { plan tests => 14 }

require 't/propertytester.pl';

require_ok( 'Syndicate::Channel::item' );
my $item = new Syndicate::Channel::item();
is (ref ($item), 'Syndicate::Channel::item', 'item object created');

$item->title("my item title");
is ($item->title(), "my item title", "item title method works");

$item->link("my item link");
is ($item->link(), "my item link", "item link method works");

$item->description("my item description");
is ($item->description(), "my item description", "item description method works");

propertytester ($item);

1;

use strict;
use Test::More;
BEGIN { plan tests => 17 }

require 't/propertytester.pl';

require_ok( 'Syndicate::Channel::image' );
my $image = new Syndicate::Channel::image();

is (ref ($image), 'Syndicate::Channel::image', 'image object created');

$image->title("my image title");
is ($image->title(), "my image title", "Image title method works");

$image->url("my image url");
is ($image->url(), "my image url", "Image url method works");

$image->link("my image link");
is ($image->link(), "my image link", "Image link method works");

$image->width("my image width");
is ($image->width(), "my image width", "Image width method works");

$image->height("my image height");
is ($image->height(), "my image height", "Image height method works");

$image->description("my image description");
is ($image->description(), "my image description", "Image description method works");

propertytester ($image);

1;

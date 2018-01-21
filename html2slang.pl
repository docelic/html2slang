# Tool to convert HTML to slang.
#
# It might not cover absolutely all edge cases, but does pretty well and
# should get you in a good position.
#
# Primary use case is converting HTML templates into much nicer and more
# efficient slang syntax.
#
# Various methods of running it:
#   perl html2slang.pl file1.html file2.html
#   cat file1.html | perl html2slang.pl
#   perl html2slang.pl < file2.html
#
# Output is always printed to STDOUT. Redirect to where desired.
#
# Author: Davor Ocelic <docelic@spinlocksolutions.com>
# License: MIT

# TODO:
# - Support for preformatted tags where whitespace is significant

use strict;
our( $indent, @noncontainer, %state, %options);
use subs qw/flush clear_state/;

# Initialize basic variables/values
$indent = 0;
@noncontainer = qw/meta link br hr img input !doctype/;
clear_state;

# Load all HTML text into $_
$_= join '', <>;

# Remove all whitespace that may be at beginning of line
s/^\s+//gm;
# Insert newline in front of every (except first) "<" character
# Insert newline after every ">". Don't care about excessive space, will be removed later
s/(?<!^)</\n</gm;
s/>/>\n/gm;

# Split such string (containing newlines) into array of individual lines
my @lines= split/\n/, $_;
@lines= grep {/\S/} @lines;
@lines= grep {!/^<!/} @lines;
# Remove all whitespace at end of each line
s/\s+$//s for @lines;

#die join "\n", @lines;

# Any tag that spans multiple lines, pull up into a single line
for( my $i = 0; $i< @lines; $i++) {
  local $_= $lines[$i];
  while( /^</ and !/>$/) {
    my $l= splice( @lines, $i+1, 1);
    #$l=~ s/^\s+//;
    $_= $lines[$i].= " $l";
  }
}
# Ensure that every line again ends with \n
#@lines= map { $_=~ /\n$/ ? $_ : "$_\n" } @lines;
chomp for @lines;

for( @lines) {
  my $line= $_;

  next unless /\S/;
  my $container= !s/\/>/>/;

  # At this point, we know that every line will either begin with "<", or if not, then
  # it is a text and:
  # If last seen tag was a container tag, it is part of it content.
  # If it wasn't a container tag, it is free form text that is not part of any <p> or <span>

  # So:

  # If opening tag
  if(/^<([a-zA-Z\@:]\S*)(.*)/) {
    my( $tag, $body)= ( $1, $2);

    # Remove ending ">"
    if( $tag=~ s/\s*>\s*$// or $body=~ s/\s*>\s*$//){
    }

    $container&&= (grep $_ eq $tag, @noncontainer) ? 0 : 1;

    ( my $tagname= $tag); #=~ s/>//; # Remove ">" just in case it matched

    # Dump any existing state
    flush;

    while( $body=~ s/class=(['"])\s*(.*?)\s*\1\s*//) {
      my @classes= split /\s+/, $2;
      push @{$state{classes}}, @classes;
    }
    while( $body=~ s/id=(['"])\s*(.*?)\s*\1\s*//) {
      my @ids= split /\s+/, $2;
      push @{$state{ids}}, @ids;
    }

    #$body=~ s/^\s+//;
    $body=~ s/\s+$//;

    # Begin next tag
    if( $container) {
      $state{tag}= $tagname;
      $state{container} = $container;
      $state{body} = $body;
      $state{indent} = $indent;
      $indent++;
      #$indent++;
      #flush;
    } else {
      # Non-container, a pass-thru element
      flush { tag => $tag , body => $body, classes => $state{classes}, ids => $state{ids}}
    }

  # If closing tag
  } elsif(/^<\/(\S+)/) {
    $indent--; # if $state{container};
    ( my $tagname= $1)=~ s/>//; # Remove ">" just in case it matched
    # We generally just decrease indent on those, and also we'll just do a
    # quick verification that tag must have been open
    if( $state{tag} and ($tagname ne $state{tag})){
      warn "Open tag is '$state{tag}', but I see closing tag '$tagname'; reporting and ignoring.\n";
    }
    flush;

  # If text that needs to be printed
  } else {
    # This means it is not a tag but content. If previous tag was container,
    # this is part of his content. If it wasn't, it's just text
    s/^\s*/ /;
    #s/\s+$//;
    if( $state{container}) {
      s/\s+$//;
      $state{body}.= $_;
      $_ = "";
    } else {
      flush { tag => "" , body => $_ }
    }
  }
}

# Once again remove all empty lines
@lines= grep {/\S/} @lines;

#print @lines;
flush;

 exit 0;

sub flush {
  my $from = @_ ? $_[0] : \%state;
    if( $$from{tag}) {
      print qq{${\( '  ' x $state{indent})}${\( $$from{tag} ? ($$from{tag} . ids($from). classes($from)): '' )}$$from{body}\n};
      clear_state;
    }
}
sub classes {
  my $from = @_ ? $_[0] : \%state;
  return "" unless $$from{classes} && @{$$from{classes}};
  return ".". join ".", @{$$from{classes}};
}
sub ids {
  my $from = @_ ? $_[0] : \%state;
  return "" unless $$from{ids} && @{$$from{ids}};
  return "#". join "#", @{$$from{ids}};
}
sub clear_state {
  %state= ( tag => "", container => 0, body => "", classes => [], ids => [], indent => $indent);
}


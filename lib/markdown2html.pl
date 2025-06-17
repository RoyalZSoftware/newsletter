#!/usr/bin/perl
use strict;
use warnings;

my $in_frontmatter = 0;

while (<>) {
    chomp;

    # Frontmatter ignorieren
    if (/^---\s*$/) {
        $in_frontmatter = !$in_frontmatter;
        next;
    }
    next if $in_frontmatter;

    # Überschriften
    if (/^###\s+(.*)/) {
        print "<h3>$1</h3>\n";
        next;
    }
    if (/^##\s+(.*)/) {
        print "<h2>$1</h2>\n";
        next;
    }
    if (/^#\s+(.*)/) {
        print "<h1>$1</h1>\n";
        next;
    }
    if (/^\s*$/) {
        print "<br>\n";
        next;
    }

    my $line = $_;

    # Links [text](url)
    $line =~ s/\[([^\]]+)\]\((https?:\/\/[^\)]+)\)/<a href="$2">$1<\/a>/g;

    # Fett **text**
    $line =~ s/\*\*([^\*]+)\*\*/<strong>$1<\/strong>/g;

    # Kursiv *text*
    $line =~ s/\*([^\*]+)\*/<em>$1<\/em>/g;

    print "<p>$line</p>\n";
}

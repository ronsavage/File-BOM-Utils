#!/usr/bin/env perl
#
# Name:
#	update.version.pl.
#
# Purpose:
#	Update the version number in all *.pm files in a dir structure.
#
# Parameters:
#	o Version number
#	o Starting directory

use strict;
use warnings;

use File::Find;
use Getopt::Long;
use Pod::Usage;

my($count, $directory, $version);

# -----------------------------------------------

sub found
{
	return if ($File::Find::name !~ /\.pm$/);

	open(INX, $_) || die("Can't open($File::Find::name): $!");
	my(@line) = <INX>;
	close INX;

	my($found) = 0;

	my($line);

	# This code does not handle the case where the VERSION line is missing.
	# Also, if there are multiple packages in a file, it assumes they either
	# all have a version number, or all don't have one.

	for (@line)
	{
		if (/^(our\s+\$VERSION\s+=\s+')(.+)('.+)$/)
		{
			$found	= 1;
			$_		= "$1$version$3\n";
		}
		elsif (/^(\$(?:\w+::){1,}VERSION\s*=\s*')(?:\d.+)(';)$/)
		{
			$found	= 1;
			$_		= "$1$version$2\n";
		}
	}

	if ($found)
	{
		$count++;

		open(OUT, "> $_") || die("Can't open(> $File::Find::name): $!");
		print OUT @line;
		close OUT;
	}
	elsif ($line[0] !~ /::Schema/)
	{
		print "$File::Find::name. \n";
		print "Error: Version line not found. \n";
	}

}	# End of found.

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'directory=s',
 'help',
 'version=s',
) )
{
	pod2usage(1) if ($option{'help'} || ! ($option{'directory'} && $option{'version'}) );

	$count		= 0;
	$version	= $option{'version'};
	$directory	= $option{'directory'};

	find(\&found, $directory);

	print "$count files' version numbers updated to $version in $directory. \n";

	exit;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

update.version.pl - Update all *.pm files in a directory with a new version number.

=head1 SYNOPSIS

update.version.pl [options]

	Options:
	-directory directoryName
	-help
	-version versionNumber

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -directory directoryName

The directory to process.

=item -help

Print help and exit.

=item -version versionNumber

The version number to process, in 1.00 format.

=back

=cut

#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::BOM::Utils;

use Getopt::Long;

use Pod::Usage;

# ------------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'action=s',
	'bom_type=s',
	'help',
	'input_file=s',
	'output_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit File::BOM::Utils -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

bom.pl - Check, Add and Remove BOMs

=head1 SYNOPSIS

bom.pl.pl [options]

	Options:
	-action   $string
	-bom_type $string
	-help
	-input_file  $file_name
	-output_file $file_name

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -action $string

Specify the action wanted:

=over 4

=item o add

Add the BOM named with the bom_type option to input_file.
Write the result to output_file.

=item o remove

Remove the BOM from the input_file. Write the result to output_file.

=item o test

Report the BOM status of input_file.

=back

Default: ''.

This option is mandatory.

=item -help

Print help and exit.

=item -input_file $file_name

Specify the input file.

Default: ''.

This option is mandatory.

=item -output_file $file_name

Specify the output file.

And yes, it can be the same as the input file, but does not default to the input file.
That would be dangerous.

Default: ''.

=back

=cut

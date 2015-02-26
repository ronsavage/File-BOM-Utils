#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::BOM::CheckAddRemove;

# ------------------------------------------------

my($bom_man)          = File::BOM::CheckAddRemove -> new;
my(@bom_types)        = sort keys %File::BOM::CheckAddRemove::type2bom;
my($types)            = '(BOM types handled: ' . join(', ', @bom_types) . ')';
my($message)          = "Usage: $0 in_file_name out_file_name bom_type $types\n";
my($input_file_name)  = shift || die $message;
my($output_file_name) = shift || die $message;

$bom_man -> report($input_file_name, 'Before removing BOM');
$bom_man -> remove(input_file_name => $input_file_name, output_file_name => $output_file_name);
$bom_man -> report($output_file_name, 'After removing BOM');

# Return 0 for success and 1 for failure.

exit 0;

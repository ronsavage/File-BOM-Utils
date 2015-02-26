#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::BOM::CheckAddRemove;

# ------------------------------------------------

my($bom_man)         = File::BOM::CheckAddRemove -> new;
my(@bom_types)       = sort keys %File::BOM::CheckAddRemove::type2bom;
my($types)           = '(BOM types handled: ' . join(', ', @bom_types) . ')';
my($message)         = "Usage: $0 file_name $types\n";
my($input_file_name) = shift || die $message;

$bom_man -> report($input_file_name, '');

# Return 0 for success and 1 for failure.

exit 0;

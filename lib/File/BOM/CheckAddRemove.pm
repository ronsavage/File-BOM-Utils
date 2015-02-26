package File::BOM::CheckAddRemove;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Fcntl ':flock';

use File::Slurp; # For read_file() and write_file().

use Moo;

use Types::Standard qw/Int ScalarRef Str/;

has bom_type =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has data =>
(
	default  => sub{return \''}, #Use ' in comment for UltraEdit syntax hiliter.
	is       => 'rw',
	isa      => ScalarRef[Str],
	required => 0,
);

has input_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has output_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

# http://search.cpan.org/perldoc?PPI::Token::BOM or String::BOM.

our(%bom2type) =
(
	"\x00\x00\xfe\xff" => 'UTF-32-BE',
	"\xff\xfe\x00\x00" => 'UTF-32-LE',
	"\xfe\xff"         => 'UTF-16-BE',
	"\xff\xfe"         => 'UTF-16-LE',
	"\xef\xbb\xbf"     => 'UTF-8',
);

our(%type2bom) =
(
	'UTF-32-BE' => "\x00\x00\xfe\xff",
	'UTF-32-LE' => "\xff\xfe\x00\x00",
	'UTF-16-BE' => "\xfe\xff",
	'UTF-16-LE' => "\xff\xfe",
	'UTF-8'     => "\xef\xbb\xbf",
);

our $VERSION = '1.00';

# ------------------------------------------------

sub add
{
	my($self, %opt) = @_;

	$self -> read(%opt);
	$self -> bom_type($opt{bom_type})                 if (defined $opt{bom_type});
	$self -> output_file_name($opt{output_file_name}) if (defined $opt{input_file_name});

	my($output_file_name) = $self -> output_file_name;
	my($type)             = $self -> bom_type;

	die "Unknown BOM type: $type\n" if (! $type2bom{$type});

	write_file($output_file_name, {binmode => ':raw'}, $type2bom{$type});
	write_file($output_file_name, {append => 1, binmode => ':raw'}, $self -> data);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of add.

# ------------------------------------------------

sub bom_report
{
	my($self, %opt) = @_;

	$self -> bom_type($opt{bom_type}) if (defined $opt{bom_type});

	my($type) = $self -> bom_type;

	return
	{
		length => length($type2bom{$type}) || 0,
		type   => $type,
	};

} # End of bom_report.

# ------------------------------------------------

sub bom_values
{
	my($self) = @_;

	return sort{4 - length($a) <=> 4 - length($b)} keys %bom2type;

} # End of bom_values;

# ------------------------------------------------

sub file_report
{
	my($self, %opt) = @_;

	$self -> read(%opt);

	my($data)  = ${$self -> data};
	my($type)  = ''; # Sugar: Make $type not null.
	my($value) = ''; # Sugar: Make $value not null.

	my($length);

	# Sort from long to short to avoid false positives.

	for my $key ($self -> bom_values)
	{
		$length = length $key;

		# Warning: Use eq and not ==.

		if (substr($data, 0, $length) eq $key)
		{
			$value                    = $key;
			$type                     = $bom2type{$key};
			substr($data, 0, $length) = '';

			last;
		}
	}

	return
	{
		length  => $length, # Warning. May be junk. Test type first.
		message => $type ? "BOM type $type found" : 'No BOM found',
		type    => $type,
		value   => $value,
	};

} # End of file_report.

# ------------------------------------------------

sub read
{
	my($self, %opt) = @_;

	$self -> input_file_name($opt{input_file_name}) if (defined $opt{input_file_name});
	$self -> data(scalar read_file($self -> input_file_name, bin_mode => ':raw', scalar_ref => 1) );

	# Return 0 for success and 1 for failure.

	return 0;

} # End of read.

# ------------------------------------------------

sub remove
{
	my($self, %opt) = @_;
	my($result)     = $self -> file_report(%opt);

	if ($$result{type} ne '')
	{
		$self -> output_file_name($opt{output_file_name}) if (defined $opt{input_file_name});

		my($output_file_name) = $self -> output_file_name;

		substr(${$self -> data}, 0, $$result{length}) = '';

		write_file($output_file_name, {binmode => ':raw'}, $self -> data);
	}

	# Return 0 for success and 1 for failure.

	return 0;

}  # End of remove.

# ------------------------------------------------

sub report
{
	my($self, $file_name, $heading) = @_;
	$heading    = $heading ? " ($heading)" : '';
	my($result) = $self -> file_report(input_file_name => $file_name);

	print "File report$heading for $file_name: \n";
	print 'Size: ', -s $file_name, " (bytes) \n";

	for my $key (qw/message type/)
	{
		print "$key: $$result{$key}\n";
	}

	print "BOM report: \n";

	if ($$result{type})
	{
		my($stats) = $self -> bom_report(bom_type => $$result{type});

		for my $key (qw/length type/)
		{
			print "$key: $$stats{$key}\n";
		}
	}

} # End of report.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<File::BOM::CheckAddRemove> - Check, Add and Remove BOMs, with file locking

=head1 Synopsis

This is scripts/synopsis.pl:


=head1 Description

L<File::BOM::CheckAddRemove> provides a L<Marpa::R2>-based parser for extracting delimited text
sequences from strings. The text outside and inside the delimiters, and delimiters themselves, are
all stored as nodes in a tree managed by L<Tree>.

Nested strings, with the same or different delimiters, are stored as daughters of the nodes which
hold the delimiters.

This module is a companion to L<Text::Delimited::Marpa>. The differences are discussed in the L</FAQ>
below.

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

See t/utf8.t.

=item o Escaping delimiters within the text

See t/escapes.t.

=item o Options to make nested and/or overlapped delimiters fatal errors

See t/colons.t.

=item o Using delimiters which are part of another delimiter

See t/escapes.t and t/perl.delimiters.

=item o Processing the tree-structured output

See scripts/traverse.pl.

=item o Emulating L<Text::Xslate>'s use of '<:' and ':>

See t/colons.t and t/percents.t.

=item o Implementing a really trivial HTML parser

See t/html.t.

In the same vein, see t/angle.brackets.t, for code where the delimiters are just '<' and '>'.

=item o Handling multiple sets of delimiters

See t/multiple.delimiters.t.

=item o Skipping (leading) characters in the input string

See t/skip.prefix.t.

=item o Implementing hard-to-read text strings as delimiters

See t/silly.delimiters.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<File::BOM::CheckAddRemove> as you would any C<Perl> module:

Run:

	cpanm File::BOM::CheckAddRemove

or run:

	sudo cpan File::BOM::CheckAddRemove

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = File::BOM::CheckAddRemove -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<File::BOM::CheckAddRemove>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text([$stringref])>]):

=over 4

=item o close => $arrayref

An arrayref of strings, each one a closing delimiter.

The # of elements must match the # of elements in the 'open' arrayref.

See the L</FAQ> for details and warnings.

A value for this option is mandatory.

Default: None.

=item o length => $integer

The maximum length of the input string to process.

This parameter works in conjunction with the C<pos> parameter.

C<length> can also be used as a key in the hash passed to L</parse([%hash])>.

See the L</FAQ> for details.

Default: Calls Perl's length() function on the input string.

=item o next_few_limit => $integer

This controls how many characters are printed when displaying 'the next few chars'.

It only affects debug output.

Default: 20.

=item o open => $arrayref

An arrayref of strings, each one an opening delimiter.

The # of elements must match the # of elements in the 'open' arrayref.

See the L</FAQ> for details and warnings.

A value for this option is mandatory.

Default: None.

=item o options => $bit_string

This allows you to turn on various options.

C<options> can also be used as a key in the hash passed to L</parse([%hash])>.

Default: 0 (nothing is fatal).

See the L</FAQ> for details.

=item o pos => $integer

The offset within the input string at which to start processing.

This parameter works in conjunction with the C<length> parameter.

C<pos> can also be used as a key in the hash passed to L</parse([%hash])>.

See the L</FAQ> for details.

Note: The first character in the input string is at pos == 0.

Default: 0.

=item o text => $stringref

This is a reference to the string to be parsed. A stringref is used to avoid copying what could
potentially be a very long string.

C<text> can also be used as a key in the hash passed to L</parse([%hash])>.

Default: \''.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar constructed based on user input.

=head2 close()

Get the arrayref of closing delimiters.

See also L</open()>.

See the L</FAQ> for details and warnings.

'close' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 delimiter_action()

Returns a hashref, where the keys are delimiters and the values are either 'open' or 'close'.

=head2 delimiter_frequency()

Returns a hashref where the keys are opening and closing delimiters, and the values are the # of
times each delimiter appears in the input stream.

The value is incremented for each opening delimiter and decremented for each closing delimiter.

=head2 error_message()

Returns the last error or warning message set.

Error messages always start with 'Error: '. Messages never end with "\n".

Parsing error strings is not a good idea, ever though this module's format for them is fixed.

See L</error_number()>.

=head2 error_number()

Returns the last error or warning number set.

Warnings have values < 0, and errors have values > 0.

If the value is > 0, the message has the prefix 'Error: ', and if the value is < 0, it has the
prefix 'Warning: '. If this is not the case, it's a reportable bug.

Possible values for error_number() and error_message():

=over 4

=item o 0 => ""

This is the default value.

=item o 1/-1 => "Last open delimiter: $lexeme_1. Unexpected closing delimiter: $lexeme_2"

If L</error_number()> returns 1 it's an error, and if it returns -1 it's a warning.

You can set the option C<overlap_is_fatal> to make it fatal.

=item o 2/-2 => "Opened delimiter $lexeme again before closing previous one"

If L</error_number()> returns 2 it's an error, and if it returns -2 it's a warning.

You can set the option C<nesting_is_fatal> to make it fatal.

=item o 3/-3 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 3 it's an error, and if it returns -3 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=item o 4 => "Backslash is forbidden as a delimiter character"

This preempts some types of sabotage.

This message always indicates an error, never a warning.

=item o 5 => "Single-quotes are forbidden in multi-character delimiters"

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message always indicates an error, never a warning.

=item o 6/-6 => "Parse exhausted"

If L</error_number()> returns 6 it's an error, and if it returns -6 it's a warning.

You can set the option C<exhaustion_is_fatal> to make it fatal.

=item o 7 => 'Single-quote is forbidden as an escape character'

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message always indicates an error, never a warning.

=item o 8 => "There must be at least 1 pair of open/close delimiters"

This message always indicates an error, never a warning.

=item o 9 => "The # of open delimiters must match the # of close delimiters"

This message always indicates an error, never a warning.

=item o 10 => "Unexpected event name 'xyz'"

Marpa has triggered an event and it's name is not in the hash of event names derived from the BNF.

This message always indicates an error, never a warning.

=item o 11 => "The code does not handle these events simultaneously: a, b, ..."

The code is written to handle single events at a time, or in rare cases, 2 events at the same time.
But here, multiple events have been triggered and the code cannot handle the given combination.

This message always indicates an error, never a warning.

=back

See L</error_message()>.

=head2 escape_char()

Get the escape char.

=head2 known_events()

Returns a hashref where the keys are event names and the values are 1.

=head2 length([$integer])

Here, the [] indicate an optional parameter.

Get or set the length of the input string to process.

See also the L</FAQ> and L</pos([$integer])>.

'length' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 matching_delimiter()

Returns a hashref where the keys are opening delimiters and the values are the corresponding closing
delimiters.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 next_few_chars($stringref, $offset)

Returns a substring of $s, starting at $offset, for use in debug messages.

See L<next_few_limit([$integer])>.

=head2 next_few_limit([$integer])

Here, the [] indicate an optional parameter.

Get or set the number of characters called 'the next few chars', which are printed during debugging.

'next_few_limit' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 open()

Get the arrayref of opening delimiters.

See also L</close()>.

See the L</FAQ> for details and warnings.

'open' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 options([$bit_string])

Here, the [] indicate an optional parameter.

Get or set the option flags.

For typical usage, see scripts/synopsis.pl.

See the L</FAQ> for details.

'options' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse([%hash])

Here, the [] indicate an optional parameter.

This is the only method the user needs to call. All data can be supplied when calling L</new()>.

You can of course call other methods (e.g. L</text([$stringref])> ) after calling L</new()> but
before calling C<parse()>.

The optional hash takes these ($key => $value) pairs (exactly the same as for L</new()>):

=over 4

=item o length => $integer

=item o options => $bit_string

=item o pos => $integer

=item o text => $stringref

=back

Note: If a value is passed to C<parse()>, it takes precedence over any value with the same
key passed to L</new()>, and over any value previously passed to the method whose name is $key.
Further, the value passed to C<parse()> is always passed to the corresponding method (i.e. whose
name is $key), meaning any subsequent call to that method returns the value passed to C<parse()>.

See scripts/samples.pl.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 pos([$integer])

Here, the [] indicate an optional parameter.

Get or set the offset within the input string at which to start processing.

See also the L</FAQ> and L</length([$integer])>.

'pos' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 text([$stringref])

Here, the [] indicate an optional parameter.

Get or set a reference to the string to be parsed.

'text' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 tree()

Returns an object of type L<Tree>, which holds the parsed data.

Obviously, it only makes sense to call C<tree()> after calling C<parse()>.

See scripts/traverse.pl for sample code which processes this tree's nodes.

=head1 FAQ

=head2 What are the differences between File::BOM::CheckAddRemove and Text::Delimited::Marpa?

I think this is shown most clearly by getting the 2 modules to process the same string. So,
using this as input:

	'a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k'

Output from File::BOM::CheckAddRemove's scripts/tiny.pl:

	(#   2) |          1         2         3         4         5         6         7         8         9
	        |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	Parsing |Skip me ->a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|. pos: 10. length: 42
	Parse result: 0 (0 is success)
	root. Attributes: {text => "", uid => "0"}
	    |--- text. Attributes: {text => "a ", uid => "1"}
	    |--- open. Attributes: {text => "<:", uid => "2"}
	    |    |--- text. Attributes: {text => "b ", uid => "3"}
	    |    |--- open. Attributes: {text => "<:", uid => "4"}
	    |    |    |--- text. Attributes: {text => "c", uid => "5"}
	    |    |--- close. Attributes: {text => ":>", uid => "6"}
	    |    |--- text. Attributes: {text => " d", uid => "7"}
	    |--- close. Attributes: {text => ":>", uid => "8"}
	    |--- text. Attributes: {text => " e ", uid => "9"}
	    |--- open. Attributes: {text => "<:", uid => "10"}
	    |    |--- text. Attributes: {text => "f ", uid => "11"}
	    |    |--- open. Attributes: {text => "<:", uid => "12"}
	    |    |    |--- text. Attributes: {text => " g ", uid => "13"}
	    |    |    |--- open. Attributes: {text => "<:", uid => "14"}
	    |    |    |    |--- text. Attributes: {text => "h", uid => "15"}
	    |    |    |--- close. Attributes: {text => ":>", uid => "16"}
	    |    |    |--- text. Attributes: {text => " i", uid => "17"}
	    |    |--- close. Attributes: {text => ":>", uid => "18"}
	    |    |--- text. Attributes: {text => " j", uid => "19"}
	    |--- close. Attributes: {text => ":>", uid => "20"}
	    |--- text. Attributes: {text => " k", uid => "21"}

Output from Text::Delimited::Marpa's scripts/tiny.pl:

	(#   2) |          1         2         3         4         5         6         7         8         9
	        |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	Parsing |Skip me ->a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|. pos: 10. length: 42
	Parse result: 0 (0 is success)
	root. Attributes: {end => "0", length => "0", start => "0", text => "", uid => "0"}
	    |--- span. Attributes: {end => "22", length => "9", start => "14", text => "b <:c:> d", uid => "1"}
	    |    |--- span. Attributes: {end => "18", length => "1", start => "18", text => "c", uid => "2"}
	    |--- span. Attributes: {end => "47", length => "18", start => "30", text => "f <: g <:h:> i:> j", uid => "3"}
	         |--- span. Attributes: {end => "43", length => "10", start => "34", text => " g <:h:> i", uid => "4"}
	              |--- span. Attributes: {end => "39", length => "1", start => "39", text => "h", uid => "5"}

Another example, using the same input string, but manually processing the tree nodes.
Parent-daughter relationships are here represented by indentation.

Output from File::BOM::CheckAddRemove's scripts/traverse.pl:

	        |          1         2         3         4         5
	        |012345678901234567890123456789012345678901234567890
	Parsing |a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|.
	Span  Text
	   1  |a |
	   2  |<:|
	   3    |b |
	   4    |<:|
	   5      |c|
	   6    |:>|
	   7    | d|
	   8  |:>|
	   9  | e |
	  10  |<:|
	  11    |f |
	  12    |<:|
	  13      | g |
	  14      |<:|
	  15        |h|
	  16      |:>|
	  17      | i|
	  18    |:>|
	  19    | j|
	  20  |:>|
	  21  | k|

Output from Text::Delimited::Marpa's scripts/traverse.pl:

	        |          1         2         3         4         5
	        |012345678901234567890123456789012345678901234567890
	Parsing |a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|.
	Span  Start  End  Length  Text
	   1      4   12       9  |b <:c:> d|
	   2      8    8       1    |c|
	   3     20   37      18  |f <: g <:h:> i:> j|
	   4     24   33      10    | g <:h:> i|
	   5     29   29       1      |h|

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

=head2 How do I escape delimiters?

By backslash-escaping the first character of all open and close delimiters which appear in the
text.

As an example, if the delimiters are '<:' and ':>', this means you have to escape I<all> the '<'
chars and I<all> the colons in the text.

The backslash is preserved in the output.

If you don't want to use backslash for escaping, or can't, you can pass a different escape character
to L</new()>.

See t/escapes.t.

=head2 How do the length and pos parameters to new() work?

The recognizer - an object of type Marpa::R2::Scanless::R - is called in a loop, like this:

	for
	(
		$pos = $self -> recce -> read($stringref, $pos, $length);
		$pos < $length;
		$pos = $self -> recce -> resume($pos)
	)

L</pos([$integer])> and L</length([$integer])> can be used to initialize $pos and $length.

Note: The first character in the input string is at pos == 0.

See L<https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/R.pod#read> for details.

=head2 Does this package support Unicode/UTF8?

Yes. See t/escapes.t, t/multiple.quotes.t and t/utf8.t.

=head2 Does this package handler Perl delimiters (e.g. q|..|, qq|..|, qr/../, qw/../)?

See t/perl.delimiters.t.

=head2 Warning: Calling mutators after calling new()

The only mutator which works after calling new() is L</text([$stringref])>.

In particular, you can't call L</escape_char()>, L</open()> or L</close()> after calling L</new()>.
This is because parameters passed to C<new()> are interpolated into the grammar before parsing
begins. And that's why the docs for those methods all say 'Get the...' and not 'Get and set the...'.

To make the code work, you would have to manually call _validate_open_close(). But even then
a lot of things would have to be re-initialized to give the code any hope of working.

=head2 What is the format of the 'open' and 'close' parameters to new()?

Each of these parameters takes an arrayref as a value.

The # of elements in the 2 arrayrefs must be the same.

The 1st element in the 'open' arrayref is the 1st user-chosen opening delimiter, and the 1st
element in the 'close' arrayref must be the corresponding closing delimiter.

It is possible to use a delimiter which is part of another delimiter.

See scripts/samples.pl. It uses both '<' and '<:' as opening delimiters and their corresponding
closing delimiters are '>' and ':>'. Neat, huh?

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use File::BOM::CheckAddRemove ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see t/angle.brackets.t, t/colons.t, t/escapes.t,
t/multiple.quotes.t, t/percents.t and scripts/samples.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

C<nothing_is_fatal> has the value of 0.

=item o print_errors

Print errors if this flag is set.

C<print_errors> has the value of 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

C<print_warnings> has the value of 2.

=item o print_debugs

Print extra stuff if this flag is set.

C<print_debugs> has the value of 4.

=item o overlap_is_fatal

This means overlapping delimiters cause a fatal error.

So, setting C<overlap_is_fatal> means '{Bold [Italic}]' would be a fatal error.

I use this example since it gives me the opportunity to warn you, this will I<not> do what you want
if you try to use the delimiters of '<' and '>' for HTML. That is, '<i><b>Bold Italic</i></b>' is
not an error because what overlap are '<b>' and '</i>' BUT THEY ARE NOT TAGS. The tags are '<' and
'>', ok? See also t/html.t.

C<overlap_is_fatal> has the value of 8.

=item o nesting_is_fatal

This means nesting of identical opening delimiters is fatal.

So, using C<nesting_is_fatal> means 'a <: b <: c :> d :> e' would be a fatal error.

C<nesting_is_fatal> has the value of 16.

=item o ambiguity_is_fatal

This makes L</error_number()> return 3 rather than -3.

C<ambiguity_is_fatal> has the value of 32.

=item o exhaustion_is_fatal

This makes L</error_number()> return 6 rather than -6.

C<exhaustion_is_fatal> has the value of 64.

=back

=head2 How do I print the tree built by the parser?

See L</Synopsis>.

=head2 How do I make use of the tree built by the parser?

See scripts/traverse.pl. It is a copy of t/html.t with tree-walking code instead of test code.

=head2 How is the parsed data held in RAM?

The parsed output is held in a tree managed by L<Tree>.

The tree always has a root node, which has nothing to do with the input data. So, even an empty
input string will produce a tree with 1 node. This root has an empty hashref associated with it.

Nodes have a name and a hashref of attributes.

The name indicates the type of node. Names are one of these literals:

=over 4

=item o close

=item o open

=item o root

=item o text

=back

For 'open' and 'close', the delimiter is given by the value of the 'text' key in the hashref.

The (key => value) pairs in the hashref are:

=over 4

=item o text => $string

If the node name is 'open' or 'close', $string is the delimiter.

If the node name is 'text', $string is the verbatim text from the document.

Verbatim means, for example, that backslashes in the input are preserved.

=back

Try:

	perl -Ilib scripts/samples.pl info

=head2 How is HTML/XML handled?

The tree does not preserve the nested nature of HTML/XML.

Post-processing (valid) HTML could easily generate another view of the data.

But anyway, to get perfect HTML you'd be grabbing the output of L<Marpa::R2::HTML>, right?

See scripts/traverse.pl and t/html.t for a trivial HTML parser.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o Advanced error reporting

See L<https://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2014/11/delimiter.html>.

Perhaps this could be a sub-class?

=item o I8N support for error messages

=item o An explicit test program for parse exhaustion

=back

=head1 See Also

L<Text::Delimited::Marpa>.

L<Tree> and L<Tree::Persist>.

L<Text::Balanced>.

L<MarpaX::Demo::SampleScripts> - for various usages of L<Marpa::R2>, but not of this module.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Thanks to Jeffrey Kegler, who wrote Marpa and L<Marpa::R2>.

And thanks to rns (Ruslan Shvedov) for writing the grammar for double-quoted strings used in
L<MarpaX::Demo::SampleScripts>'s scripts/quoted.strings.02.pl. I adapted it to HTML (see
scripts/quoted.strings.05.pl in that module), and then incorporated the grammar into
L<GraphViz2::Marpa>, and - after more extensions - into this module.

Lastly, thanks to Robert Rothenberg for L<Const::Exporter>, a module which works the same way
Perl does.

=head1 Repository

L<https://github.com/ronsavage/Text-Balanced-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File::BOM::CheckAddRemove>.

=head1 Author

L<File::BOM::CheckAddRemove> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut

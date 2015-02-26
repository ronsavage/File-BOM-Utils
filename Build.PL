use strict;
use warnings;

use Module::Build;

# -----------------------------------------------

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'File::BOM::CheckAddRemove',
	license        => 'artistic_2',
	dist_abstract  => 'Check, Add and Remove BOMs, with file locking',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 1.001006,
# 	 	'Test::Pod'  => 1.45, # Make it optional. See xt/author/pod.t.
	},
	configure_requires =>
	{
		'Module::Build' => 0.4210,
	},
	requires =>
	{
		'Fcntl'    => 0,
		'strict'   => 0,
		'warnings' => 0,
	},
	resources =>
	{
		bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-BOM-CheckAddRemove',
		license    => 'http://opensource.org/licenses/Artistic-2.0',
		repository => 'https://github.com/ronsavage/File-BOM-CheckAddRemove',
	},
) -> create_build_script();

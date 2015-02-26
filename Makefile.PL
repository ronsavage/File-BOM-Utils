use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Check, Add and Remove BOMs, with file locking',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST File-BOM-CheckAddRemove-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'File-BOM-CheckAddRemove',
	NAME      => 'File::BOM::CheckAddRemove',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Fcntl'      => 0,
		'strict'     => 0,
		'Test::More' => 1.001006,
#		'Test::Pod'  => 1.45, # Make it optional. See xt/author/pod.t
		'warnings'   => 0,
	},
	VERSION_FROM => 'lib/File/BOM/CheckAddRemove.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-BOM-CheckAddRemove',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/File-BOM-CheckAddRemove.git',
				web  => 'https://github.com/ronsavage/File-BOM-CheckAddRemove',
			},
		},
	};
}

WriteMakefile(%params);

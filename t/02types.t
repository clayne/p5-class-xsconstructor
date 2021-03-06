=pod

=encoding utf-8

=head1 PURPOSE

Test that Class::XSConstructor supports manual type constraints.

B<< TODO: >> thia currently fails, but it's not documented yet anyway.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;# skip_all => "TODO: why won't these pass???";
use Test::Fatal;

BEGIN {
	package Local::Types;
	our $Int = sub {
		my $val = shift;
		!ref($val) and $val =~ /\A-?[0-9]+\z/;
	};
}

ok( $Local::Types::Int->('40'),   "Int('40')" );
ok(!$Local::Types::Int->('xyz'), "!Int('xyz')");

{
	package Person;
	use Class::XSConstructor qw( name! ), age => $Local::Types::Int, qw( email phone );
}

{
	package Employee;
	use parent -norequire, qw(Person);
	use Class::XSConstructor qw( employee_id! );
}

# This is not part of the public API, but a simple way of
# testing the import stuff works properly.
#

is_deeply(
	\@Person::__XSCON_HAS,
	[qw/ name age email phone /],
	'Person attributes',
);

is_deeply(
	\@Employee::__XSCON_HAS,
	[qw/ name age email phone employee_id /],
	'Employee attributes',
);

is_deeply(
	\@Person::__XSCON_REQUIRED,
	[qw/ name /],
	'Person required attributes',
);

is_deeply(
	\@Employee::__XSCON_REQUIRED,
	[qw/ name employee_id /],
	'Employee required attributes',
);

is_deeply(
	\%Person::__XSCON_ISA,
	{ age => $Local::Types::Int },
	'Person type constraints',
);

is_deeply(
	\%Employee::__XSCON_ISA,
	{ age => $Local::Types::Int },
	'Employee type constraints',
);

my $alice0 = bless {
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
} => "Employee";

my $alice1 = Employee->new(
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
	ignoreme     => 999,
);

my $alice2 = Employee->new(
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
	ignoreme     => 999,
);

is_deeply($alice1, $alice0, 'constructor works given list of key-value pairs');
is_deeply($alice2, $alice0, 'constructor works given hashref');

is_deeply(
	Employee->new(name => "Alice", employee_id => "001"),
	bless({ name => "Alice", employee_id => "001" } => "Employee"),
	"optional arguments don't autovivify given list of key-value pairs",
);

is_deeply(
	Employee->new({ name => "Alice", employee_id => "001" }),
	bless({ name => "Alice", employee_id => "001" } => "Employee"),
	"optional arguments don't autovivify given hashref",
);

my $e1 = exception { Employee->new(  name        => "Alice"   ) };
my $e2 = exception { Employee->new(  exployee_id => "001"     ) };
my $e3 = exception { Employee->new({ name        => "Alice"  }) };
my $e4 = exception { Employee->new({ exployee_id => "001"    }) };
my $e5 = exception { Employee->new(  name => "Alice", employee_id => "001"  ) };
my $e6 = exception { Employee->new({ name => "Alice", employee_id => "001" }) };

like($_, qr/\AAttribute 'employee_id' is required/, 'exception') for $e1, $e3;
like($_, qr/\AAttribute 'name' is required/       , 'exception') for $e2, $e4;
is($_, undef, 'no exception') for $e5, $e6;

my $e7 = exception { Employee->new(  name => "Alice", employee_id => "001", age => "xyz"  ) };
my $e8 = exception { Employee->new({ name => "Alice", employee_id => "001", age => "xyz" }) };

like($_, qr/failed type constraint/, 'exception') for $e7, $e8;

done_testing;


use MooseX::Declare;

class Test::Common::Timer with (Agua::Common::Timer, Util::Main, Util::Logger) {
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Int
has 'log'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	5);

# String

####///}}}

method BUILD ($hash) {
}

method testDatetimeToMysql {
	diag("getMysqlTime");

	my $tests	=	[
		{
			date		=>	"Fri May  9 14:20:02 PDT 2014",
			expected	=>	"2014-05-09 14:20:02"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $date	=	$test->{date};
		my $expected=	$test->{expected};
		$self->logDebug("expected", $expected);
		
		my $actual	=	$self->datetimeToMysql($date);
		$self->logDebug("actual", $actual);

		ok($actual eq $expected, "correct $expected");
	}
	
}


}   #### Test::Common::Timer
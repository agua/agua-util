use MooseX::Declare;

class Test::Util::Main with Util::Logger extends Util::Main {

use Data::Dumper;
use Test::More;

use FindBin qw($Bin);

method testFileTail {
	diag("Test fileTail");

  #### CREATE OUTPUTDIR
  my $outputdir = "$Bin/outputs";
  `rm -fr $outputdir`;
  `mkdir -p $outputdir` if not -d $outputdir;

  my $tests = [
    {
      source  =>  "$Bin/inputs/present.txt",
      target  =>  "$Bin/outputs/present",
      found   =>  "The cluster has been started and configured.",
      reset   =>  10,
      pause   =>  1,
      maxwait =>  5,
      expected=>  1
    },
    {
      source  =>  "$Bin/inputs/missing.txt",
      target  =>  "$Bin/outputs/missing",
      found   =>  "The cluster has been started and configured.",
      reset   =>  10,
      pause   =>  1,
      maxwait =>  5,
      expected=>  0
    }
  ];

  foreach my $test ( @$tests ) {
    my $source  = $test->{source};
    my $target  = $test->{target};
    my $found   = $test->{found};
    my $pause   = $test->{pause};
    my $maxwait = $test->{maxwait};
    my $expected= $test->{expected};

    #### START PRINT FILE ASYNCHRONOUSLY
    $self->logDebug("target", $target);
    $self->asyncPrintFile($source, $target, 5, 1);
    sleep(2);

    #### TEST
    my $actual = $self->fileTail($target, $found, $pause, $maxwait);
    $self->logDebug("actual", $actual);
    is_deeply($actual, $expected);
  }	
}

method asyncPrintFile ($sourcefile, $targetfile, $printlines, $pause) {
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("printlines", $printlines);
	$self->logDebug("pause", $pause);

  #### READ SOURCE FILE
  open(FILE, $sourcefile) or die "Can't open sourcefile: $sourcefile\n";
  my @lines = <FILE>;
  close(FILE);
	$self->logDebug("no. lines: ", $#lines + 1, "");
    
	my $pid = fork();
	if ( $pid == 0 ) {
    #### PRINT TO TARGET FILE IN printlines CHUNKS OF LINES
    open(OUT, ">$targetfile") or die "Can't open targetfile: $targetfile\n";
    my $counter = 0;
    while ( $counter < $#lines + 1 ) {
      # print "******* counter: $counter ******** $lines[$counter]\n";
      my $step = 0;
      while ( $step < $printlines and $counter < $#lines + 1 ) {
          print OUT $lines[$counter];
          $step++;
          $counter++;
      }
      sleep($pause);
    }
    close(OUT) or die "Can't close targetfile: $targetfile\n";
    $self->logDebug("FINISHED PRINTING FILE");
		exit;
	}
    
    return;
}


}   #### Test::Util::Main
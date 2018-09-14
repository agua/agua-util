package Util::Logger;
use Moose::Role;
use Method::Signatures::Simple;

=head2

ROLE        Util::Logger

PURPOSE

	1. PRINT MESSAGE TO STDOUT AND/OR LOG FILE

	2. PREFIX DATETIME AND CALLING CLASS, FILE AND LINE NUMBER

	3. 'LOGLEVEL' VARIABLE SPECIFIES WHICH CATEGORIES OF LOG TO OUTPUT:
		
		LOGLEVEL	Outputs (incl. previous level)	Example
		
			1		logCritical 	"SYSTEM FAILURE... QUITTING"
				
			2		logWarning 		"POSSIBLE ERROR ... CONTINUING"

			3		logInfo 		"SOMETHING MIGHT HAPPEN HERE"

			4		logDebug		"CHECKING HERE FOR ERRORS"
					logCaller
					logDebug	
			
			5		logNote 		"NOTHING HAPPENED, WE ARE HERE"

	4. logCaller METHOD INCLUDES THE FOLLOWING INFORMATION:
	
			-	DATETIME
		
			-	NAME OF THE CALLING METHOD
		
			-	LINE NUMBER IN FILE OF CALLING METHOD

		
	5. logError AND logStatus PRINT REGARDLESS OF THE LOGLEVEL

		logError	LOGFILE & STDOUT 	{ error: ... , module, line, datetime }
		
		logStatus	STDOUT	 			{ status: ..., module, line, datetime }

=cut

#Boolean
has 'backup' 	=> ( isa => 'Int', 		is => 'rw', default => 0 );

# Int
has 'log'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'oldlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'oldprintlog'=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'errpid' 	=> ( isa => 'Int', 		is => 'rw', required => 0 );
has 'indent'	=> ( isa => 'Int', 		is => 'rw', default	=>	4 );

# String
has 'logtype'	=> ( isa => 'Str', 		is => 'rw', default	=> 	"cli"	);  
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username' 	=> ( isa => 'Str|Undef', 		is => 'rw', required => 0 );

# Object
has 'logfh'     => ( isa => 'FileHandle|Undef', is => 'rw', required => 0 );
has 'oldout' 	=> ( isa => 'FileHandle', is => 'rw', required => 0 );
has 'olderr' 	=> ( isa => 'FileHandle', is => 'rw', required => 0 );

#### EXTERNAL MODULES
use Data::Dumper;
# use PadWalker qw/peek_my peek_our/;

# sub get_name_my {
#     my $pad = peek_my($_[0] + 1);
#     for (keys %$pad) {
#         return $_ if $$pad{$_} == \$_[1]
#     }
# }
# sub get_name_our {
#     my $pad = peek_our($_[0] + 1);
#     for (keys %$pad) {
#         return $_ if $$pad{$_} == \$_[1]
#     }
# }
# sub get_name_stash {
#     my $caller = caller($_[0]) . '::';
#     my $stash = do {
#         no strict 'refs';
#         \%$caller
#     };
#     my %lookup;
#     for my $name (keys %$stash) {
#         if (ref \$$stash{$name} eq 'GLOB') {
#             for (['$' => 'SCALAR'],
#                  ['@' => 'ARRAY'],
#                  ['%' => 'HASH'],
#                  ['&' => 'CODE']) {
#                 if (my $ref = *{$$stash{$name}}{$$_[1]}) {
#                     $lookup{$ref} ||= $$_[0] . $caller . $name
#                 }
#             }
#         }
#     }
#     $lookup{\$_[1]}
# }

# sub get_name {
#     unshift @_, @_ == 2 ? 1 + shift : 1;
#     &get_name_my  or
#     &get_name_our or
#     &get_name_stash
# }


# method log ( $variable ) {
# 	my $name = get_name(1, $variable) || 'name not found';
	
# 	return -1 if not $self->log() > 3 and not $self->printlog() > 3;

# 	$name = '' if not defined $name;
#     $self->appendLog($self->logfile()) if not defined $self->logfh();   

# 	my $text = $variable;
# 	if ( not defined $variable and @_ == 2 )	{
# 		$text = "undef";
# 	}
# 	elsif ( ref($variable) )	{
# 		$text = $self->objectToJson($variable);
# 	}

#   my ($package, $filename, $linenumber) = caller;
#   my $timestamp = $self->logTimestamp();
# 	my $callingsub = (caller 1)[3] || '';
	
# 	my $indent = $self->indent();
# 	my $spacer = " " x $indent;
# 	my $line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$name\n";
# 	$line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$name: $text\n" if @_ == 2;

#   print { $self->logfh() } $line if defined $self->logfh();
#   print $line;
# 	return $line;
# }


method setUserLogfile (  $username, $identifier, $mode ) {
	return "/tmp/$username.$identifier.$mode.log";
}

method WARN_handler ( $signal ) {
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $line = "$timestamp\t[WARN]   \t$callingsub\t$linenumber\t$signal";
	
  print STDERR $line;
	print { $self->logfh() } $line if defined $self->logfh();
}

method DIE_handler ( $signal ) {
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $line = "$timestamp\t[DIE]   \t$callingsub\t$linenumber\t$signal";
	
  print STDERR $line;
	print { $self->logfh() } $line if defined $self->logfh();
}

method logGroup ( $message ) {
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();

	#### SET INDENT	
	#$self->logDebug("BEFORE self->indent", $self->indent());
	my $indent = $self->indent();
	$indent += 4;
	$self->indent($indent);
	#$self->logDebug("AFTER self->indent", $self->indent());

	#### SET LINE
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $spacer = " " x $indent;
  my $line = "$timestamp$spacer". "[GROUP]    \t$callingsub\t$linenumber\t$message\n";

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
  print $line if $self->log() > 3;

	return $line;
}

method logGroupEnd ( $message ) {
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();

	#### SET INDENT	
	#$self->logDebug("BEFORE self->indent", $self->indent());
	my $indent = $self->indent();
	#$self->logDebug("AFTER self->indent", $self->indent());

	#### SET LINE
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $spacer = " " x $indent;
  my $line = "$timestamp$spacer". "[GROUPEND]    \t$callingsub\t$linenumber\t$message\n";

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
  print $line if $self->log() > 3;

	$indent -= 4;
	$indent = 2 if $indent < 4;
	$self->indent($indent);

	return $line;
}

method logReport ( $message ) {
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();

  my $timestamp = $self->logTimestamp();
	my $line = "$timestamp\t[REPORT]   \t$message\n";

  print { $self->logfh() } $line if defined $self->logfh();

	return $line;
}

method logNote ( $message, $variable ) {
	return -1 if not $self->log() > 4 and not $self->printlog() > 4;

	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh(); 

	my $text = $variable;
	if ( not defined $variable and @_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';

	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[NOTE]   \t$callingsub\t$linenumber\t$message\n";
	$line = "$timestamp$spacer" . "[NOTE]   \t$callingsub\t$linenumber\t$message: $text\n" if @_ == 2;

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 4;
  print $line if $self->log() > 4;

	return $line;
}

method logDebug ( $message, $variable ) {
	return -1 if not $self->log() > 3 and not $self->printlog() > 3;

	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   

	my $text = $variable;
	if ( not defined $variable and @_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	
	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message\n";
	$line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message: $text\n" if @_ == 2;
  
  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
  print $line if $self->log() > 3;

	return $line;
}

method logInfo ( $message ) {
	return -1 if not $self->log() > 2 and not $self->printlog() > 2;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[INFO]    \t$callingsub\t$linenumber\t$message\n";

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 2;
  print $line if $self->log() > 2;
	
	return $line;
}

method logWarning ( $message ) {
	return -1 if not $self->log() > 1 and not $self->printlog() > 1;
	
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();   
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[WARNING] \t$callingsub\t$linenumber\t$message\n";

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 1;
  print $line if $self->log() > 1;
	
	return $line;
}

method logCritical ( $message ) {
	return -1 if not $self->log() > 0 and not $self->printlog() > 0;
	
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();   
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[CRITICAL]\t$callingsub\t$linenumber\t$message\n";

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;
  print $line if $self->log() > 0;
	
	#### FOR FASTCGI: SKIP TO END OF SCRIPT WITHOUT EXITING
	#### NB: MUST PUT THIS AT END OF SCRIPT:
	####
	#### EXITLABEL:{};
	#### 
	#### OR YOU CAN WRITE A MESSAGE INSIDE IT:
	#### 
	#### EXITLABEL:{ warn "We have skipped to the end of the program\n"; };
	goto EXITLABEL;
	
	return $line;
}

#### 1. PRINT MESSAGE TO BOTH LOGFILE AND STDOUT
#### 2. PREFIX DATETIME AND CALLING CLASS, FILE AND LINE NUMBER
method logCaller ( $message, $variable ) {
	$message = '' if not defined $message;
  $self->appendLog($self->logfile()) if not defined $self->logfh();   
  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $caller = (caller 2)[3] || '';
	my $callerline = (caller 2)[2] || '';

	my $text = $variable;
	if ( not defined $variable and @_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[CALLER]   \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message\n";
	$line = "$timestamp$spacer" . "[CALLER]   \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message: $text\n" if @_ == 2;

#	my $callerline = (caller 2)[2];
#    my $line = "$timestamp\t[CALLER]  \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message\n";

  print $line if $self->log() > 3;
  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
	return $line;
}

method logError ( $message, $variable ) {
	$message = '' if not defined $message;
  # $self->appendLog($self->logfile()) if not defined $self->logfh();   

	my $text = $variable;
	if ( not defined $variable and @_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

  my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
  my $line = "$timestamp\t[ERROR]   \t$callingsub\t$linenumber\t$message\n";

	my $logtype	=	$self->logtype();
	if ( $logtype eq "json" ) {
	    print qq{{"error":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp"}\n};
	}
	else {
		my $indent = $self->indent();
		my $spacer = " " x $indent;
		my $line = "$timestamp$spacer" . "[ERROR]   \t$callingsub\t$linenumber\t$message\n";
		$line = "$timestamp$spacer" . "[ERROR]   \t$callingsub\t$linenumber\t$message: $text\n" if @_ == 2;
	}

  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;
  print $line if $self->printlog() > 0;
	
	return $line;
}

method logStatus ( $message, $data ) {
	$message = '' if not defined $message;
	$data = {} if not defined $data;

  $self->appendLog($self->logfile()) if not defined $self->logfh();   
	
	my ($package, $filename, $linenumber) = caller;
  my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
    my $line = "$timestamp\t[STATUS]  \t$callingsub\t$linenumber\t$message\n";
  print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;

	my $datajson = $self->objectToJson($data);
  print qq{{"status":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp","data":$datajson}\n};

	return $line;
}

method startLog ( $logfile ) {
	$self->logfile($logfile);
	$self->backupLogfile($logfile) if $self->backup();
	
	#### OPEN LOGFILE
	my $logfh;
    open($logfh, ">$logfile") or die "Can't open logfile: $logfile\n";
	$self->logfh($logfh);
}

method appendLog ( $logfile ) {
  return if not defined $logfile or not $logfile;
  $self->logfile($logfile);
    
	#### OPEN LOGFILE
	my $logfh;
    open($logfh, ">>$logfile") or die "Can't open logfile: $logfile\n";

  $self->logfh($logfh);    
}

method pauseLog {
	$self->oldlog($self->log());
	$self->oldprintlog($self->printlog());
	$self->printlog(0);
	$self->log(0);
	return;	
}

method resumeLog ( $logfile ) {
    $logfile = $self->logfile() if not defined $logfile;
    $self->logError("logfile not defined") and exit if not defined $logfile;

	$self->log($self->oldlog()) if defined $self->oldlog();
	$self->printlog($self->oldprintlog()) if defined $self->oldprintlog();
}

method stopLog{
	$self->printlog(0);
	$self->log(0);
	
	#### CLOSE LOG FILEHANDLE
	my $logfh = $self->logfh();
    close($logfh) if defined $logfh;
	$self->logfh(undef);
}

method backupLogfile ( $logfile ) {
#### MOVE OLD LOGFILE TO *.N WITH N INCREMENTED EACH TIME
	return if not defined $logfile or not $logfile;
  return if not -f $logfile;
    
  my $oldfile = $logfile;
  $oldfile .= ".1";	
	while ( -f $oldfile )	{
		my ($stub, $index) = $oldfile =~ /^(.+?)\.(\d+)$/;
		$index++;
		$oldfile = $stub . "." . $index;
	}
    `mv $logfile $oldfile`;
}

method logTimestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return sprintf "%4d-%02d-%02d %02d:%02d:%02d",
        $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

method objectToJson ( $object ) {
	my $json = sprintf "%s", Dumper $object;
	$json =~ s/^\s*\$VAR1\s*=\s*//;
	$json =~ s/;\s\n*\s*$//ms;
	$json =~ s/'/"/gms;
	$json =~ s/\s*\n\s*//gms;
	$json =~ s/\s+=>\s+/:/gms;
	#$json =~ s/,/,\n/gms;

	return $json;	
}

method set_signal_handlers {
	#### SET SIGNAL HANDLERS
	$self->logDebug("Setting SIG{'Warn'} to WARN_handler");
	$SIG{__WARN__} =sub { $self->WARN_handler() };
	$SIG{__DIE__}=sub { $self->DIE_handler() };

##### SET SIGNAL HANDLERS
#$SIG{__WARN__} = \&WARN_handler;
#$SIG{__DIE__}  = \&DIE_handler;

}



no Moose::Role;

1;


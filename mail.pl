#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Encode;
use Mojo::UserAgent;

my %rcpt = ();
open (RCPT,"<", "rcpt.txt") || die "Can't open rcpt.txt file";
	while(my $row = <RCPT>){
		my($alias, $addr) = split('=',$row);
		chomp $addr;
		$rcpt{$alias} = $addr;
	};
close (RCPT);

my $to = ''; 

if (keys %rcpt == 1){
	my @alias = keys %rcpt;
	$to = $rcpt{$alias[0]};

}else{
	print "Enter recipient.\n0 - list of aliases\nq - exit\n";
	while (!$to || !$rcpt{$to}){
		print 'Alias: ';
		$to = <>;
		chomp $to;
		exit if ($to eq 'q');
		if ($to eq 0){
			foreach my $key (keys %rcpt){
				print "$key <$rcpt{$key}>\n";

			};
		};
	};
	$to = $rcpt{$to};

};

print 'To: ';
print $to;

print "\nS: ";

my $subject = Encode::decode('utf8', <>);
chop $subject;

print 'T: ';
my $body = Encode::decode('utf8', <>);
chop $body;

if ($subject || $body){

	$body = ' ' if (!$body);
	
	my $ua = Mojo::UserAgent->new;
	my $tx = $ua->post('https://api.postmarkapp.com/email', 
		{
			'Accept' => 'application/json',
			'Content-Type' => 'application/json',
			'X-Postmark-Server-Token' => '830d529a-a84e-4a11-8a12-dd8b590039b9',
		} => json => 
		{
			from => 'mailbox@emrk.ru', 
			to => $to, 
			subject => $subject,
			htmlbody => $body,
		}
	)->result;

	print "\nResult: ".$tx->message;
}else{

	print "Result: empty text";
};

print "\n";

1;

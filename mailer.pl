#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Encode;
use Mojo::UserAgent;
use YAML::XS 'LoadFile';
use FindBin qw($Bin $Script);

$Script=~s/\.pl//;
my $config = LoadFile("$Bin/$Script.yaml");
my %rcpt = (); #Recipients alias->address

open (RCPT,"<", "$Bin/rcpt.txt") || die "Can't open rcpt.txt file";
	while(my $row = <RCPT>){
		my($alias, $addr) = split('=',$row);
		chomp $addr;
		$rcpt{$alias} = $addr;
	};
close (RCPT);

my $to = ''; 

$to = $ARGV[0] if(@ARGV); #Check if has recipient in argument

if (keys %rcpt == 1){
	my @alias = keys %rcpt;
	$to = $rcpt{$alias[0]};

}else{
	while (!$to || !$rcpt{$to}){
		print "\nEnter recipient.\n[0] - show list\n[/] - exit\n";	
		print "\nRecipient: ";
		$to = <STDIN>;
		chomp $to;
		exit if ($to eq '/');
		if ($to eq 0){
			print "\nRecipient list\n";
			foreach my $key (keys %rcpt){
				print "$key\t<$rcpt{$key}>\n";

			};
		};
	};
	$to = $rcpt{$to};
};

print 'To: ';
print $to;

my $subject = '';
my $body = '';

if ($ARGV[1]) {
	$subject = $ARGV[1]; 
	$subject = Encode::decode('utf8', $subject);

}else{
	print "\nSubj.: ";
	$subject = Encode::decode('utf8', <STDIN>);
	chop $subject;

	print 'Msg.: ';
	my $msg = '';
	while($msg = <STDIN>){
		last if ($msg eq ".\n");
		$body = $body.Encode::decode('utf8', $msg);
	};

	chop $body;
};

if ($subject || $body){

	$body = ' ' if (!$body);
	
	my $ua = Mojo::UserAgent->new;
	my $tx = $ua->post('https://api.postmarkapp.com/email', 
		{
			'Accept' => 'application/json',
			'Content-Type' => 'application/json',
			'X-Postmark-Server-Token' => $config->{token},
		} => json => 
		{
			from => $config->{from}, 
			to => $to, 
			subject => $subject,
			textbody => $body,
		}
	)->result;

	print "\nResult: ".$tx->message;
}else{

	print "Result: empty text";
};

print "\n";

1;

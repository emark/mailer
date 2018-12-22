#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Encode;
use Mojo::UserAgent;
use YAML::XS 'LoadFile';
use FindBin qw($Bin $Script);

my $VERSION = '1.03';
$Script=~s/\.pl//;
my $config_file = "$Bin/$Script.yaml"; 
my $config = {
	token => 'xxxx-xxxx-xxxx',
	from => 'mail@gmail.com',
	recipients => 'rcpt.txt',
	codepage => 'utf8',
};

print "Mailer, v.$VERSION\n";
if (-f $config_file){
	my $check_config = LoadFile($config_file);
	foreach my $key (keys %{$check_config}){
		if(!$config->{$key}){
			print "Checking for configuration file is false. Abort.";
			exit;
		};
	};
	$config = $check_config;

}else{

open (CONF, ">", $config_file) || die "Can't create configuration file: $config_file";
	foreach my $key (keys %{$config}){
		print CONF "$key: $config->{$key}\n";
	};
close CONF;

print "Create default config file.\nPlease edit config file and run program once more.\n";
exit;
};

my %rcpt = (); #Recipients alias->address

open (RCPT,"<", "$Bin/$config->{recipients}") || die "Can't open $config->{recipients} file";
	while(my $row = <RCPT>){
		my ($alias, $addr) = split('=',$row);
		chomp $addr if($addr);
		$rcpt{$alias} = $addr;
	};
close (RCPT);

my $to = ''; 

$to = $ARGV[0] if(@ARGV); #Check if has recipient in argument

if (!$to){
	print "\nRecipients\n";
	foreach my $key (keys %rcpt){
		print "$key\t<$rcpt{$key}>\n" if ($rcpt{$key});

	};
}else{ 
	if (!$rcpt{$to}){
		print "Recipient [$to] not found. Quit.\n";
		exit;
	};

	print "\nTo: ";
	print $rcpt{$to};

	my $subject = '';
	my $body = '';

	if ($ARGV[1]) { #Check if subject taken from arguements
		$subject = $ARGV[1]; 
		$subject = Encode::decode($config->{codepage}, $subject);

	}else{
		print "\nSubj.: ";
		$subject = Encode::decode($config->{codepage}, <STDIN>);
		chop $subject;

		print 'Msg.: ';
		my $msg = '';
		while($msg = <STDIN>){
			last if ($msg eq ".\n");
			$body = $body.Encode::decode($config->{codepage}, $msg);
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
				to => $rcpt{$to},
				subject => $subject,
				textbody => $body,
			}
		)->result;

		print "\nResult: ".$tx->message;
	}else{

		print "Result: empty text";
	};

	print "\n";

};

1;

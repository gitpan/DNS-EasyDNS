package DNS::EasyDNS;

our $VERSION = 0.02;

#==============================================================================#

=head1 NAME

DNS::EasyDNS - Update your EasyDNS dynamic DNS entries

=head1 SYNOPSIS

	use DNS::EasyDNS;
	my $ed = DNS::EasyDNS->new;
	$ed->update( user => "foo", password => "bar" ) || die "Failed: $@";

=head1 DESCRIPTION

This module allows you to update your EasyDNS ( http://www.easydns.com/ )
dynamic DNS records. This is done via an http get using the L<libwww-perl>
modules.

=head1 METHODS

=cut

#==============================================================================#

package DNS::EasyDNS;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use CGI::Util qw(escape);
use HTTP::Request::Common qw(GET);

use base qw(LWP::UserAgent);

use constant URL => 'http://members.easydns.com/dyn/dyndns.php';

#==============================================================================#

=item DNS::EasyDNS->new();

Create a new EasyDNS object. This is actually an inheritted L<LWP::UserAgent>
so you may like to use some of the UserAgent methods. For example,
if you are behind a proxy server:

	$ed->proxy('http', 'http://proxy.sn.no:8001/');

=cut

sub new {
	my ($pack,@args) = @_;
	my $obj = $pack->SUPER::new(@args);
	$obj->agent("DNS::EasyDNS perl module");
	return $obj;
}

#==============================================================================#

=item $ed->update(%args);

Updates your EasyDNS dynamic DNS records. Valid C<%args> are:

=over 8

C<username> - Your EasyDNS login name. This is required.

C<password> - The corresponding password. This is required.

C<hostname> - The full host being updated. This is required.

C<tld> - The root domain of your hostname, for example if your hostname is
"example.co.uk" you should set "tld" to "co.uk".

C<myip> - The IP address of the client to be updated. Use "0.0.0.0" to set 
record to an offline state (sets record to "offline.easydns.com"). This
defaults to the IP address of the incoming connection (handy if you are
being natted).

C<mx> - Use this parameter as the MX handler for the domain being updated, 
it defaults to preference 5.

C<backmx> - Values are either C<"YES"> or C<"NO">, if C<"YES"> we set smtp.easydns.com
to be a backup mail spool for domain being updated at preference 100.

C<wildcard> - Values are either C<"ON"> or C<"OFF">, if C<"ON"> sets a wildcard
host record for the domain being updated equal to the IP address specified 
in C<myip>.

=back

The function returns C<TRUE> of success. On failure it returns C<FALSE> and 
sets C<$@>.

=cut

sub update {
	my ($obj,%args) = @_;

	my %get;
	while (my ($k,$v) = each %args) {
		if    ( $k eq "username" ) { $obj->{"username"} = $v }
		elsif ( $k eq "password" ) { $obj->{"password"} = $v }
		elsif ( $k eq "hostname" ) { $get{hostname} = $v     }
		elsif ( $k eq "tld"      ) { $get{tld} = $v          }
		elsif ( $k eq "myip"     ) { $get{myip} = $v         }
		elsif ( $k eq "mx"       ) { $get{mx} = $v           }
		elsif ( $k eq "backmx"   ) { $get{backmx} = $v       }
		elsif ( $k eq "wildcard" ) { $get{wildcard} = $v     }
		else { carp "update(): Bad argument $k" }
	}

	croak "update(): Argument 'username' is required" 
		unless defined $obj->{"username"};

	croak "update(): Argument 'password' is required" 
		unless defined $obj->{"password"};

	croak "update(): Argument 'hostname' is required" 
		unless defined $args{"hostname"};

	## Make the GET request URL.
	my $qry = join('&', map { escape($_)."=".escape($get{$_}) } keys %get);

	my $resp = $obj->request(GET URL."?".$qry);

	if ($resp->is_success) {
		chomp(my $code = $resp->content);
		if ($code eq 'NOERROR') {
			return 1;
		} else {
			$@ = 'easyDNS said "'.$code.'"';
			return;
		}
	} else {
		$@ = 'HTTP request failed "'.$resp->status_line.'"';
		return;
	}
}

sub get_basic_credentials { ($_[0]->{"username"}, $_[0]->{"password"}) }

#==============================================================================#

=head1 NOTES

There are some example scripts in the C<examples> directory of the module
distribution. These are designed to run out of cron (or similar). You
should not run them to often to avoid overloading the EasyDNS servers (in fact
EasyDNS will not respond to similar reqests less that 10 minutes apart). Ideally
your code should cache the existing value for your IP, and only update
EasyDNS when it changes.

=head1 BUGS

None known

=head1 AUTHOR

This module is Copyright (c) 2002 Gavin Brock gbrock@cpan.org. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

For more information about the EasyDNS services please visit 
http://www.easydns.com/. This module is not written nor supported by 
EasyDNS Technologies Inc., however the code (and much of the documentation) is
based on the Update API as provided by EasyDNS.

=head1 SEE ALSO

L<LWP::UserAgent>

=cut

# That's all folks..
#==============================================================================#
1;

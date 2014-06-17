#!/usr/bin/perl -w

use strict;
use warnings;
use YAML::Syck;
use DateTime;
use DateTime::Format::Strptime;
use Data::Dumper;

my $debug = 0;
my $FPM = "/usr/bin/fpm";

$YAML::Syck::SingleQuote = 1;

die "Usage: $0 package_dir \n(for more doc, use perldoc)\n" if scalar @ARGV != 1;

my $pkg = "$ARGV[0]";
die "Give a valid dir, '$pkg' doesnot exist \n(for more doc, use perldoc)\n" if not -d "$pkg";

my $index = $pkg."/index.yaml";
die "file '$index' doesnot exist \n(for more doc, use perldoc)\n" if not -f $index;

# read the yaml and build the commands
my $yaml = LoadFile($index);
print Dumper $yaml if $debug;

my $command;
my $xtras;			

my $ts = DateTime->from_epoch(epoch => $^T, time_zone => "UTC");

my  $timestamp = $ts->strftime('%Y%m%d%H');

$yaml->{version} .= "_".$timestamp;

$yaml->{epoch} = defined $yaml->{epoch} ? $yaml->{epoch} : 1;

foreach my $option (keys %$yaml) {
  if ($option =~ m!_build!) {
    $xtras .= " " . join ' ', @{$yaml->{$option}};
    next
  }
  if (grep (m!$option!, qw!C t s S!)) {
     $command .= " -" . $option . " " . "'$yaml->{$option}'";
     next
  }
  if (ref($yaml->{$option}) eq 'ARRAY') {
    $command .= " ". join ' ', map { "--$option '$_'" } @{$yaml->{$option}}
  } else {
    $command .= " --" . $option . " " . "'$yaml->{$option}'"
  }
}

$command .= " -C $pkg" if not exists $yaml->{C};

print "DBG: $command\n" if $debug;
print "DBG: $xtras\n"   if $debug;

my $cmd = "$FPM $command $xtras";

print "INFO: $cmd\n";
system($cmd) == 0 or die "$!"

__END__

=pod

=head1 NAME

fpm_multipkg - Not sure how many fpm_multipkg exists and what they are for, but B<this a wrapper around fpm>

=head1 SYNOPSIS

C<fpm_multipkg PACKAGE_DIR>

=head1 DESCRIPTION

fpm_multipkg reads PACKAGE_DIR/index.yaml and created the corresponding 'fpm' command. All the keys are fpm options, except B<_build> which is used by the wrapper. If you want to add more options, just read the fpm help and add the option. Make sure while adding the option, choose the the long-description always and when long-description is not available choose the other. B<For options thT has to be repeated, give it as a list>, see the <-depends> in the L<EXAMPLE CONF>. The package version will be appended by C<git log -1 --pretty=format:%ct>.

=head1 EXAMPLE CONF

  name: fpm_multipkg
  version: 0.9
  depends:
    - perl
    - perl-YAML-Syck
    - perl-DateTime-Format-Strptime
    - perl-DateTime
  url: https://github.com/jordansissel/fpm
  maintainer: "Vigith Maurice"
  description: "A Wrapper around fpm, to formulate the options"
  architecture: noarch
  s: dir
  t: rpm
  _build: 
     - usr


=head1 AUTHOR
Vigith Maurice 

=cut

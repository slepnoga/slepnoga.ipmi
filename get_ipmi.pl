#!/usr/bin/perl

use strict;
use Getopt::Std;
 
my %opts;
getopt('H:U:P:', \%opts);
die "Usage $0 -H host -U user -P password\n"
        unless ($opts{H} && $opts{U} && $opts{P});
 
my $ipmi_cmd = "/usr/sbin/ipmitool";
my $ipmi_prm = "-I lan -H $opts{H} -U $opts{U} -P $opts{P}";
 
open(FRU_LIST, "$ipmi_cmd $ipmi_prm fru |")
        or die "Can't run $ipmi_cmd $ipmi_cmd fru: $!\n";
 
my $template;
my $fru;
while(<FRU_LIST>) {
        chomp;
        s/\s+$//;
        last if defined($template);
        my ($key, $value) = split(/\s*\:\s*/);
        $fru = $value if ($key =~ /FRU\s+Device\s+Description/);
        $template = $value if (($fru =~ /\/SYS/) && ($key =~ /Product\s+Name/));
}
close(FRU_LIST);
$template =~ s/\s+/_/g;
 
open(SENSOR_LIST, "$ipmi_cmd $ipmi_prm sensor list |")
        or die "Can't run $ipmi_cmd $ipmi_cmd sensor list: $!\n";
 
my %sensor;
while(<SENSOR_LIST>) {
        chomp;
        s/\s*$//;
        my ($cs, $unit) = (split(/\s*\|\s*/))[0,2];
        $sensor{$cs}{unit} = $unit;
}
close(SENSOR_LIST);
 
foreach my $cs (sort keys %sensor) {
        open(SENSOR_DATA, "$ipmi_cmd $ipmi_prm sensor get '$cs' |")
                or die "Can't run $ipmi_cmd $ipmi_cmd sensor get '$cs': $!\n";
        while(<SENSOR_DATA>) {
                chomp;
                next unless /\:/;
                my ($key, $value) = split(/\s*\:\s*/);
                $value = undef if ($value eq 'na');
                if ($key =~ /Sensor\s+Type/) {
                        my $type = (split(/[\(\)]/, $key))[1];
                        $sensor{$cs}{type} = $type;
                        $sensor{$cs}{dsc} = $value;
                } elsif ($key =~ /Lower\s+Non-Recoverable/) {
                        $sensor{$cs}{lnr} = $value;
                } elsif ($key =~ /Lower\s+Critical/) {
                        $sensor{$cs}{lcr} = $value;
                } elsif ($key =~ /Lower\s+Non-Critical/) {
                        $sensor{$cs}{lnc} = $value;
                } elsif ($key =~ /Upper\s+Non-Critical/) {
                        $sensor{$cs}{unc} = $value;
                } elsif ($key =~ /Upper\s+Critical/) {
                        $sensor{$cs}{ucr} = $value;
                } elsif ($key =~ /Upper\s+Non-Recoverable/) {
                        $sensor{$cs}{unr} = $value;
                }
        }
        close(SENSOR_DATA);
}
 
print "# template|sensor|type|dsc|unit|lnr|lcr|lnc|unc|ucr|unr\n";
foreach my $cs (sort keys %sensor) {
        printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n",
                $template, $cs, $sensor{$cs}{type},
                $sensor{$cs}{dsc}, $sensor{$cs}{unit},
                $sensor{$cs}{lnr}, $sensor{$cs}{lcr},
                $sensor{$cs}{lnc}, $sensor{$cs}{unc},
                $sensor{$cs}{ucr}, $sensor{$cs}{unr};
}

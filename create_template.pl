#!/usr/bin/perl

# http://www.tune-it.ru/web/tiamat/home/-/blogs/17465

use strict;
use POSIX qw(strftime);
 
my $date = strftime("%d.%m.%y", localtime);
my $time = strftime("%H.%M", localtime);
 
my $delay = 300;
my $history = 7;
my $trends = 365;
 
# 0 - Линия
# 1 - Заполнение
# 2 - Жирная линия
# 3 - Точечный
# 4 - Пунктирная линия
# 5 - Градиентная линия
 
my $drawtype = 1;
 
# 3 - Числовой (целое)
# 0 - Числовой (с плавающей точкой)
# 1 - Символ
# 2 - Журнал (лог)
# 4 - Текст
 
my %sensor_type = (
        Discrete => 3,
        Analog => 0,
);
 
# 0 - Не классифицировано
# 1 - Уведомление
# 2 - Предупреждение
# 3 - Средняя
# 4 - Высокая
# 5 - Чрезвычайная
 
my @thresh_type = (
        { pri => 4, dsc => 'Lower Non-Recoverable' },
        { pri => 3, dsc => 'Lower Critical' },
        { pri => 2, dsc => 'Lower Non-Critical' },
        { pri => 2, dsc => 'Upper Non-Critical' },
        { pri => 3, dsc => 'Upper Critical' },
        { pri => 4, dsc => 'Upper Non-Recoverable' },
);
 
my $head = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<zabbix_export version="1.0" date="%s" time="%s">
        <hosts>
                <host name="%s">
                        <proxy_hostid>0</proxy_hostid>
                        <useip>0</useip>
                        <dns></dns>
                        <ip>0.0.0.0</ip>
                        <port>10050</port>
                        <status>3</status>
                        <useipmi>0</useipmi>
                        <ipmi_ip></ipmi_ip>
                        <ipmi_port>623</ipmi_port>
                        <ipmi_authtype>0</ipmi_authtype>
                        <ipmi_privilege>2</ipmi_privilege>
                        <ipmi_username></ipmi_username>
                        <ipmi_password></ipmi_password>
                        <groups>
                                <group>Templates</group>
                        </groups>
                        <items>
%s
                        </items>
                        <triggers>
%s
                        </triggers>
                        <graphs>
%s
                        </graphs>
                        <templates/>
                        <macros/>
                </host>
        </hosts>
        <dependencies/>
</zabbix_export>
EOF
 
my $item = <<EOF;
                                <item type="12" key="%s" value_type="%d">
                                        <description>%s</description>
                                        <ipmi_sensor>%s</ipmi_sensor>
                                        <delay>$delay</delay>
                                        <history>$history</history>
                                        <trends>$trends</trends>
                                        <status>0</status>
                                        <data_type>0</data_type>
                                        <units>%s</units>
                                        <multiplier>0</multiplier>
                                        <delta>0</delta>
                                        <formula>1</formula>
                                        <lastlogsize>0</lastlogsize>
                                        <logtimefmt></logtimefmt>
                                        <delay_flex></delay_flex>
                                        <authtype>0</authtype>
                                        <username></username>
                                        <password></password>
                                        <publickey></publickey>
                                        <privatekey></privatekey>
                                        <params></params>
                                        <trapper_hosts></trapper_hosts>
                                        <snmp_community></snmp_community>
                                        <snmp_oid></snmp_oid>
                                        <snmp_port>161</snmp_port>
                                        <snmpv3_securityname></snmpv3_securityname>
                                        <snmpv3_securitylevel>0</snmpv3_securitylevel>
                                        <snmpv3_authpassphrase></snmpv3_authpassphrase>
                                        <snmpv3_privpassphrase></snmpv3_privpassphrase>
                                        <applications/>
                                </item>
EOF
 
my $trigger = <<EOF;
                                <trigger>
                                        <description>%s</description>
                                        <type>0</type>
                                        <expression>%s</expression>
                                        <url></url>
                                        <status>0</status>
                                        <priority>%d</priority>
                                        <comments>%s</comments>
                                </trigger>
EOF
 
my $graph = <<EOF;
                                <graph name="%s" width="900" height="200">
                                        <ymin_type>0</ymin_type>
                                        <ymax_type>0</ymax_type>
                                        <ymin_item_key></ymin_item_key>
                                        <ymax_item_key></ymax_item_key>
                                        <show_work_period>1</show_work_period>
                                        <show_triggers>1</show_triggers>
                                        <graphtype>0</graphtype>
                                        <yaxismin>0.0000</yaxismin>
                                        <yaxismax>100.0000</yaxismax>
                                        <show_legend>0</show_legend>
                                        <show_3d>0</show_3d>
                                        <percent_left>0.0000</percent_left>
                                        <percent_right>0.0000</percent_right>
                                        <graph_elements>
                                                <graph_element item="%s">
                                                        <drawtype>$drawtype</drawtype>
                                                        <sortorder>0</sortorder>
                                                        <color>009900</color>
                                                        <yaxisside>0</yaxisside>
                                                        <calc_fnc>2</calc_fnc>
                                                        <type>0</type>
                                                        <periods_cnt>$delay</periods_cnt>
                                                </graph_element>
                                        </graph_elements>
                                </graph>
EOF
 
my ($tname, $items, $triggers, $graphs);
while (<>) {
        chomp;
        next if /^#/;
        my ($template,$sensor,$type,$dsc,$unit,$lnr,$lcr,$lnc,$unc,$ucr,$unr) =
                split(/\|/);
 
        $template = "Template_$template";
        $tname = $template;
 
        my $key = sprintf("%s_%s_%s", $type, $dsc, $unit);
        $key =~ s/[\s\\\/]+/_/g;
        $key = sprintf("%s[%s]", $key, $sensor);
 
        $items .= sprintf($item, $key, $sensor_type{$type},
                        "$type sensor for $dsc $sensor ($unit)", $sensor, $unit);
 
        if ($type eq 'Discrete') {
                $triggers .= sprintf($trigger, 
                        "$type sensor for $dsc $sensor on {HOSTNAME} was changed",
                        sprintf("{%s:%s.diff(0)}#0", $template, $key), 4, '');
        } elsif ($type eq 'Analog') {
                my $index = -1;
                my $op = '#';
                foreach my $tv ($lnr,$lcr,$lnc,$unc,$ucr,$unr) {
                        $index++;
                        next if ($tv =~ /^$/);
                        my $td = $thresh_type[$index]->{dsc};
                        my $tp = $thresh_type[$index]->{pri};
                        $op = '&lt;' if ($index < 3);
                        $op = '&gt;' if ($index > 2);
                        $triggers .= sprintf($trigger,
                                "$type sensor for $dsc $sensor on {HOSTNAME} changed to $td",
                                sprintf("{%s:%s.last(0)}%s%s", $template, $key, $op, $tv), $tp, '');
                }
                $graphs .= sprintf($graph, "$type sensor for $dsc $sensor ($unit)",
                                "$template:$key");
        } else {
                die "unknown sensor type: $type\n";
        }
}
 
printf($head, $date, $time, $tname, $items, $triggers, $graphs);

package Logger;
use strict;
use warnings;
use lib '/perllib';
use Data::Dumper;
use Scalar::Util;

use overload (
    'fallback' => 1,
    '""' => \&toString,
);

my $logLevels;

sub new
{
    my $type = shift;
    my $level = shift;
    my $data = @_;
    
    if(scalar @_ > 1)
    {
        $data = '';
        foreach my $dataData (@_)
        {
            $data .= Logger::formatData('data' => $dataData)."\n";
        }
        $data =~ s/\s+$//s;
    }
    else
    {
        if (scalar @_ == 1)
        {
            $data = $_[0];
        }
        $data = Logger::formatData('data' => $data);
    }
    my $class = ref($type) || $type || 'Logger';

    my $this = {
        'data'  => $data,
        'level' => $level,
    };
    bless $this, $class;

    return $this;
}

sub formatData
{
    my (%params) = @_;
    my $data = $params{'data'};
    if(ref($data))
    {
        if(Scalar::Util::blessed($data) and $data->can('toString'))
        {
            $data = $data->toString(depth => 1);
        }
        else
        {
            require Data::Dumper;
            my $dumper = Data::Dumper->new([$data]);
            $dumper->Freezer("Dumper_Freezer");
            $dumper->Toaster("Dumper_Toaster");
            $dumper->Terse(1);
            $dumper->Varname('    ');
            $dumper->Pair(' => ');
            $data = $dumper->Dump;
        }
    }
    $data =~ s/\s+$//s;
    return $data;
}

sub toString
{
    my $this    = shift;
    my %params  = @_;
    my $logPrefix = '['.sprintf('%-9s', $this->getLogLevel).'] ';
    my $data = $this->{'data'};
    $data =~ s/\n/\n$logPrefix/g;
    return $logPrefix.$data;
}

sub getLogLevel
{
    my $this = shift;
    if($logLevels->{$this->{'level'}} and $logLevels->{$this->{'level'}}->{'name'})
    {
        my $logLevel = ucfirst(lc($logLevels->{$this->{'level'}}->{'name'}.''));
        $logLevel =~ s/_(\w)/\u$1/g;
        return $logLevel;
    }
    return 'Unknown';
}

sub init
{
    $logLevels = {
        0 => {
            'type' => 'critical',
            'name' => 'Critical',
        },
        1 => {
            'type' => 'warn',
            'name' => 'Warn',
        },
        2 => {
            'type' => 'important',
            'name' => 'Important',
        },
        3 => {
            'type' => 'log',
            'name' => 'Log',
        },
        4 => {
            'type' => 'info',
            'name' => 'Info',
        },
        5 => {
            'type' => 'program_state',
            'name' => 'PrgState',
        },
        6 => {
            'type' => 'debug_critical',
            'name' => 'DbgCrit',
        },
        7 => {
            'type' => 'debug_important',
            'name' => 'DbgImport',
        },
        8 => {
            'type' => 'debug',
            'name' => 'DbgLog',
        },
        9 => {
            'type' => 'debug_state',
            'name' => 'DbgState',
        },
        10 => {
            'type' => 'debug_debug',
            'name' => 'DbgDebug',
        },
    };
    foreach my $code (keys %$logLevels)
    {
        my $logLevelSnakeCase = lc $logLevels->{$code}->{'type'}.'';
        my $logLevelCamelCase = $logLevelSnakeCase;
        $logLevelCamelCase =~ s/_(\w)/\u$1/g;
        my @logLevelList = ();
        foreach my $logLevel ($logLevelSnakeCase, uc $logLevelSnakeCase, ucfirst $logLevelCamelCase, $logLevelCamelCase)
        {
            if(not grep { $_ eq $logLevel } @logLevelList)
            {
                push @logLevelList, $logLevel;
            }
        }
        foreach my $logLevel (@logLevelList)
        {
            no warnings 'once';
            no strict qw(refs);
            my $funcResult = __PACKAGE__.'::'.$logLevel;
            *$funcResult = sub { 
                my $Logger = Logger->new($code, @_);
                print STDERR $Logger->toString()."\n";
            };
        }
    }
}

BEGIN
{
    init();
}


return 1;

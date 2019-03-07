package Result;
use strict;
use warnings;
use lib '/perllib';
use Data::Dumper;

use overload (
    'fallback' => 1,
    'bool' => \&toBool,
    '""' => \&toString,
);

my $exceptionTypes;

sub new
{
    my $type = shift;
    my %params = @_;
    if (scalar @_ == 1  and ref $_[0] eq 'HASH' )
    {
        %params = %{ $_[0] };
    }
    my $class = ref($type) || $type || 'Result';
 
    my $start = 0;
    my @caller0;
    my @caller1;
    do {
        @caller0 = caller( $start+0);
        @caller1 = caller( $start+1);
        $start++
    }
    while(scalar(caller( $start+1)) and $caller0[0] eq 'Result' and $start < 10);

    my $this = {
        'status' => $params{'status'},
        'value'  => $params{'value'},
        'msg'    => $params{'msg'},
        'caller' => {
            'package'   => $caller0[0],
            'filename'  => $caller0[1],
            'line'      => $caller0[2],
            'function'  => $caller1[3],
        },
        'trace'  => undef,
    };
    if ($this->{'status'} >= 200 )
    {
        require Carp;
        my $trace = Carp::longmess('full stack trace : ');
        $trace =~ s/\s+$//s;
        $trace =~ s/\t/    /g;
        $this->{'trace'} = $trace;
    }
    bless $this, $class;
    return $this;
}

sub status
{
    my $this = shift;
    return $this->{'status'};
}

sub value
{
    my $this = shift;
    return $this->{'value'};
}

sub msg
{
    my $this = shift;
    return $this->{'msg'};
}

sub toBool
{
    my $this = shift;
    if($this->{'status'} >= 100 and $this->{'status'} < 200)
    {
        return 1;
    }
    return 0;
}

sub toString
{
    my $this    = shift;
    my %params  = @_;
    my $type = 'error';
    if($this->{'status'} < 200)
    {
        $type = 'success';
    }
    my $exceptionType = $this->exceptionType;
    my $return = '<Result::'.$type.' exceptionType=\''.$exceptionType.'\' status=\''.$this->{'status'}.'\'>'."\n";
    $return .= '    <caller>'.$this->getCaller.'</caller>'."\n";
    if($type ne 'success')
    {
        my $trace = $this->{'trace'};
        $trace =~ s/\n/\n    /g;
        $return .= '    <trace>'."\n";
        $return .= '        '.$trace."\n";
        $return .= '    </trace>'."\n";
    }
    my $message = $this->{'msg'} || '';
    $return .= '    <messages>'."\n";
    $return .= '        <message>'.$message.'</message>'."\n";
    $return .= '    </messages>'."\n";
    if($type eq 'success')
    {
        my $value = $this->{'value'} || '';
        if (ref $value)
        {
            $value = Logger::formatData('data' => $value);
            $value =~ s/\s+$//s;
        }
        $return .= '    <value>'.$value.'</value>'."\n";
    }
    $return .= '</Result::'.$type.'>';
    return $return;
}

sub getCaller
{
    my $this = shift;
    my $function = $this->{'caller'}->{'function'} || '_MAIN_';
    return $function.' at ('.$this->{'caller'}->{'filename'}.':'.$this->{'caller'}->{'line'}.')';
}

sub httpCode
{
    my $this = shift;
    if($exceptionTypes->{$this->{'status'}} and $exceptionTypes->{$this->{'status'}}->{'httpCode'})
    {
        return $exceptionTypes->{$this->{'status'}}->{'httpCode'};
    }
    return 500;
}

sub exceptionType
{
    my $this = shift;
    if($exceptionTypes->{$this->{'status'}} and $exceptionTypes->{$this->{'status'}}->{'name'})
    {
        my $exceptionType = ucfirst(lc($exceptionTypes->{$this->{'status'}}->{'name'}.''));
        $exceptionType =~ s/_(\w)/\u$1/g;
        return $exceptionType;
    }
    return $this->{'status'};
}

sub init
{
    $exceptionTypes = {
        100 => {
            'name'     => 'SUCCESS',
            'aliases'  => [qw/OK/],
            'httpCode' => 200,
        },
        201 => {
            'name'     => 'MISSING_ARGUMENT',
            'aliases'  => [qw/MISSING_ARGUMENTS MISSING_PARAMETER MISSING_PARAMETERS/],
            'httpCode' => 400,
        },
        202 => {
            'name'     => 'INVALID_ARGUMENT',
            'aliases'  => [qw/INVALID_ARGUMENTS INVALID_PARAMETER INVALID_PARAMETERS/],
            'httpCode' => 400,
        },
        203 => {
            'name'     => 'INCOMPATIBLE_PARAMETERS',
            'httpCode' => 400,
        },
        204 => {
            'name'     => 'UNCONSISTENT_DATA',
            'httpCode' => 400,
        },
        210 => {
            'name'     => 'OBJECT_NOT_FOUND',
            'aliases'  => [qw/NOT_FOUND NOTFOUND/],
            'httpCode' => 404,
        },
        211 => {
            'name'     => 'OBJECT_ALREADY_EXISTS',
            'aliases'  => [qw/ALREADY_EXISTS ALREADYEXISTS/],
            'httpCode' => 409,
        },
        212 => {
            'name'     => 'NO_CHANGE',
            'aliases'  => [qw/NOCHANGE/],
            'httpCode' => 409,
        },
        241 => {
            'name'     => 'ACTION_IMPOSSIBLE',
            'httpCode' => 403,
        },
        250 => {
            'name'     => 'NOT_IMPLEMENTED',
            'httpCode' => 501,
        },
        401 => {
            'name'     => 'PERMISSION_DENIED',
            'httpCode' => 403,
        },
        500 => {
            'name'     => 'INTERNAL_ERROR',
            'httpCode' => 500,
        },
    };
    foreach my $status (keys %$exceptionTypes)
    {
        my @exceptionNames = ($exceptionTypes->{$status}->{'name'});
        if($exceptionTypes->{$status}->{'aliases'} and scalar @{$exceptionTypes->{$status}->{'aliases'}})
        {
            push @exceptionNames, @{$exceptionTypes->{$status}->{'aliases'}};
        }
        foreach my $exceptionName (@exceptionNames)
        {
            my $exceptionTypeSnakeCase = lc($exceptionName.'');
            my $exceptionTypeCamelCase = $exceptionTypeSnakeCase;
            $exceptionTypeCamelCase =~ s/_(\w)/\u$1/g;
            my $exceptionTypeHuman = ucfirst($exceptionTypeSnakeCase.'');
            $exceptionTypeHuman =~ s/_(\w)/ \u$1/g;
            my @exceptionTypeList = ();
            foreach my $exceptionType ($exceptionTypeSnakeCase, uc $exceptionTypeSnakeCase, ucfirst $exceptionTypeCamelCase, $exceptionTypeCamelCase)
            {
                if(not grep { $_ eq $exceptionType } @exceptionTypeList)
                {
                    push @exceptionTypeList, $exceptionType;
                }
            }
            foreach my $exceptionType (@exceptionTypeList)
            {
                no warnings 'once';
                no strict qw(refs);
                my $funcStatus = __PACKAGE__.'::status::'.$exceptionType;
                *$funcStatus = sub { return $status; };
                my $funcResult = __PACKAGE__.'::'.$exceptionType;
                *$funcResult = sub { 
                    my $class = shift;
                    if($status < 200)
                    {
                        my $value = shift;
                        return Result->new(
                            'status' => $status,
                            'value'  => $value
                        );
                    }
                    else
                    {
                        my $msg = shift || $exceptionTypeHuman;
                        return Result->new(
                            'status' => $status,
                            'msg'    => $msg,
                        );
                    }
                };
            }
        }
    }
}

BEGIN
{
    init();
}


return 1;

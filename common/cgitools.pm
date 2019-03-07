package cgitools;
use strict;
use warnings;
use lib '/perllib';
use JSON::XS;
use CGI;
use common::Result;
use common::Logger;

use Encode;

sub promptJson
{
    my (%params ) = @_;

    my $fnret     = $params{'fnret'};
    my $max_depth = $params{'max_depth'};
    my $res = {};
    my $httpCode = 200;
    if( ref $fnret eq 'Result' )
    {
        if($fnret)
        {
            my $content = JSON->new->utf8(1)->allow_nonref->encode($fnret->value);
            $content = decode('utf-8', $content, Encode::FB_DEFAULT);
            $content = decode('utf-8', $content, Encode::FB_DEFAULT);
            $content = JSON->new->utf8(0)->allow_nonref->decode($content);
            $res = $content;
        }
        else
        {
            $httpCode  		 = $fnret->httpCode;
            $res->{'status'} = $fnret->exceptionType;
            $res->{'msg'}    = (not $fnret)?$fnret->msg:$fnret->value;
        }
    }
    else
    {
        $res = $fnret;
    }
    
    my $json = new JSON::XS;
    if( $max_depth)
    {
        Logger::log('max_depth forced to '.$max_depth);
        $json->max_depth($max_depth);
    }

    my $output = $json->allow_nonref->convert_blessed(1)->encode($res);
   
    print CGI::header({-type => 'application/json', -status => $httpCode});

    print $output;

    return $fnret;
}

sub promptHtml
{
    my (%params ) = @_;

    my $fnret     = $params{'fnret'};
    my $res = {};
    my $httpCode = 200;
    if( ref $fnret eq 'Result' )
    {
        $httpCode = $fnret->httpCode;
        $res = (not $fnret)?$fnret->msg:$fnret->value;
    }
    else
    {
        $res = $fnret;
    }
    
    print CGI::header({-type => 'text/html', -status => $httpCode});
    print $res;
    return $fnret;
}

1;

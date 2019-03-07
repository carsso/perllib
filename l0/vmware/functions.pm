package l0::vmware::functions;

use strict;
use warnings;

use lib '/perllib';

sub connectToVcenter
{
    return l0::vmware::functions::connect(@_);
}

sub connect
{

}

sub disconnectFromVcenter
{
    return l0::vmware::functions::disconnect(@_);
}

sub disconnect
{
}

sub loadSdk
{
}

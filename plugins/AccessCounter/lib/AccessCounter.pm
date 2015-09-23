package AccessCounter;

use strict;
use MT;
use MT::App;

@AccessCounter::ISA = qw(MT::App);

sub init_request
{
    my $app = shift;
       $app->SUPER::init_request(@_);
       $app->add_methods( AccessCounter => \&_AccessCounter );
       $app->{default_mode} = 'AccessCounter';
       $app->{requires_login} = 0;
       $app;
}

sub _AccessCounter
{
    my $app = shift;
    my $q   = $app->param;

    return '//Search Engine'             if ($ENV{'HTTP_USER_AGENT'} =~ m/(bot[\/\-]|spider|crawl|slurp)/i);
    return '//Invalid request: blog_id'  unless $app->param('blog_id');
    return '//Invalid request: entry_id' unless $app->param('id');
    return '//Invalid request: mode'     if ( ! ( $q->param('mode') eq 'tracking' ) );

    my $plugin  = MT::Plugin::AccessCounter->instance;
    return '' unless($plugin->get_config_value('tracking', 'blog:' . $q->param('blog_id')));

    my $deny_ip = $plugin->get_config_value('deny_ip', 'blog:' . $q->param('blog_id'));;

    my $remote  = $ENV{'REMOTE_ADDR'};
    my $domain  = gethostbyaddr(pack('C4',split(/\./,$remote)),2) || $remote;

    my @deny_ip = split /\r?\n/, $deny_ip;
    foreach my $ip (@deny_ip)
    {
        next if $ip =~ m/^#/;
        if ($ip =~ m/^\d{1,3}\.(?:\d{1,3}\.(?:\d{1,3}\.(?:\d{1,3})?)?)?$/)
        {
            if (defined $remote && ($remote =~ m/^\Q$ip\E/))
            {
                return "//Deny Ip Address: ".$remote;
            }
        } elsif ($ip =~ m/\w/) {
            if (defined $domain && ($domain =~ m/\Q$ip\E$/))
            {
                return "//Deny Domain: ".$domain;
            }
        }
    }
    return AccessCounter::save_access($app, $q);
}

sub save_access
{
    my $app = shift;
    my $q = shift;

    my $entry = $app->model('entry')->load({id => $q->param('id'),});
    return "Invalid request: entry" unless $entry;

    my $ac = $entry->accessed_count ? $entry->accessed_count : 0;
       $entry->accessed_count($ac+1);

    my @ts = MT::Util::offset_time_list(time, $q->param('blog_id'));
    my $ts = sprintf '%04d-%02d-%02d %02d:%02d:%02d', $ts[5]+1900, $ts[4]+1, @ts[3,2,1,0];
       $entry->last_accessed_on($ts);
       $entry->save();

    return '//sucess';
}

package MT::Plugin::AccessCounter;

use strict;

use base qw( MT::Plugin );
use MT::Util qw( format_ts );

our $VERSION = '1.05';

my $plugin;
{
    my $settings = [
        ['tracking',      { Default => 0,  Scope => 'blog'}],
        ['deny_ip',       { Default => q{# This matches all 192.168.*.* IP addresses.
192.168.
}, Scope => 'blog'}],
    ];
    my $about = {
        name                   => 'Access Counter',
        id                     => 'AccessCounter',
        key                    => __PACKAGE__,
        author_name            => 'morimasato',
        author_link            => 'https://github.com/morimasato/mt-plugin-accesscounter',
        version                => $VERSION,
        blog_config_template   => 'config.tmpl',
        settings               => MT::PluginSettings->new($settings),
        schema_version         => '1.01',
        l10n_class             => 'AccessCounter::L10N',
        registry => {
            object_types => {
                'entry' => {
                    'last_accessed_on' => 'datetime not null default 20000101000000',
                    'accessed_count' => 'integer not null default 0',
                },
            },
            upgrade_functions => {
                'init_access_counter' => {
                    version_limit => '1.01',
                    code => \&_init_access_counter
                },
            },
            callbacks => {
                'BuildPage' => \&_add_tracking_tag,
                'MT::App::CMS::template_source.edit_entry' => {
                       handler => \&_add_accessed_count_edit_entry,
                       priority => 10,
                },
                'MT::App::CMS::template_source.entry_table' => {
                       handler => \&_add_accessed_count_entry_table,
                       priority => 10,
                },
                'MT::App::CMS::template_param.edit_entry' => {
                       handler => \&_format_last_accessed_on,
                       priority => 10,
                },
            },
            tags => {
                function => {
                    'AccessedCount' => \&_accessed_count,
                },
            },
            list_properties => {
                entry => {
                    'accessed_count' => {
                        label => 'Counts',
                        auto => 1,
                    },
                },
            },
        },
    };
    $plugin = __PACKAGE__->new($about);
}
MT->add_plugin($plugin);

#--- plugin handlers

sub instance {
    return $plugin;
}

sub description {
    my $plugin = shift;
    my $app = MT->instance;
    my $blog;
    if ($app->isa('MT::App::CMS')) {
        $blog = $app->blog;
    }
    my $desc = $plugin->translate('<p>This plugin enables Access Ranking: tally up the accessed count. Additionally, you can sort entries by their accessed count.</p><pre><code>&#60;mt:Entries <strong>sort_by=&#34;accessed_count&#34;</strong>&#62;<br />...<br />&#60;/mt:Entries&#62;</code></pre>');

    return $desc;
}

sub save_config {
    my $plugin = shift;
    my ($args, $scope) = @_;

    my $app = MT->instance;
    return $plugin->SUPER::save_config(@_);
}

sub _init_access_counter
{
    my $app = MT->instance;
    my $blog_class = $app->model('blog');
    my $entry_class = $app->model('entry');

    my @blogs = $blog_class->load;
    for my $blog (@blogs)
    {
        my @entrys = $entry_class->load({ blog_id => $blog->id },);
        for my $entry (@entrys)
        {
            unless ($entry->last_accessed_on)
            {
                $entry->last_accessed_on('20000101000000');
                $entry->accessed_count(0);
                $entry->save;
            }
        }
    }
}

sub _add_tracking_tag
{
    my ($eh, %args) = @_;

    return unless $args{blog} && $plugin->get_config_value('tracking', 'blog:' . $args{blog}->id);
    return unless $args{entry};

    my $path  = MT::ConfigMgr->instance->CGIPath;
       $path .= '/' unless $path =~ m!/$!;
       $path  =~ s!^https?://[^/]+(/.*)$!$1!;
    my $track = '<script type="text/javascript" src="'.$path.'plugins/AccessCounter/AccessCounter.cgi?mode=tracking&blog_id='.$args{blog}->id.'&id='.$args{entry}->id.'"></script>';

    my $text  = $args{content};
    $$text    =~ s!</body>!$track\n</body>!i;

    return 1;
}

sub _add_accessed_count_edit_entry
{
    my ($cb, $app, $tmpl) = @_;
    my $q = $app->param;
    return unless($plugin->get_config_value('tracking', 'blog:' . $q->param('blog_id')));

    my ($src, $new, $old);
    $src = <<'HTML';
    <mt:if name="object_type" eq="page">
        <$MTApp:PageActions from="edit_page"$>
    <mt:else>
        <$MTApp:PageActions from="edit_entry"$>
    </mt:if>
HTML
    $new = <<'HTML';
        <mt:unless name="new_object">
<div id="publishing-field"<mt:unless name="disp_prefs_show_publishing"> class="hidden"</mt:unless>>
    <mtapp:widget
        id="entry-publishing-widget"
        label="<__trans phrase="Accessed Count">">

        <$mt:setvar name="accessed_count_label" value="<__trans phrase="Counts">"$>
        <mtapp:setting
            id="accessed_count"
            label="$accessed_count_label">
            <input name="accessed_count" id="accessed_count" tabindex="20" value="<$mt:var name="accessed_count" escape="html"$>" />
        </mtapp:setting>

        <$mt:setvar name="last_accessed_on_label" value="<__trans phrase="Last Accessed">"$>
        <mtapp:setting
            id="last_accessed_on"
            label="$last_accessed_on_label"
            help_page="entries"
            help_section="date">
            <span class="date-time-fields"><$mt:var name="last_accessed_on" escape="html"$></span>
        </mtapp:setting>
    </mtapp:widget>
</div>
        </mt:unless>
HTML

    $new =~ s/<__trans phrase="Accessed Count">/$plugin->translate("Accessed Count")/eg;
    $new =~ s/<__trans phrase="Counts">/$plugin->translate("Counts")/eg;
    $new =~ s/<__trans phrase="Last Accessed">/$plugin->translate("Last Accessed")/eg;
    $old = quotemeta($src);
    $$tmpl =~ s/$old/$new$src/s;

    #MT5.0/MT5.1
    $src = <<'HTML';
<mt:if name="object_type" eq="page">
    <$MTApp:PageActions from="edit_page"$>
<mt:else>
    <$MTApp:PageActions from="edit_entry"$>
</mt:if>
HTML
    $new = <<'HTML';
        <mt:unless name="new_object">
<div id="publishing-field"<mt:unless name="status_publish"> class="hidden"</mt:unless>>
    <mtapp:widget
        id="entry-publishing-widget"
        label="<__trans phrase="Accessed Count">">

        <$mt:setvar name="accessed_count_label" value="<__trans phrase="Counts">"$>
        <mtapp:setting
            id="accessed_count"
            label="$accessed_count_label"
            label_class="top-label">
            <input name="accessed_count" id="accessed_count" tabindex="20" value="<$mt:var name="accessed_count" escape="html"$>" />
        </mtapp:setting>

        <$mt:setvar name="last_accessed_on_label" value="<__trans phrase="Last Accessed">"$>
        <mtapp:setting
            id="last_accessed_on"
            label="$last_accessed_on_label"
            label_class="top-label"
            help_page="entries"
            help_section="date">
            <span class="date-time-fields"><$mt:var name="last_accessed_on" escape="html"$></span>
        </mtapp:setting>
    </mtapp:widget>
</div>
        </mt:unless>
HTML

    $new =~ s/<__trans phrase="Accessed Count">/$plugin->translate("Accessed Count")/eg;
    $new =~ s/<__trans phrase="Counts">/$plugin->translate("Counts")/eg;
    $new =~ s/<__trans phrase="Last Accessed">/$plugin->translate("Last Accessed")/eg;
    $old = quotemeta($src);
    $$tmpl =~ s/$old/$new$src/s;
}

sub _add_accessed_count_entry_table
{
    my ($cb, $app, $tmpl) = @_;
    my $q = $app->param;
    return unless($plugin->get_config_value('tracking', 'blog:' . $q->param('blog_id')));

    my ($src, $new, $old);
    $src = '<th class="view"><span><__trans phrase="View"></span></th>';
    $new = <<'HTML';
        <th class="view"><__trans phrase="AC"></th>
HTML
    $old = quotemeta($src);
    $$tmpl =~ s/$old/$new$src/s;

    $src = '<td class="view si status-view">';
    $new = <<'HTML';
        <td class="accessed_count"><$mt:var name="accessed_count" escape="html"$></td>
HTML
    $old = quotemeta($src);
    $$tmpl =~ s/$old/$new$src/s;

    #MT5.0
    $src = '<td class="view status-view">';
    $old = quotemeta($src);
    $$tmpl =~ s/$old/$new$src/s;
}

sub _format_last_accessed_on
{
    my ($cb, $app, $param, $tmpl) = @_;
    my $q  = $app->param;
    return unless($plugin->get_config_value('tracking', 'blog:' . $q->param('blog_id')));

    $param->{accessed_count}   = ($param->{accessed_count} =~ m/^\d+$/) ? $param->{accessed_count} : 0;
    $param->{last_accessed_on} = $param->{last_accessed_on} ? format_ts('%Y-%m-%d %H:%M:%S', $param->{last_accessed_on}, $q->param('blog_id'), 'en', 0) : '2000-01-01 00:00:00';
}

sub _accessed_count
{
    my ($ctx, $args) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    return $args && $args->{pad} ? (sprintf "%06d", $e->accessed_count) : $e->accessed_count;
}

1;

#!/usr/bin/env perl -wT
# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the Bugzilla Bug Tracking System.
#
# The Initial Developer of the Original Code is Netscape Communications
# Corporation. Portions created by Netscape are
# Copyright (C) 1998 Netscape Communications Corporation. All
# Rights Reserved.
#
# Contributor(s): Gervase Markham <gerv@gerv.net>
#

###############################################################################
# This CGI is a general template display engine. To display templates using it,
# put them in the "pages" subdirectory of en/default, call them
# "foo.<ctype>.tmpl" and use the URL page.cgi?id=foo.<ctype> , where <ctype> is
# a content-type, e.g. html.
###############################################################################

use strict;

use lib qw(. lib);

use Bugzilla;
use Bugzilla::Error;
use Bugzilla::Hook;
use Bugzilla::Search::Quicksearch;

###############
# Subroutines #
###############

# For quicksearch.html.
sub quicksearch_field_names {
    my $fields = Bugzilla::Search::Quicksearch->FIELD_MAP;
    my %fields_reverse;
    # Put longer names before shorter names.
    my @nicknames = sort { length($b) <=> length($a) } (keys %$fields);
    foreach my $nickname (@nicknames) {
        my $db_field = $fields->{$nickname};
        $fields_reverse{$db_field} ||= [];
        push(@{ $fields_reverse{$db_field} }, $nickname);
    }
    return \%fields_reverse;
}

###############
# Main Script #
###############

Bugzilla->login();

my $cgi = Bugzilla->cgi;
my $template = Bugzilla->template;

my $id = $cgi->param('id');
if ($id) {
    # Be careful not to allow directory traversal.
    if ($id =~ /\.\./) {
        # two dots in a row is bad
        ThrowCodeError("bad_page_cgi_id", { "page_id" => $id });
    }
    # Split into name and ctype.
    $id =~ /^([\w\-\/\.]+)\.(\w+)$/;
    if (!$2) {
        # if this regexp fails to match completely, something bad came in
        ThrowCodeError("bad_page_cgi_id", { "page_id" => $id });
    }

    my %vars = ( 
      quicksearch_field_names => \&quicksearch_field_names,
    );
    Bugzilla::Hook::process('page_before_template', 
                            { page_id => $id, vars => \%vars });

    my $format = $template->get_format("pages/$1", undef, $2);
    
    $cgi->param('id', $id);

    print $cgi->header($format->{'ctype'});

    $template->process("$format->{'template'}", \%vars)
      || ThrowTemplateError($template->error());
}
else {
    ThrowUserError("no_page_specified");
}

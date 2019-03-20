package Koha::Plugin::Com::ByWaterSolutions::RepeatableMarcReport;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;
use Koha::Libraries;
use Koha::Patron::Categories;
use C4::Biblio;
use MARC::Record;
use MARC::Field;

## Here we set our plugin version
our $VERSION = "{VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Repeatable marc report',
    author => 'Barton Chittenden',
    description =>
'This plugin allows repeatable marc fields to be queried and exported',
    date_authored   => '2019-02-08',
    date_updated    => '1900-01-01',
    minimum_version => '17.05.00.000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('next') ) {
        $self->report_step1();
    }
    elsif ( $cgi->param('next') == 2 ) {
        $self->report_step2();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

#    We don't have any extra setup

}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;
#   Nothing to clean up

}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report-step1.tt' });
    $template->param(
        name => $self->{metadata}->{name},
    );

    print $cgi->header();
    print $template->output();
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;

    my $report    = $cgi->param('report_id');
    my $tag       = $cgi->param('marc_tag');
    my $subfield  = $cgi->param('marc_subfield');
    my $output    = $cgi->param('output') || "";

    my $query = "
        SELECT savedsql FROM saved_sql WHERE id=?
    ";

    my $sth = $dbh->prepare($query);
    $sth->execute($report);

    my $count = 0;
    my @results;
    my $error = '';
    my $selected_report;
    while ( $selected_report = $sth->fetchrow_hashref() ) {
        warn Data::Dumper::Dumper( $selected_report);
        $error = "Report $report:\n[$selected_report->{savedsql}]\n\ndoes not contain 'biblionumber'" unless $selected_report->{savedsql} =~ /biblionumber/;
        last; # there should only be one row
    }

    my $prepare_error;
    my $sth2 = $dbh->prepare($selected_report->{savedsql}); 
    $prepare_error = $dbh->errstr if $dbh->errstr;

    my $execute_error;
    $sth2->execute();
    $execute_error = $dbh->errstr if $dbh->errstr;

    my $headers =  $sth2->{NAME};
    my $index=0;
    for my $header ( @{$headers}) {
        last if $header eq 'biblionumber';
        $index++;
    }
    push @{$headers}, "$tag\$$subfield";
    warn "heders: $headers";
    # Look up index of biblionumber here.
    while ( my $row = $sth2->fetchrow_arrayref() ) {
        my $biblionumber = @{$row}[$index];
        my $rec = GetMarcBiblio($biblionumber);
        my @fields = $rec->field( $tag );
        for my $field ( @fields ) {
            for my $sub ( $field->subfield("$subfield") ) {
                push( @results, [@$row, $sub ] );
            }
        }
    }

    my $filename;
    if ( $output eq "csv" ) {
        print $cgi->header( -attachment => 'borrowers.csv' );
        $filename = 'report-step2-csv.tt';
    }
    else {
        print $cgi->header();
        $filename = 'report-step2-html.tt';
    }
    my $template = $self->get_template({ file => $filename });
    $template->param(
        name => $self->{metadata}->{name},
        result_headers => $headers,
        result_loop   => \@results,
        execute_error => $execute_error,
        prepare_error => $prepare_error,
    );

    print $cgi->header();
    print $template->output();
}

1;

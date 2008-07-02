package Chart::Clicker::Decoration::Glass;
use Moose;

extends 'Chart::Clicker::Decoration';

use Chart::Clicker::Context;
use Chart::Clicker::Drawing::Color;

has 'background_color' => ( is => 'rw', isa => 'Chart::Clicker::Drawing::Color' );
has 'glare_color' => (
    is => 'rw',
    isa => 'Chart::Clicker::Drawing::Color',
    default => sub {
        Chart::Clicker::Drawing::Color->new(
            red => 1, green => 1, blue => 1, alpha => 1
        )
    },
    coerce => 1
);

sub prepare {
    my $self = shift();
    my $clicker = shift();
    my $dimension = shift();

    $self->width($dimension->width());
    $self->height($dimension->height());

    return 1;
}

sub draw {
    my $self = shift();
    my $clicker = shift();

    my $cr = $clicker->context();

    if($self->background_color()) {
        $cr->set_source_rgba($self->background_color->as_array_with_alpha());
        $cr->fill();
    }

    my $twentypofheight = $self->height() * .20;

    $cr->move_to(1, $twentypofheight);
    $cr->rel_curve_to(
        0, 0, $self->width() / 2, -$self->height() * .30,
        $self->width(), 0
    );
    $cr->line_to($self->width(), 0);
    $cr->line_to(0, 0);
    $cr->line_to(0, $twentypofheight);

    $cr->set_source_rgba($self->glare_color->as_array_with_alpha());
    $cr->fill();
}

1;
__END__

=head1 NAME

Chart::Clicker::Decoration::Grid

=head1 DESCRIPTION

Generates a collection of Markers for use as a background.

=head1 SYNOPSIS

=head1 METHODS

=head2 Constructor

=over 4

=item new

Creates a new Chart::Clicker::Decoration::Grid object.

=item prepare

Prepare this Grid for drawing

=back

=head2 Class Methods

=over 4

=item color

Set/Get the color for this Grid.

=item domain_ticks

Set/Get the domain ticks for this Grid.

=item range_ticks

Set/Get the range ticks for this Grid.

=item stroke

Set/Get the Stroke for this Grid.

=item draw

Draw this Grid.

=cut

=back

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head1 SEE ALSO

perl(1)

=head1 LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.

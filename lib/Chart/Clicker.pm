package Chart::Clicker;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;

extends 'Chart::Clicker::Drawing::Container';

use Layout::Manager::Compass;

use Graphics::Color::RGB;

use Graphics::Primitive::Insets;
use Graphics::Primitive::Border;

use Chart::Clicker::Decoration::Plot;
use Chart::Clicker::Format::Png;
use Chart::Clicker::Util;

use Chart::Clicker::Drawing::ColorAllocator;

use Cairo;

our $VERSION = '2.0.0';

subtype 'Format'
    => as 'Object'
    => where { $_->does('Chart::Clicker::Format') };

coerce 'Format'
    => from 'Str'
    => via {
        return Chart::Clicker::Util::load('Chart::Clicker::Format::'.$_)
    };

has 'color_allocator' => (
    is => 'rw',
    isa => 'Chart::Clicker::Drawing::ColorAllocator',
    default => sub { Chart::Clicker::Drawing::ColorAllocator->new()  }
);

has 'context' => (
    is => 'rw',
    isa => 'Chart::Clicker::Context',
    clearer => 'clear_context'
);

has 'datasets' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    provides => {
        'count'=> 'dataset_count',
        'push' => 'add_to_datasets',
        'get' => 'get_dataset'
    }
);

has 'dataset_domain_axes' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        'set' => 'set_dataset_domain_axis',
        'get' => 'get_dataset_domain_axis',
    }
);

has 'dataset_range_axes' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        'set' => 'set_dataset_range_axis',
        'get' => 'get_dataset_range_axis',
    }
);

has 'domain_axes' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Chart::Clicker::Axis]',
    default => sub { [] },
    provides => {
        'get' => 'get_domain_axis'
    }
);

has 'format' => (
    is      => 'rw',
    isa     => 'Format',
    coerce  => 1,
    default => sub { Chart::Clicker::Format::Png->new() }
);

has '+layout' => (
    default => sub { Layout::Manager::Compass->new() }
);

has 'markers' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Chart::Clicker::Data::Marker]',
    default => sub { [] },
    provides => {
        'count' => 'marker_count',
        'push'  => 'add_to_markers'
    }
);

has 'marker_domain_axes' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        'set' => 'set_marker_domain_axis',
        'get' => 'get_marker_domain_axis'
    }
);

has 'marker_range_axes' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        'set' => 'set_marker_range_axis',
        'get' => 'get_marker_range_axis'
    }
);

has 'plot' => (
    is => 'rw',
    isa => 'Chart::Clicker::Decoration::Plot',
    default => sub {
        Chart::Clicker::Decoration::Plot->new()
    }
);

has 'range_axes' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Chart::Clicker::Axis]',
    default => sub { [] },
    provides => {
        'get' => 'get_range_axis'
    }
);

has 'renderer_domain_axes' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has 'renderer_range_axes' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has '+width' => (
    default => 500
);

has '+height' => (
    default => 300
);

has '+border' => (
    default => sub {
        Graphics::Primitive::Border->new()
    }
);

has '+background_color' => (
    default => sub {
        Graphics::Color::RGB->new(
            { red => 1, green => 1, blue => 1, alpha => 1 }
        )
    }
);

# override('draw', sub {
#     my ($self) = @_;
# 
#     #super;
# 
#     # TODO This should be elsewhere...
#     my $width = $self->width();
#     my $height = $self->height();
# 
#     my $context = $self->context();
# 
#     if(defined($self->background_color())) {
#         $context->set_source_rgba($self->background_color->as_array_with_alpha());
#         $context->rectangle(0, 0, $width, $height);
#         $context->paint();
#     }
# 
#     my $x = 0;
#     my $y = 0;
#     my $bwidth = $width;
#     my $bheight = $height;
# 
#     my $margins = $self->margins();
#     my ($mx, $my, $mw, $mh) = (0, 0, 0, 0);
#     if($margins) {
#         $mx = $margins->left();
#         $my = $margins->top();
#         $mw = $margins->right();
#         $mh = $margins->bottom();
#     }
# 
#     if(defined($self->border())) {
#         my $stroke = $self->border();
#         my $bswidth = $stroke->width();
#         $context->set_source_rgba($self->border->color->as_array_with_alpha());
#         $context->set_line_width($bswidth);
#         $context->set_line_cap($stroke->line_cap());
#         $context->set_line_join($stroke->line_join());
#         $context->new_path();
#         my $swhalf = $bswidth / 2;
#         $context->rectangle(
#             $mx + $swhalf, $my + $swhalf,
#             $width - $bswidth - $mw - $mx, $height - $bswidth - $mh - $my
#         );
#         $context->stroke();
#     }
#     # TODO END This should be elsewhere...
# 
#     foreach my $c (@{ $self->components }) {
#         next unless defined($c);
# 
#         my $comp = $c->{component};
#         my $context = $self->context();
# 
#         $context->save;
#         $context->translate($comp->origin->x, $comp->origin->y);
#         $context->rectangle(0, 0, $comp->width, $comp->height);
#         $context->clip;
# 
#         $comp->draw();
# 
#         $context->restore();
#     }
# });

# sub draw {
#      my $self = shift();
# 
# }

# override('prepare', sub {
#     my $self = shift();
# 
#     my $plot = $self->plot();
# 
#     # Prepare the datasets and establish ranges for the axes.
#     my $count = 0;
#     foreach my $ds (@{ $self->datasets() }) {
#         unless($ds->count() > 0) {
#             die("Dataset $count is empty.");
#         }
# 
#         my $rend = $plot->get_renderer($plot->get_dataset_renderer($count) || 0);
#         if(!defined($rend)) {
#             die("Can't find a renderer, that's fatal!");
#         }
#         $ds->prepare();
# 
#         my $daxisnum = $self->get_dataset_domain_axis($count);
#         my $daxis = $self->get_domain_axis($daxisnum || 0);
#         if(defined($daxis)) {
#             $daxis->range->combine($ds->domain());
#         }
# 
#         my $raxisnum = $self->get_dataset_range_axis($count);
#         my $raxis = $self->get_range_axis($raxisnum || 0);
# 
#         if(defined($raxis)) {
#             if($rend->additive()) {
#                 $raxis->range->combine($ds->combined_range());
#             } else {
#                 $raxis->range->combine($ds->range());
#             }
#         }
# 
#         $count++;
#     }
# 
#     $self->format->surface(
#         $self->format->create_surface($self->width, $self->height)
#     );
#     $self->context(Chart::Clicker::Context->create($self->format->surface()));
# 
#     foreach my $c (@{ $self->components }) {
#         $c->{component}->clicker($self);
#     }
# 
#     super;
# 
#     return 1;
# });

sub write {
    my $self = shift();
    my $file = shift();

    return $self->format->write($self, $file);
}

sub data {
    my $self = shift();

    return $self->format->surface_data();
}

1;

__END__

=head1 NAME

Chart::Clicker - Powerful, extensible charting.

=head1 DESCRIPTION

Chart::Clicker aims to be a powerful, extensible charting package that creates
really pretty output.  Charts can be saved in png, svg, pdf and postscript
format.

Clicker leverages the power of Cairo to create snazzy 2D graphics easily and
quickly.

At it's core Clicker is more of a toolkit for creating charts.  It's interface
is a bit more complex because making pretty charts requires attention and care.
Some fine defaults are established to make getting started easier, but to really
unleash the potential of Clicker you must roll up your sleeves and build
things by hand.

The API is a bit intimidating, so it is recommended that you begin with
L<Chart::Clicker::Simple>.

=head1 WARNING

Clicker has aspirations to do more and be better.  Good software is not Athena
and therefore doesn't spring fully formed from the mind.  It is entirely
possible that new features will be added that may change behavior. You can
find more information at L<http://www.onemogin.com/clicker>.  Feel free to
send your criticisms, advice, patches or money to me as a way of helping.

=head1 FORMATS

Clicker supports PNG and SVG output.

=head1 SYNOPSIS

  use Chart::Clicker;
  use Chart::Clicker::Axis;
  use Chart::Clicker::Data::DataSet;
  use Chart::Clicker::Data::Series;
  use Chart::Clicker::Decoration::Grid;
  use Chart::Clicker::Decoration::Legend;
  use Chart::Clicker::Decoration::Plot;
  use Chart::Clicker::Drawing qw(:positions);
  use Chart::Clicker::Drawing::Insets;
  use Chart::Clicker::Renderer::Area;

  my $chart = Chart::Clicker->new({ format => 'Png', width => 500, height => 350 });

  my $series = Chart::Clicker::Data::Series->new({
    keys    => [1, 2, 3, 4, 5, 6],
    values  => [12, 9, 8, 3, 5, 1]
  });

  my $dataset = Chart::Clicker::Data::DataSet->new({
    series => [ $series ]
  });
  $chart->datasets([ $dataset ]);

  my $legend = Chart::Clicker::Decoration::Legend->new({
    margins => Chart::Clicker::Drawing::Insets->new({
        top => 3
    })
  });
  $chart->add($legend, $CC_BOTTOM);

  my $daxis = Chart::Clicker::Axis->new({
    orientation => $CC_HORIZONTAL,
    position    => $CC_BOTTOM,
    format      => '%0.2f'
  });
  $chart->add($daxis, $CC_AXIS_BOTTOM);

  my $raxis = Chart::Clicker::Axis->new({
    orientation => $CC_VERTICAL,
    position    => $CC_LEFT,
    format      => '%0.2f'
  });
  $chart->add($raxis, $CC_AXIS_LEFT);

  $chart->range_axes([ $raxis ]);
  $chart->domain_axes([ $daxis ]);

  my $grid = Chart::Clicker::Decoration::Grid->new();
  $chart->add($grid, $CC_CENTER, 0);

  my $renderer = Chart::Clicker::Renderer::Area->new(fade => 1);

  my $plot = Chart::Clicker::Decoration::Plot->new();
  $plot->renderers([$renderer]);
  $chart->plot($plot);

  $chart->add($plot, $CC_CENTER);

  $chart->prepare();
  $chart->draw();
  $chart->write('/path/to/chart.png');

=cut

=head1 METHODS

=head2 Constructor

=over 4

=item new

Creates a new Chart::Clicker object. If no format, width and height are
specified then defaults of Png, 500 and 300 are chosen, respectively.

=back

=head2 Class Methods

=over 4

=item add_to_datasets

Add the specified dataset (or arrayref of datasets) to the chart.

=item add_to_markers

Add the specified marker to the chart.

=item color_allocator

Set/Get the color_allocator for this chart.

=item context

Set/Get the context for this chart.

=item data

Returns the data for this chart as a scalar.  Suitable for 'streaming' to a
client.

=item datasets

Get/Set the datasets for this chart.

=item draw

Draw this chart

=item I<format>

Get the format for this Chart.  Required in the constructor.  Must be on of
Png, Pdf, Ps or Svg.

=item get_dataset_domain_axis

  my $axis = $chart->get_dataset_domain_axis($index)

Returns the domain axis to which the specified dataset is affined.

=item get_dataset_range_axis

  my $axis = $chart->get_dataset_range_axis($index)

Returns the range axis to which the specified dataset is affined.

=item inside_width

Get the width available in this container after taking away space for
insets and borders.

=item inside_height

Get the height available in this container after taking away space for
insets and borders.

=item prepare

Prepare this chart for rendering.

=item set_dataset_domain_axis

  $chart->set_dataset_domain_axis($dataset_index, $axis_index)

Affines the dataset at the specified index to the domain axis at the second
index.

=item set_dataset_range_axis

  $chart->set_dataset_range_axis($dataset_index, $axis_index)

Affines the dataset at the specified index to the range axis at the second
index.

=item write

Write the chart output to the specified location. Output is written in the
format provided to the constructor (which defaults to Png).

  $c->write('/path/to/the.png');

=back

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head1 CONTRIBUTORS

Torsten Schoenfeld
Ash Berlin

=head1 SEE ALSO

perl(1)

=head1 LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.

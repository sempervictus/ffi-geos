# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class GeometryTests < MiniTest::Unit::TestCase
  include TestHelper

  def setup
    super
    writer.trim = true
  end

  def test_intersection
    comparison_tester(
      :intersection,
      'POLYGON ((5 10, 10 10, 10 5, 5 5, 5 10))',
      'POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))'
    )
  end

  def test_buffer
    simple_tester(
      :buffer,
      'POLYGON EMPTY',
      'POINT(0 0)',
      0
    )

    snapped_tester(
      :buffer,
      'POLYGON ((10 0, 10 -2, 9 -4, 8 -6, 7 -7, 6 -8, 4 -9, 2 -10, 0 -10, -2 -10, -4 -9, -6 -8, -7 -7, -8 -6, -9 -4, -10 -2, -10 0, -10 2, -9 4, -8 6, -7 7, -6 8, -4 9, -2 10, 0 10, 2 10, 4 9, 6 8, 7 7, 8 6, 9 4, 10 2, 10 0))',
      'POINT(0 0)',
      10
    )

    # One segment per quadrant
    snapped_tester(
      :buffer,
      'POLYGON ((10 0, 0 -10, -10 0, 0 10, 10 0))',
      'POINT(0 0)',
      10,
      { :quad_segs => 1 }
    )

    # End cap styles
    snapped_tester(
      :buffer,
      'POLYGON ((100 10, 110 0, 100 -10, 0 -10, -10 0, 0 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :round }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((100 10, 100 -10, 0 -10, 0 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :flat }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((100 10, 110 10, 110 -10, 0 -10, -10 -10, -10 10, 100 10))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :quad_segs => 1, :endcap => :square }
    )

    # Join styles
    snapped_tester(
      :buffer,
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 0, 107 -7, 100 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :round }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 0, 100 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :bevel }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 110 -10, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :mitre }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((90 10, 90 100, 93 107, 100 110, 107 107, 110 100, 109 -5, 105 -9, 0 -10, -7 -7, -10 0, -7 7, 0 10, 90 10))',
      'LINESTRING(0 0, 100 0, 100 100)',
      10,
      { :quad_segs => 2, :join => :mitre, :mitre_limit => 1.0 }
    )

    # Single-sided buffering
    snapped_tester(
      :buffer,
      'POLYGON ((100 0, 0 0, 0 10, 100 10, 100 0))',
      'LINESTRING(0 0, 100 0)',
      10,
      { :single_sided => true }
    )

    snapped_tester(
      :buffer,
      'POLYGON ((0 0, 100 0, 100 -10, 0 -10, 0 0))',
      'LINESTRING(0 0, 100 0)',
      -10,
      { :single_sided => true }
    )
  end

  def test_convex_hull
    geom = read('POINT(0 0)')
    assert_geom_eql_exact(read('POINT(0 0)'), geom.convex_hull)

    geom = read('LINESTRING(0 0, 10 10)')
    assert_geom_eql_exact(read('LINESTRING(0 0, 10 10)'), geom.convex_hull)

    geom = read('POLYGON((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))')
    assert_geom_eql_exact(read('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))'), geom.convex_hull)
  end

  def test_difference
    comparison_tester(
      :difference,
      'GEOMETRYCOLLECTION EMPTY',
      'POINT(0 0)',
      'POINT(0 0)'
    )

    comparison_tester(
      :difference,
      'POINT (0 0)',
      'POINT(0 0)',
      'POINT(1 0)'
    )

    comparison_tester(
      :difference,
      'LINESTRING (0 0, 10 0)',
      'LINESTRING(0 0, 10 0)',
      'POINT(5 0)'
    )

    comparison_tester(
      :difference,
      'GEOMETRYCOLLECTION EMPTY',
      'POINT(5 0)',
      'LINESTRING(0 0, 10 0)'
    )

    comparison_tester(
      :difference,
      'POINT (5 0)',
      'POINT(5 0)',
      'LINESTRING(0 1, 10 1)'
    )

    comparison_tester(
      :difference,
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0))',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 -10, 5 10)'
    )

    comparison_tester(
      :difference,
      'LINESTRING (0 0, 5 0)',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 0, 20 0)'
    )

    comparison_tester(
      :difference,
      'POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(5 -10, 5 10)'
    )

    comparison_tester(
      :difference,
      'POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(10 0, 20 0)'
    )

    comparison_tester(
      :difference,
      'POLYGON ((5 0, 0 0, 0 10, 10 10, 10 5, 5 5, 5 0))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'
    )
  end

  def test_sym_difference
    %w{ sym_difference symmetric_difference }.each do |method|
      comparison_tester(
        method,
        'GEOMETRYCOLLECTION EMPTY',
        'POINT(0 0)',
        'POINT(0 0)'
      )

      comparison_tester(
        method,
        'MULTIPOINT (0 0, 1 0)',
        'POINT(0 0)',
        'POINT(1 0)'
      )

      comparison_tester(
        method,
        'LINESTRING (0 0, 10 0)',
        'LINESTRING(0 0, 10 0)',
        'POINT(5 0)'
      )

      comparison_tester(
        method,
        'LINESTRING (0 0, 10 0)',
        'POINT(5 0)',
        'LINESTRING(0 0, 10 0)'
      )

      comparison_tester(
        method,
        'GEOMETRYCOLLECTION (POINT (5 0), LINESTRING (0 1, 10 1))',
        'POINT(5 0)',
        'LINESTRING(0 1, 10 1)'
      )

      comparison_tester(
        method,
        'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (5 -10, 5 0), (5 0, 5 10))',
        'LINESTRING(0 0, 10 0)',
        'LINESTRING(5 -10, 5 10)'
      )

      comparison_tester(
        method,
        'MULTILINESTRING ((0 0, 5 0), (10 0, 20 0))',
        'LINESTRING(0 0, 10 0)',
        'LINESTRING(5 0, 20 0)'
      )

      comparison_tester(
        method,
        'GEOMETRYCOLLECTION (LINESTRING (5 -10, 5 0), POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0)))',
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
        'LINESTRING(5 -10, 5 10)'
      )

      comparison_tester(
        method,
        'GEOMETRYCOLLECTION (LINESTRING (10 0, 20 0), POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0)))',
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
        'LINESTRING(10 0, 20 0)'
      )

      comparison_tester(
        method,
        'MULTIPOLYGON (((5 0, 0 0, 0 10, 10 10, 10 5, 5 5, 5 0)), ((5 0, 10 0, 10 5, 15 5, 15 -5, 5 -5, 5 0)))',
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
        'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'
      )
    end
  end

  def test_boundary
    simple_tester(
      :boundary,
      'GEOMETRYCOLLECTION EMPTY',
      'POINT(0 0)'
    )

    simple_tester(
      :boundary,
      'MULTIPOINT (0 0, 10 10)',
      'LINESTRING(0 0, 10 10)'
    )

    simple_tester(
      :boundary,
      'MULTILINESTRING ((0 0, 10 0, 10 10, 0 10, 0 0), (5 5, 5 6, 6 6, 6 5, 5 5))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),( 5 5, 5 6, 6 6, 6 5, 5 5))'
    )
  end

  def test_union
    comparison_tester(
      :union,
      'POINT (0 0)',
      'POINT(0 0)',
      'POINT(0 0)'
    )

    comparison_tester(
      :union,
      'MULTIPOINT (0 0, 1 0)',
      'POINT(0 0)',
      'POINT(1 0)'
    )

    comparison_tester(
      :union,
      'LINESTRING (0 0, 10 0)',
      'LINESTRING(0 0, 10 0)',
      'POINT(5 0)'
    )

    comparison_tester(
      :union,
      'LINESTRING (0 0, 10 0)',
      'POINT(5 0)',
      'LINESTRING(0 0, 10 0)'
    )

    comparison_tester(
      :union,
      'GEOMETRYCOLLECTION (POINT (5 0), LINESTRING (0 1, 10 1))',
      'POINT(5 0)',
      'LINESTRING(0 1, 10 1)'
    )

    comparison_tester(
      :union,
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (5 -10, 5 0), (5 0, 5 10))',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 -10, 5 10)'
    )

    comparison_tester(
      :union,
      'MULTILINESTRING ((0 0, 5 0), (5 0, 10 0), (10 0, 20 0))',
      'LINESTRING(0 0, 10 0)',
      'LINESTRING(5 0, 20 0)'
    )

    comparison_tester(
      :union,
      'GEOMETRYCOLLECTION (LINESTRING (5 -10, 5 0), POLYGON ((5 0, 0 0, 0 10, 5 10, 10 10, 10 0, 5 0)))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(5 -10, 5 10)'
    )

    comparison_tester(
      :union,
      'GEOMETRYCOLLECTION (LINESTRING (10 0, 20 0), POLYGON ((10 0, 0 0, 0 10, 10 10, 10 0)))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(10 0, 20 0)'
    )

    comparison_tester(
      :union,
      'POLYGON ((5 0, 0 0, 0 10, 10 10, 10 5, 15 5, 15 -5, 5 -5, 5 0))',
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      'POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'
    )
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:union_cascaded)
    def test_union_cascaded

      simple_tester(
        :union_cascaded,
        'POLYGON ((1 0, 0 0, 0 1, 0 11, 10 11, 10 14, 14 14, 14 10, 11 10, 11 0, 1 0), (11 11, 12 11, 12 12, 11 12, 11 11))',
        'MULTIPOLYGON(
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11)),
          ((0 0, 11 0, 11 11, 0 11, 0 0))
        ))'
      )
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:unary_union)
    def test_unary_union

      simple_tester(
        :unary_union,
        'POLYGON ((1 0, 0 0, 0 1, 0 11, 10 11, 10 14, 14 14, 14 10, 11 10, 11 0, 1 0), (11 11, 12 11, 12 12, 11 12, 11 11))',
        'MULTIPOLYGON(
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11)),
          ((0 0, 11 0, 11 11, 0 11, 0 0))
        ))'
      )
    end
  end

  def test_union_without_arguments
    simple_tester(
      :union,
      'POLYGON ((1 0, 0 0, 0 1, 0 11, 10 11, 10 14, 14 14, 14 10, 11 10, 11 0, 1 0), (11 11, 12 11, 12 12, 11 12, 11 11))',
      'MULTIPOLYGON(
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)),
        ((0 0, 11 0, 11 11, 0 11, 0 0))
      ))'
    )
  end

  def test_point_on_surface
    %w{
      point_on_surface
      representative_point
    }.each do |method|
      simple_tester(
        method,
        'POINT (0 0)',
        'POINT (0 0)'
      )

      simple_tester(
        method,
        'POINT (5 5)',
        'LINESTRING (0 0, 5 5, 10 10)'
      )

      simple_tester(
        method,
        'POINT (2.5 5)',
        'POLYGON ((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))'
      )
    end
  end

  def test_centroid
    %w{
      centroid
      center
    }.each do |method|
      simple_tester(
        method,
        'POINT (0 0)',
        'POINT(0 0)'
      )

      simple_tester(
        method,
        'POINT (5 5)',
        'LINESTRING(0 0, 10 10)'
      )

      snapped_tester(
        method,
        'POINT (5 4)',
        'POLYGON((0 0, 0 10, 5 5, 10 10, 10 0, 0 0))'
      )
    end
  end

  def test_envelope
    simple_tester(
      :envelope,
      'POINT (0 0)',
      'POINT(0 0)'
    )

    simple_tester(
      :envelope,
      'POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))',
      'LINESTRING(0 0, 10 10)'
    )
  end

  def test_relate
    tester = lambda { |expected, geom_a, geom_b|
      assert_equal(expected, geom_a.relate(geom_b))
    }

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(0 0)')
    tester['0FFFFFFF2', geom_a, geom_b]

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(1 0)')
    tester['FF0FFF0F2', geom_a, geom_b]

    geom_a = read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')
    geom_b = read('POINT(1 0)')
    tester['FF20F1FF2', geom_a, geom_b]
  end

  def test_relate_pattern
    tester = lambda { |pattern, geom_a, geom_b, expected|
      assert_equal(expected, geom_a.relate_pattern(geom_b, pattern))
    }

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(0 0)')
    tester['0FFFFFFF2', geom_a, geom_b, true]
    tester['0*******T', geom_a, geom_b, true]
    tester['0*******1', geom_a, geom_b, false]

    geom_a = read('POINT(0 0)')
    geom_b = read('POINT(1 0)')
    tester['FF0FFF0F2', geom_a, geom_b, true]
    tester['F*******2', geom_a, geom_b, true]
    tester['T*******2', geom_a, geom_b, false]

    geom_a = read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')
    geom_b = read('POINT(1 0)')
    tester['FF20F1FF2', geom_a, geom_b, true]
    tester['F****T**T', geom_a, geom_b, true]
    tester['T*******2', geom_a, geom_b, false]
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:relate_boundary_node_rule)
    def test_relate_boundary_node_rule
      geom_a = read('LINESTRING(0 0, 2 4, 5 5, 0 0)')
      geom_b = read('POINT(0 0)')

      ret = geom_a.relate_boundary_node_rule(geom_b, :ogc)
      assert_equal('0F1FFFFF2', ret)

      ret = geom_a.relate_boundary_node_rule(geom_b, :endpoint)
      assert_equal('FF10FFFF2', ret)

      assert_raises(TypeError) do
        geom_a.relate_boundary_node_rule(geom_b, :gibberish)
      end
    end
  end

  def test_line_merge
    simple_tester(
      :line_merge,
      'LINESTRING (0 0, 10 10, 10 0, 5 0, 5 -5)',
      'MULTILINESTRING(
        (0 0, 10 10),
        (10 10, 10 0),
        (5 0, 10 0),
        (5 -5, 5 0)
      )'
    )
  end

  def test_simplify
    simple_tester(
      :simplify,
      'LINESTRING (0 0, 5 10, 10 0, 10 9, 0 9)',
      'LINESTRING(0 0, 3 4, 5 10, 10 0, 10 9, 5 11, 0 9)',
      2
    )
  end

  def test_topology_preserve_simplify
    simple_tester(
      :topology_preserve_simplify,
      'LINESTRING (0 0, 5 10, 10 0, 10 9, 5 11, 0 9)',
      'LINESTRING(0 0, 3 4, 5 10, 10 0, 10 9, 5 11, 0 9)',
      2
    )
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:extract_unique_points)
    def test_extract_unique_points
      geom = read('GEOMETRYCOLLECTION (
        MULTIPOLYGON (
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11))
        ),
        POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
        MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
        LINESTRING (0 0, 2 3),
        MULTIPOINT (0 0, 2 3),
        POINT (9 0),
        POINT(1 0)),
        LINESTRING EMPTY
      ')

      simple_tester(
        :extract_unique_points,
        'MULTIPOINT (0 0, 1 0, 1 1, 0 1, 10 10, 10 14, 14 14, 14 10, 11 11, 11 12, 12 12, 12 11, 2 3, 3 4, 9 0)',
        geom.extract_unique_points
      )
    end
  end

  def test_relationships
    tester = lambda { |geom_a, geom_b, tests|
      tests.each do |test|
        expected, method, args = test
        if ENV['FORCE_TESTS'] || geom_a.respond_to?(method)
          value = geom_a.send(method, *([ geom_b ] + Array(args)))
          assert_equal(expected, value)
        end
      end
    }

    tester[read('POINT(0 0)'), read('POINT(0 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [true, :contains?],
      [false, :overlaps?],
      [true, :eql?],
      [true, :eql_exact?, TOLERANCE],
      [true, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POINT(0 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [true, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POINT(5 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('LINESTRING(5 -5, 5 5)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [true, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('LINESTRING(5 0, 15 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [true, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('LINESTRING(0 0, 5 0, 10 0)'), read('LINESTRING(0 0, 10 0)'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [true, :within?],
      [true, :contains?],
      [false, :overlaps?],
      [true, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [true, :covers?],
      [true, :covered_by?]
    ]]

    tester[read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'), read('POLYGON((5 -5, 5 5, 15 5, 15 -5, 5 -5))'), [
      [false, :disjoint?],
      [false, :touches?],
      [true, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [true, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]

    tester[read('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'), read('POINT(15 15)'), [
      [true, :disjoint?],
      [false, :touches?],
      [false, :intersects?],
      [false, :crosses?],
      [false, :within?],
      [false, :contains?],
      [false, :overlaps?],
      [false, :eql?],
      [false, :eql_exact?, TOLERANCE],
      [false, :covers?],
      [false, :covered_by?]
    ]]
  end

  def test_empty
    refute_geom_empty(read('POINT(0 0)'))
    assert_geom_empty(read('POINT EMPTY'))
    refute_geom_empty(read('LINESTRING(0 0, 10 0)'))
    assert_geom_empty(read('LINESTRING EMPTY'))
    refute_geom_empty(read('POLYGON((0 0, 10 0, 10 10, 0 0))'))
    assert_geom_empty(read('POLYGON EMPTY'))
    refute_geom_empty(read('GEOMETRYCOLLECTION(POINT(0 0))'))
    assert_geom_empty(read('GEOMETRYCOLLECTION EMPTY'))
  end

  def test_valid
    assert_geom_valid(read('POINT(0 0)'))
    refute_geom_valid(read('POINT(0 NaN)'))
    refute_geom_valid(read('POINT(0 nan)'))
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:valid_reason)
    def test_valid_reason
      assert_equal("Valid Geometry", read('POINT(0 0)').valid_reason)
      assert_equal("Invalid Coordinate[0 nan]", read('POINT(0 NaN)').valid_reason)
      assert_equal("Invalid Coordinate[0 nan]", read('POINT(0 nan)').valid_reason)
      assert_equal("Self-intersection[2.5 5]", read('POLYGON((0 0, 0 5, 5 5, 5 10, 0 0))').valid_reason)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:valid_detail)
    def test_valid_detail
      tester = lambda { |detail, location, geom, flags|
        ret = read(geom).valid_detail(flags)
        assert_equal(detail, ret[:detail])
        assert_equal(location, write(ret[:location]))
      }

      assert_nil(read('POINT(0 0)').valid_detail)
      tester["Invalid Coordinate", 'POINT (0 nan)', 'POINT(0 NaN)', 0]
      tester["Self-intersection", 'POINT (2.5 5)', 'POLYGON((0 0, 0 5, 5 5, 5 10, 0 0))', 0]

      tester["Ring Self-intersection", 'POINT (0 0)', 'POLYGON((0 0, -10 10, 10 10, 0 0, 4 5, -4 5, 0 0)))', 0]

      assert_nil(read('POLYGON((0 0, -10 10, 10 10, 0 0, 4 5, -4 5, 0 0)))').valid_detail(
        :allow_selftouching_ring_forming_hole
      ))
    end
  end

  def test_simple
    assert_geom_simple(read('POINT(0 0)'))
    assert_geom_simple(read('LINESTRING(0 0, 10 0)'))
    refute_geom_simple(read('LINESTRING(0 0, 10 0, 5 5, 5 -5)'))
  end

  def test_ring
    refute_geom_ring(read('POINT(0 0)'))
    refute_geom_ring(read('LINESTRING(0 0, 10 0, 5 5, 5 -5)'))
    assert_geom_ring(read('LINESTRING(0 0, 10 0, 5 5, 0 0)'))
  end

  def test_has_z
    refute_geom_has_z(read('POINT(0 0)'))
    assert_geom_has_z(read('POINT(0 0 0)'))
  end

  def test_num_geometries
    simple_tester(:num_geometries, 1, 'POINT(0 0)')
    simple_tester(:num_geometries, 2, 'MULTIPOINT (0 1, 2 3)')
    simple_tester(:num_geometries, 1, 'LINESTRING (0 0, 2 3)')
    simple_tester(:num_geometries, 2, 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))')
    simple_tester(:num_geometries, 1, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
    simple_tester(:num_geometries, 2, 'MULTIPOLYGON(
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      ((10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11)))'
    )
    simple_tester(:num_geometries, 6, 'GEOMETRYCOLLECTION (
      MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      ),
      POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
      MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
      LINESTRING (0 0, 2 3),
      MULTIPOINT (0 0, 2 3),
      POINT (9 0))'
    )
  end

  # get_geometry_n is segfaulting in the binary GEOS build
  if defined?(Geos::FFIGeos)
    def test_get_geometry_n
      simple_tester(:get_geometry_n, 'POINT (0 1)', 'MULTIPOINT (0 1, 2 3)', 0)
      simple_tester(:get_geometry_n, 'POINT (2 3)', 'MULTIPOINT (0 1, 2 3)', 1)
      simple_tester(:get_geometry_n, nil, 'MULTIPOINT (0 1, 2 3)', 2)
    end
  end

  def test_num_interior_rings
    simple_tester(:num_interior_rings, 0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
    simple_tester(:num_interior_rings, 1, 'POLYGON (
      (10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11)
    )')
    simple_tester(:num_interior_rings, 2, 'POLYGON (
      (10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11),
      (13 11, 13 12, 13.5 12, 13.5 11, 13 11))'
    )

    assert_raises(NoMethodError) do
      read('POINT (0 0)').num_interior_rings
    end
  end

  def test_interior_ring_n
    simple_tester(
      :interior_ring_n,
      'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)',
      'POLYGON(
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )',
      0
    )

    simple_tester(
      :interior_ring_n,
      'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )',
      0
    )

    simple_tester(
      :interior_ring_n,
      'LINEARRING (13 11, 13 12, 13.5 12, 13.5 11, 13 11)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )',
      1
    )

    assert_raises(RuntimeError) do
      simple_tester(
        :interior_ring_n,
        nil,
        'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))',
        0
      )
    end

    assert_raises(NoMethodError) do
      simple_tester(
        :interior_ring_n,
        nil,
        'POINT (0 0)',
        0
      )
    end
  end

  def test_exterior_ring
    simple_tester(
      :exterior_ring,
      'LINEARRING (10 10, 10 14, 14 14, 14 10, 10 10)',
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )'
    )

    assert_raises(NoMethodError) do
      read('POINT (0 0)').exterior_ring
    end
  end

  def test_interior_rings
    array_tester(
      :interior_rings,
      [ 'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)' ],
      'POLYGON(
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )'
    )

    array_tester(
      :interior_rings,
      [
        'LINEARRING (11 11, 11 12, 12 12, 12 11, 11 11)',
        'LINEARRING (13 11, 13 12, 13.5 12, 13.5 11, 13 11)'
      ],
      'POLYGON (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11),
        (13 11, 13 12, 13.5 12, 13.5 11, 13 11)
      )'
    )
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:num_coordinates)
    def test_num_coordinates
      simple_tester(:num_coordinates, 1, 'POINT(0 0)')
      simple_tester(:num_coordinates, 2, 'MULTIPOINT (0 1, 2 3)')
      simple_tester(:num_coordinates, 2, 'LINESTRING (0 0, 2 3)')
      simple_tester(:num_coordinates, 4, 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))')
      simple_tester(:num_coordinates, 5, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
      simple_tester(:num_coordinates, 15, 'MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      )')
      simple_tester(:num_coordinates, 29, 'GEOMETRYCOLLECTION (
        MULTIPOLYGON (
          ((0 0, 1 0, 1 1, 0 1, 0 0)),
          ((10 10, 10 14, 14 14, 14 10, 10 10),
          (11 11, 11 12, 12 12, 12 11, 11 11))
        ),
        POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
        MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
        LINESTRING (0 0, 2 3),
        MULTIPOINT ((0 0), (2 3)),
        POINT (9 0)
      )')
    end
  end

  def test_coord_seq
    tester = lambda { |expected, g|
      geom = read(g)
      cs = geom.coord_seq
      expected.each_with_index do |c, i|
        assert_equal(c[0], cs.get_x(i))
        assert_equal(c[1], cs.get_y(i))
      end
    }

    tester[[[0, 0]], 'POINT(0 0)']
    tester[[[0, 0], [2, 3]], 'LINESTRING (0 0, 2 3)']
    tester[[[0, 0], [0, 5], [5, 5], [5, 0], [0, 0]], 'LINEARRING(0 0, 0 5, 5 5, 5 0, 0 0)']
  end

  def test_dimensions
    types = {
      :dontcare => -3,
      :non_empty => -2,
      :empty => -1,
      :point => 0,
      :curve => 1,
      :surface => 2
    }

    simple_tester(:dimensions, types[:point], 'POINT(0 0)')
    simple_tester(:dimensions, types[:point], 'MULTIPOINT (0 1, 2 3)')
    simple_tester(:dimensions, types[:curve], 'LINESTRING (0 0, 2 3)')
    simple_tester(:dimensions, types[:curve], 'MULTILINESTRING ((0 1, 2 3), (10 10, 3 4))')
    simple_tester(:dimensions, types[:surface], 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
    simple_tester(:dimensions, types[:surface], 'MULTIPOLYGON (
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      ((10 10, 10 14, 14 14, 14 10, 10 10),
      (11 11, 11 12, 12 12, 12 11, 11 11))
    )')
    simple_tester(:dimensions, types[:surface], 'GEOMETRYCOLLECTION (
      MULTIPOLYGON (
        ((0 0, 1 0, 1 1, 0 1, 0 0)),
        ((10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11))
      ),
      POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
      MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
      LINESTRING (0 0, 2 3),
      MULTIPOINT (0 0, 2 3),
      POINT (9 0)
    )')
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:project)
    def test_project_and_project_normalized
      geom_a = read('POINT(1 2)')
      geom_b = read('POINT(3 4)')

      # The method only accept lineal geometries
      assert_raises(RuntimeError) do
        geom_a.project(geom_b)
      end

      geom_a = read('LINESTRING(0 0, 10 0)')
      geom_b = read('POINT(0 0)')
      assert_equal(0, geom_a.project(geom_b))
      assert_equal(0, geom_a.project(geom_b, true))

      geom_b = read('POINT(10 0)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(1, geom_a.project(geom_b, true))

      geom_b = read('POINT(5 0)')
      assert_equal(5, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))

      geom_a = read('MULTILINESTRING((0 0, 10 0),(20 10, 20 20))')
      geom_b = read('POINT(20 0)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))

      geom_b = read('POINT(20 5)')
      assert_equal(10, geom_a.project(geom_b))
      assert_equal(0.5, geom_a.project(geom_b, true))
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:interpolate)
    def test_interpolate
      simple_tester(:interpolate, 'POINT (0 0)', 'LINESTRING(0 0, 10 0)', 0, false)
      simple_tester(:interpolate, 'POINT (0 0)', 'LINESTRING(0 0, 10 0)', 0, true)

      simple_tester(:interpolate, 'POINT (5 0)', 'LINESTRING(0 0, 10 0)', 5, false)
      simple_tester(:interpolate, 'POINT (5 0)', 'LINESTRING(0 0, 10 0)', 0.5, true)

      simple_tester(:interpolate, 'POINT (10 0)', 'LINESTRING(0 0, 10 0)', 20, false)
      simple_tester(:interpolate, 'POINT (10 0)', 'LINESTRING(0 0, 10 0)', 2, true)

      assert_raises(RuntimeError) do
        read('POINT(1 2)').interpolate(0)
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:start_point)
    def test_start_and_end_points
      geom = read('LINESTRING (10 10, 10 14, 14 14, 14 10)')
      simple_tester(:start_point, 'POINT (10 10)', geom)
      simple_tester(:end_point, 'POINT (14 10)', geom)

      geom = read('LINEARRING (11 11, 11 12, 12 11, 11 11)')
      simple_tester(:start_point, 'POINT (11 11)', geom)
      simple_tester(:start_point, 'POINT (11 11)', geom)
    end
  end

  def test_area
    simple_tester(:area, 1.0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
    simple_tester(:area, 0.0, 'POINT (0 0)')
    simple_tester(:area, 0.0, 'LINESTRING (0 0 , 10 0)')
  end

  def test_length
    simple_tester(:length, 4.0, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
    simple_tester(:length, 0.0, 'POINT (0 0)')
    simple_tester(:length, 10.0, 'LINESTRING (0 0 , 10 0)')
  end

  def test_distance
    geom = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'
    simple_tester(:distance, 0.0, geom, read('POINT(0.5 0.5)'))
    simple_tester(:distance, 1.0, geom, read('POINT (-1 0)'))
    simple_tester(:distance, 2.0, geom, read('LINESTRING (3 0 , 10 0)'))
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:hausdorff_distance)
    def test_hausdorff_distance
      tester = lambda { |expected, g1, g2|
        geom_1 = read(g1)
        geom_2 = read(g2)
        assert_in_delta(expected, geom_1.hausdorff_distance(geom_2), TOLERANCE)
      }

      geom_a = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'

      tester[10.0498756211209, geom_a, 'POINT(0 10)']
      tester[2.23606797749979, geom_a, 'POINT(-1 0)']
      tester[9.0, geom_a, 'LINESTRING (3 0 , 10 0)']
    end

    def test_hausdorff_distance_with_densify_fract
      tester = lambda { |expected, g1, g2|
        geom_1 = read(g1)
        geom_2 = read(g2)
        assert_in_delta(expected, geom_1.hausdorff_distance(geom_2, 0.001), TOLERANCE)
      }

      geom_a = 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))'

      tester[10.0498756211209, geom_a, 'POINT(0 10)']
      tester[2.23606797749979, geom_a, 'POINT(-1 0)']
      tester[9.0, geom_a, 'LINESTRING (3 0 , 10 0)']
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:snap)
    def test_snap
      geom = read('POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))')
      simple_tester(:snap, 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))', geom, read('POINT(0.1 0)'), 0)
      simple_tester(:snap, 'POLYGON ((0.1 0, 1 0, 1 1, 0 1, 0.1 0))', geom, read('POINT(0.1 0)'), 0.5)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize)
    def test_polygonize
      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )'
      )

      polygonized = geom_a.polygonize
      assert_equal(2, polygonized.length)
      assert_equal(
        'POLYGON ((185 221, 88 275, 180 316, 292 281, 185 221))',
        write(polygonized[0].snap_to_grid(0.1))
      )
      assert_equal(
        'POLYGON ((189 98, 83 187, 185 221, 325 168, 189 98))',
        write(polygonized[1].snap_to_grid(0.1))
      )
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize_cut_edges)
    def test_polygonize_cut_edges
      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )'
      )

      cut_edges = geom_a.polygonize_cut_edges
      assert_equal(0, cut_edges.length)
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:polygonize_full)
    def test_polygonize_full
      tester = lambda { |expected, geom|
        assert_equal(expected, write(geom.snap_to_grid(1)))
      }

      geom_a = read(
        'GEOMETRYCOLLECTION(
          LINESTRING(0 0, 10 10),
          LINESTRING(185 221, 100 100),
          LINESTRING(185 221, 88 275, 180 316),
          LINESTRING(185 221, 292 281, 180 316),
          LINESTRING(189 98, 83 187, 185 221),
          LINESTRING(189 98, 325 168, 185 221)
        )')

      polygonized = geom_a.polygonize_full

      assert_kind_of(Array, polygonized[:rings])
      assert_kind_of(Array, polygonized[:cuts])
      assert_kind_of(Array, polygonized[:dangles])
      assert_kind_of(Array, polygonized[:invalid_rings])

      assert_equal(2, polygonized[:rings].length)
      assert_equal(0, polygonized[:cuts].length)
      assert_equal(2, polygonized[:dangles].length)
      assert_equal(0, polygonized[:invalid_rings].length)

      tester[
        'POLYGON ((185 221, 88 275, 180 316, 292 281, 185 221))',
        polygonized[:rings][0]
      ]

      tester[
        'POLYGON ((189 98, 83 187, 185 221, 325 168, 189 98))',
        polygonized[:rings][1]
      ]

      tester[
        'LINESTRING (185 221, 100 100)',
        polygonized[:dangles][0]
      ]

      tester[
        'LINESTRING (0 0, 10 10)',
        polygonized[:dangles][1]
      ]

      geom_b = geom_a.union(read('POINT(0 0)'))
      polygonized = geom_b.polygonize_full

      assert_equal(2, polygonized[:dangles].length)
      assert_equal(0, polygonized[:invalid_rings].length)

      tester[
        'LINESTRING (132 146, 100 100)',
        polygonized[:dangles][0]
      ]

      tester[
        'LINESTRING (0 0, 10 10)',
        polygonized[:dangles][1]
      ]
    end

    def test_polygonize_with_bad_arguments
      assert_raises(ArgumentError) do
        geom = read('POINT(0 0)')

        geom.polygonize(geom, 'gibberish')
      end
    end
  end

  if ENV['FORCE_TESTS'] || Geos::Geometry.method_defined?(:shared_paths)
    def test_shared_paths
      geom_a = read('LINESTRING(0 0, 50 0)')
      geom_b = read('MULTILINESTRING((5 0, 15 0),(40 0, 30 0))')

      paths = geom_a.shared_paths(geom_b)
      assert_equal(2, paths.length)
      assert_equal(
        'MULTILINESTRING ((5 0, 15 0))',
        write(paths[0])
      )
      assert_equal(
        'MULTILINESTRING ((30 0, 40 0))',
        write(paths[1])
      )
    end
  end

  def test_clone
    geom_a = read('POINT(0 0)')
    geom_b = geom_a.clone

    assert_equal(geom_a, geom_b)
  end

  def test_clone_srid
    srid = 4326
    geom_a = read('POINT(0 0)')
    geom_a.srid = srid
    geom_b = geom_a.clone

    assert_equal(geom_a, geom_b)
    assert_equal(srid, geom_b.srid)
  end

  def test_dup
    geom_a = read('POINT(0 0)')
    geom_b = geom_a.dup

    assert_equal(geom_a, geom_b)
  end

  def test_dup_srid
    srid = 4326
    geom_a = read('POINT(0 0)')
    geom_a.srid = srid
    geom_b = geom_a.dup
    assert_equal(geom_a, geom_b)
    assert_equal(srid, geom_b.srid)
  end

  def test_line_string_enumerator
    geom = read('LINESTRING(0 0, 10 10))')
    assert_kind_of(Enumerable, geom.each)
    assert_kind_of(Enumerable, geom.to_enum)
    assert_equal(geom, geom.each {})
  end

  def test_normalize
    geom = read('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))')
    geom.normalize
    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(geom))

    geom = read('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))').normalize
    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(geom))
  end

  def test_normalize_bang
    geom = read('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))')
    geom.normalize!
    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(geom))

    geom = read('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))').normalize!
    assert_equal('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))', write(geom))
  end

  def test_eql
    geom_a = read('POINT(1.0 1.0)')
    geom_b = read('POINT(2.0 2.0)')

    %w{ eql? equals? == }.each do |method|
      refute(geom_a.send(method, geom_b), "Expected geoms to not be equal using #{method}")
    end
  end

  def test_eql_exact
    geom_a = read('POINT(1.0 1.0)')
    geom_b = read('POINT(2.0 2.0)')

    %w{ eql_exact? equals_exact? exactly_equals? }.each do |method|
      refute(geom_a.send(method, geom_b, 0.001), "Expected geoms to not be equal using #{method}")
    end
  end

  def test_eql_almost_default
    geom = read('POINT (1 1)')
    geom_a = read('POINT (1.0000001 1.0000001)')
    geom_b = read('POINT (1.000001 1.000001)')

    %w{ eql_almost? equals_almost? almost_equals? }.each do |method|
      assert(geom.send(method, geom_a), "Expected geoms to be equal using #{method}")
      refute(geom.send(method, geom_b), "Expected geoms to not be equal using #{method}")
    end
  end

  def test_eql_almost
    geom_a = read('POINT(1.0 1.0)')
    geom_b = read('POINT(1.1 1.1)')

    refute_equal(geom_a, geom_b)

    %w{ eql_almost? equals_almost? almost_equals? }.each do |method|
      assert(geom_a.send(method, geom_b, 0), "Expected geoms to be equal using #{method}")
      refute(geom_a.send(method, geom_b, 1), "Expected geoms to not be equal using #{method}")
    end
  end

  def test_srid_copy_policy
    geom = read('POLYGON ((0 0, 0 5, 5 5, 5 0, 0 0))')
    geom.srid = 4326

    Geos.srid_copy_policy = :zero
    cloned = geom.clone
    assert_equal(4326, cloned.srid)

    Geos.srid_copy_policy = :lenient
    cloned = geom.clone
    assert_equal(4326, cloned.srid)

    Geos.srid_copy_policy = :strict
    cloned = geom.clone
    assert_equal(4326, cloned.srid)

    Geos.srid_copy_policy = :zero
    geom_b = geom.convex_hull
    assert_equal(0, geom_b.srid)

    Geos.srid_copy_policy = :lenient
    geom_b = geom.convex_hull
    assert_equal(4326, geom_b.srid)

    Geos.srid_copy_policy = :strict
    geom_b = geom.convex_hull
    assert_equal(4326, geom_b.srid)

    geom_b = read('POLYGON ((3 3, 3 8, 8 8, 8 3, 3 3))')
    geom_b.srid = 3875

    Geos.srid_copy_policy = :zero
    geom_c = geom.intersection(geom_b)
    assert_equal(0, geom_c.srid)

    Geos.srid_copy_policy = :lenient
    geom_c = geom.intersection(geom_b)
    assert_equal(4326, geom_c.srid)

    assert_raises(Geos::MixedSRIDsError) do
      Geos.srid_copy_policy = :strict
      geom_c = geom.intersection(geom_b)
      assert_equal(231231, geom_c.srid)
    end
  ensure
    Geos.srid_copy_policy = :default
  end

  def test_dump_points
    geom = read('GEOMETRYCOLLECTION(
      MULTILINESTRING((0 0, 10 10, 20 20), (100 100, 200 200, 300 300)),

      POINT(10 10),

      POLYGON((0 0, 5 0, 5 5, 0 5, 0 0), (1 1, 4 1, 4 4, 1 4, 1 1))
    )')

    assert_equal([
      [
        [
          Geos.create_point(0, 0),
          Geos.create_point(10, 10),
          Geos.create_point(20, 20)
        ],

        [
          Geos.create_point(100, 100),
          Geos.create_point(200, 200),
          Geos.create_point(300, 300)
        ]
      ],

      [
        Geos.create_point(10, 10)
      ],

      [
        [
          Geos.create_point(0, 0),
          Geos.create_point(5, 0),
          Geos.create_point(5, 5),
          Geos.create_point(0, 5),
          Geos.create_point(0, 0)
        ],

        [
          Geos.create_point(1, 1),
          Geos.create_point(4, 1),
          Geos.create_point(4, 4),
          Geos.create_point(1, 4),
          Geos.create_point(1, 1)
        ]
      ]
    ], geom.dump_points)
  end
end

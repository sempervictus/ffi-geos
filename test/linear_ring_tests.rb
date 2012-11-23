# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class LinearRingTests < MiniTest::Unit::TestCase
  include TestHelper

  def setup
    super
    writer.trim = true
  end

  def test_to_polygon
    geom = read('POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))')
    ring = geom.exterior_ring

    assert_equal(write(geom), write(ring.to_polygon))
  end

  def test_to_polygon_with_srid
    wkt = 'LINEARRING (0 0, 5 0, 5 5, 0 5, 0 0)'
    expected = 'POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))'

    srid_copy_tester(:to_polygon, expected, 0, :zero, wkt)
    srid_copy_tester(:to_polygon, expected, 4326, :lenient, wkt)
    srid_copy_tester(:to_polygon,  expected, 4326, :strict, wkt)
  end

  def test_to_line_string
    geom = read('LINEARRING (0 0, 5 0, 5 5, 0 5, 0 0)')

    assert_equal('LINESTRING (0 0, 5 0, 5 5, 0 5, 0 0)', write(geom.to_line_string))
  end

  def test_to_line_string_with_srid
    wkt = 'LINEARRING (0 0, 5 0, 5 5, 0 5, 0 0)'
    expected = 'LINESTRING (0 0, 5 0, 5 5, 0 5, 0 0)'

    srid_copy_tester(:to_line_string, expected, 0, :zero, wkt)
    srid_copy_tester(:to_line_string, expected, 4326, :lenient, wkt)
    srid_copy_tester(:to_line_string,  expected, 4326, :strict, wkt)
  end
end

# encoding: BINARY

require 'rubygems'
require 'minitest/autorun'

if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
end

if ENV['USE_BINARY_GEOS']
  require 'geos'
else
  require File.join(File.dirname(__FILE__), %w{ .. lib ffi-geos })
end

puts "Ruby version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "ffi version #{Gem.loaded_specs['ffi'].version}" if Gem.loaded_specs['ffi']

if Geos.respond_to?(:version)
  puts "GEOS version #{Geos.version}"
else
  puts "GEOS version #{Geos::GEOS_VERSION}"
end

puts "ffi-geos version #{Geos::VERSION}" if defined?(Geos::VERSION)

if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_path}"
end

module TestHelper
  TOLERANCE = 0.0000000000001

  def self.included(base)
    base.class_eval do
      attr_reader :reader, :writer
    end
  end

  def setup
    GC.start
    @reader = Geos::WktReader.new
    @writer = Geos::WktWriter.new
  end

  def read(*args)
    reader.read(*args)
  end

  def write(*args)
    writer.write(*args)
  end

  def srid_copy_tester(method, expected, expected_srid, srid_policy, wkt, *args)
    geom = read(wkt)
    geom.srid = 4326

    Geos.srid_copy_policy = srid_policy
    geom_b = geom.send(method, *args)

    assert_equal(4326, geom.srid)
    assert_equal(expected_srid, geom_b.srid)
    assert_equal(expected, write(geom_b))
  ensure
    Geos.srid_copy_policy = :default
  end

  {
    :empty => 'to be empty',
    :valid => 'to be valid',
    :simple => 'to be simple',
    :ring => 'to be ring',
    :closed => 'to be closed',
    :has_z => 'to have z dimension'
  }.each do |t, m|
    self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
      def assert_geom_#{t}(geom)
        assert(geom.#{t}?, "Expected geom #{m}")
      end

      def refute_geom_#{t}(geom)
        assert(!geom.#{t}?, "Did not expect geom #{m}")
      end
    EOF
  end

  def assert_geom_eql_exact(geom, result, tolerance = TOLERANCE)
    assert(geom.eql_exact?(result, tolerance), "Expected geom.eql_exact? to be within #{tolerance}")
  end

  def affine_tester(method, expected, wkt, *args)
    writer.trim = true

    geom = read(wkt)
    geom.send("#{method}!", *args).snap_to_grid!(0.1)

    assert_equal(expected, write(geom))

    geom = read(wkt)
    geom2 = geom.send(method, *args).snap_to_grid(0.1)

    assert_equal(wkt, write(geom))
    assert_equal(expected, write(geom2, :trim => true))
  end
end

if RUBY_VERSION >= '1.9'
  MiniTest::Reporters.use!(MiniTest::Reporters::SpecReporter.new)
end


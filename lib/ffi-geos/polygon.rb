# encoding: UTF-8

module Geos
  class Polygon < Geometry
    def num_interior_rings
      FFIGeos.GEOSGetNumInteriorRings_r(Geos.current_handle, self.ptr)
    end

    def interior_ring_n(n)
      if n < 0 || n >= self.num_interior_rings
        raise RuntimeError.new("Index out of bounds")
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGetInteriorRingN_r(Geos.current_handle, self.ptr, n), {
            :auto_free => false,
            :srid_copy => self.srid
          }
        )
      end
    end
    alias :interior_ring :interior_ring_n

    def exterior_ring
      cast_geometry_ptr(
        FFIGeos.GEOSGetExteriorRing_r(Geos.current_handle, self.ptr), {
          :auto_free => false,
          :srid_copy => self.srid
        }
      )
    end

    def interior_rings
      self.num_interior_rings.times.collect do |n|
        self.interior_ring_n(n)
      end
    end

    def dump_points(cur_path = [])
      points = [ self.exterior_ring.dump_points ]

      self.interior_rings.each do |ring|
        points.push(ring.dump_points)
      end

      cur_path.concat(points)
    end

    %w{ max min }.each do |op|
      %w{ x y }.each do |dimension|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.envelope.exterior_ring.#{dimension}_#{op}
            end
          end
        EOF
      end

      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def z_#{op}
          unless self.empty?
            if self.has_z?
              self.exterior_ring.z_#{op}
            else
              0
            end
          end
        end
      EOF
    end
  end
end

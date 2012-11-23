# encoding: UTF-8

module Geos
  class LineString < Geometry
    include Enumerable

    def each
      if block_given?
        self.num_points.times do |n|
          yield self.point_n(n)
        end
        self
      else
        self.num_points.times.collect { |n|
          self.point_n(n)
        }.to_enum
      end
    end

    if FFIGeos.respond_to?(:GEOSGeomGetNumPoints_r)
      def num_points
        FFIGeos.GEOSGeomGetNumPoints_r(Geos.current_handle, self.ptr)
      end
    else
      def num_points
        self.coord_seq.length
      end
    end

    def point_n(n)
      if n < 0 || n >= self.num_points
        raise RuntimeError.new("Index out of bounds")
      else
        cast_geometry_ptr(
          FFIGeos.GEOSGeomGetPointN_r(Geos.current_handle, self.ptr, n), {
            :srid_copy => self.srid
          }
        )
      end
    end

    def [](*args)
      if args.length == 1 && args.first.is_a?(Numeric) && args.first >= 0
        self.point_n(args.first)
      else
        self.to_a[*args]
      end
    end
    alias :slice :[]

    def offset_curve(width, options = {})
      options = Constants::BUFFER_PARAM_DEFAULTS.merge(options)

      cast_geometry_ptr(FFIGeos.GEOSOffsetCurve_r(
          Geos.current_handle,
          self.ptr,
          width,
          options[:quad_segs],
          options[:join],
          options[:mitre_limit]
      ), {
        :srid_copy => self.srid
      })
    end

    if FFIGeos.respond_to?(:GEOSisClosed_r)
      def closed?
        bool_result(FFIGeos.GEOSisClosed_r(Geos.current_handle, self.ptr))
      end
    end

    def dump_points(cur_path = [])
      cur_path.concat(self.to_a)
    end

    %w{ max min }.each do |op|
      %w{ x y }.each do |dimension|
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def #{dimension}_#{op}
            unless self.empty?
              self.coord_seq.#{dimension}_#{op}
            end
          end
        EOF
      end

      self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        def z_#{op}
          unless self.empty?
            if self.has_z?
              self.coord_seq.z_#{op}
            else
              0
            end
          end
        end
      EOF
    end
  end
end

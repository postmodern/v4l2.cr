module V4L2
  module StructWrapper(STRUCT)
    @struct : STRUCT

    macro struct_getter(name, to scope = @struct, field = nil)
      {% begin %}
        @[AlwaysInline]
        def {{ name.id }}
          {{ scope.id }}.{{ (field || name).id }}
        end
      {% end %}

      {% if field && field != name %}
        {% begin %}
          @[AlwaysInline]
          def {{ field.id }}
            {{ scope.id }}.{{ field.id }}
          end
        {% end %}
      {% end %}
    end

    macro struct_setter(name, to scope = @struct, field = nil)
      {% begin %}
        @[AlwaysInline]
        def {{ name.id }}=(value)
          {{ scope.id }}.{{ (field || name).id }}=(value)
        end
      {% end %}

      {% if field && field != name %}
        {% begin %}
          @[AlwaysInline]
          def {{ field.id }}=(value)
            {{ scope.id }}.{{ field.id }}=(value)
          end
        {% end %}
      {% end %}
    end

    macro struct_property(name, to scope = @struct, field = nil)
      struct_getter {{ name }}, to: {{ scope }}, field: {{ field }}
      struct_setter {{ name }}, to: {{ scope }}, field: {{ field }}
    end

    macro struct_char_array_field(name)
      def {{ name.id }} : String
        bytes = @struct.{{ name.id }}.to_slice

        String.new(bytes[0,bytes.index(0) || bytes.size])
      end
    end

    def to_unsafe : Pointer(STRUCT)
      pointerof(@struct)
    end
  end
end

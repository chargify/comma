# -*- coding: utf-8 -*-
require 'comma/sanitized_extractor'

module Comma

  class SanitizedDataExtractor < SanitizedExtractor

    def multicolumn(method, &block)
      Comma::MulticolumnExtractor.new(@instance, method, @globals, &block).extract_values.each do |result|
        @results << result
      end
    end

    class ExtractValueFromInstance
      def initialize(instance)
        @instance = instance
      end

      def extract(sym, &block)
        yield_block_with_value(extract_value(sym), &block)
      end

      private

      def yield_block_with_value(value, &block)
        block ? yield(value) : value
      end

      def extract_value(method)
        extraction_object.send(method)
      end

      def extraction_object
        @instance
      end
    end

    class ExtractValueFromAssociationOfInstance < ExtractValueFromInstance
      def initialize(instance, association_name)
        super(instance)
        @association_name = association_name
      end

      private

      def extraction_object
        @instance.send(@association_name) || null_association
      end

      def null_association
        @null_association ||= Class.new(Class.const_defined?(:BasicObject) ? ::BasicObject : ::Object) do
          def method_missing(symbol, *args, &block)
            nil
          end
        end.new
      end
    end

    def method_missing(sym, *args, &block)
      if args.blank?
        @results << ExtractValueFromInstance.new(@instance).extract(sym, &block)
      end

      args.each do |arg|
        case arg
        when Hash
          arg.each do |k, v|
            @results << ExtractValueFromAssociationOfInstance.new(@instance, sym).extract(k, &block)
          end
        when Symbol
          @results << ExtractValueFromAssociationOfInstance.new(@instance, sym).extract(arg, &block)
        when String
          @results << ExtractValueFromInstance.new(@instance).extract(sym, &block)
        else
          raise "Unknown data symbol #{arg.inspect}"
        end
      end
    end

    def __static_column__(header = nil, &block)
      @results << (block ? yield(@instance) : nil)
    end
  end
end

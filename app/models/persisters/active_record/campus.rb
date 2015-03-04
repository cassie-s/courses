module Persisters
  module ActiveRecord
    class Campus < ::ActiveRecord::Base
      attr_accessor :type

      def self.orm_adapter
        ::Hexagram::Adapters::ActiveRecord
      end

      self.primary_key = "abbreviation"
    end
  end
end

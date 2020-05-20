require_relative "efficient_join/version"
require_relative "efficient_join/efficient_join.so"

module EfficientJoin
  class Error < StandardError; end

  class << self
    include EfficientJoinCExt

    def join(array, header: '', footer: '', separator: ',', item_prefix: '', item_suffix: '')
      _join(header, footer, item_prefix, item_suffix, separator, array)
    end

    def join_pg_array(array)
      _join('{', '}', '', '', ',', array)
    end
  end
end

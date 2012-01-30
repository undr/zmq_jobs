module ZmqJobs
  module CoreExt
    module Number
      def humanize(rounded=2, delimiter=' ',separator='.')
        parts = self.to_s.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
        parts.join separator
      end
    end
  end
end
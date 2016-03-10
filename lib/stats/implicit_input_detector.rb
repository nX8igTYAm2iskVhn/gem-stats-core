module Stats
  class ImplicitInputDetector
    @@detectors = []

    def initialize(presenter)
      @presenter = presenter
    end

    def self.inherited(base)
      @@detectors << base
    end

    def self.detectors
      @@detectors
    end


    def detected?
      false
    end

    def modify_presenter
      raise "implement in subclass"
    end
  end
end

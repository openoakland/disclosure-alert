module Forms
  class Form497Combined < Form497
    def initialize(filings, name: nil)
      super(filings.first, name: name)

      @filings = filings
    end

    def title
      "Combination of #{@filings.length} #{super}"
    end

    def uncombined_filing_ids
      @filings[1..-1].map(&:id) << @filings.first.id
    end

    def contents
      @filings.flat_map(&:contents).uniq
    end
  end
end

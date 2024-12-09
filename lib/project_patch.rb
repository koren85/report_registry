module ProjectPatch
  def self.included(base)
    base.class_eval do
      has_many :reports, dependent: :destroy
    end
  end
end

# Add module to Project class
Project.include ProjectPatch
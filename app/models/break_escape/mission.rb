module BreakEscape
  class Mission < ApplicationRecord
    self.table_name = 'break_escape_missions'

    has_many :games, class_name: 'BreakEscape::Game', dependent: :destroy

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true
    validates :difficulty_level, inclusion: { in: 1..5 }

    scope :published, -> { where(published: true) }

    # Path to scenario directory
    def scenario_path
      BreakEscape::Engine.root.join('scenarios', name)
    end

    # Generate scenario data via ERB
    def generate_scenario_data
      template_path = scenario_path.join('scenario.json.erb')
      raise "Scenario template not found: #{name}" unless File.exist?(template_path)

      erb = ERB.new(File.read(template_path))
      binding_context = ScenarioBinding.new
      output = erb.result(binding_context.get_binding)

      JSON.parse(output)
    rescue JSON::ParserError => e
      raise "Invalid JSON in #{name} after ERB processing: #{e.message}"
    end

    # Binding context for ERB variables
    class ScenarioBinding
      def initialize
        @random_password = SecureRandom.alphanumeric(8)
        @random_pin = rand(1000..9999).to_s
        @random_code = SecureRandom.hex(4)
      end

      attr_reader :random_password, :random_pin, :random_code

      def get_binding
        binding
      end
    end
  end
end

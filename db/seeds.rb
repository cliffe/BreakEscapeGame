puts "Creating BreakEscape missions..."

# List all scenario directories
scenario_dirs = Dir.glob(Rails.root.join('app/assets/scenarios/*')).select { |f| File.directory?(f) }

scenario_dirs.each do |dir|
  scenario_name = File.basename(dir)
  next if scenario_name == 'common'  # Skip common directory if it exists

  # Create mission metadata
  mission = BreakEscape::Mission.find_or_initialize_by(name: scenario_name)

  if mission.new_record?
    mission.display_name = scenario_name.titleize
    mission.description = "Play the #{scenario_name.titleize} scenario"
    mission.published = true
    mission.difficulty_level = 3  # Default, can be updated later
    mission.save!
    puts "  ✓ Created: #{mission.display_name}"
  else
    puts "  - Exists: #{mission.display_name}"
  end
end

puts "Done! Created #{BreakEscape::Mission.count} missions."

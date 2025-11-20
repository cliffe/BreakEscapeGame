require 'open3'

module BreakEscape
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :scenario, :ink]

    def show
      authorize @game if defined?(Pundit)
      @mission = @game.mission
    end

    # GET /games/:id/scenario
    # Returns scenario JSON for this game instance
    def scenario
      authorize @game if defined?(Pundit)
      render json: @game.scenario_data
    end

    # GET /games/:id/ink?npc=helper1
    # Returns NPC script (JIT compiled if needed)
    def ink
      authorize @game if defined?(Pundit)

      npc_id = params[:npc]
      return render_error('Missing npc parameter', :bad_request) unless npc_id.present?

      # Find NPC in scenario data
      npc = find_npc_in_scenario(npc_id)
      return render_error('NPC not found in scenario', :not_found) unless npc

      # Resolve ink file path and compile if needed
      ink_json_path = resolve_and_compile_ink(npc['storyPath'])
      return render_error('Ink script not found', :not_found) unless ink_json_path && File.exist?(ink_json_path)

      # Serve compiled JSON
      render json: JSON.parse(File.read(ink_json_path))
    rescue JSON::ParserError => e
      render_error("Invalid JSON in compiled ink: #{e.message}", :internal_server_error)
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def find_npc_in_scenario(npc_id)
      @game.scenario_data['rooms']&.each do |_room_id, room_data|
        npc = room_data['npcs']&.find { |n| n['id'] == npc_id }
        return npc if npc
      end
      nil
    end

    # Resolve ink path and compile if necessary
    def resolve_and_compile_ink(story_path)
      base_path = Rails.root.join(story_path)
      json_path = find_compiled_json(base_path)
      ink_path = find_ink_source(base_path)

      if ink_path && needs_compilation?(ink_path, json_path)
        Rails.logger.info "[BreakEscape] Compiling #{File.basename(ink_path)}..."
        json_path = compile_ink(ink_path)
      end

      json_path
    end

    def find_compiled_json(base_path)
      return base_path if File.exist?(base_path)

      ink_json_path = base_path.to_s.gsub(/\.json$/, '.ink.json')
      return Pathname.new(ink_json_path) if File.exist?(ink_json_path)

      json_path = base_path.to_s.gsub(/\.ink\.json$/, '.json')
      return Pathname.new(json_path) if File.exist?(json_path)

      nil
    end

    def find_ink_source(base_path)
      ink_path = base_path.to_s.gsub(/\.(ink\.)?json$/, '.ink')
      File.exist?(ink_path) ? Pathname.new(ink_path) : nil
    end

    def needs_compilation?(ink_path, json_path)
      return true unless json_path && File.exist?(json_path)
      File.mtime(ink_path) > File.mtime(json_path)
    end

    def compile_ink(ink_path)
      output_path = ink_path.to_s.gsub(/\.ink$/, '.json')
      inklecate_path = Rails.root.join('bin', 'inklecate')

      stdout, stderr, status = Open3.capture3(
        inklecate_path.to_s,
        '-o', output_path,
        ink_path.to_s
      )

      unless status.success?
        Rails.logger.error "[BreakEscape] Ink compilation failed: #{stderr}"
        raise "Ink compilation failed for #{File.basename(ink_path)}: #{stderr}"
      end

      if stderr.present?
        Rails.logger.warn "[BreakEscape] Ink compilation warnings: #{stderr}"
      end

      Rails.logger.info "[BreakEscape] Compiled #{File.basename(ink_path)} (#{(File.size(output_path) / 1024.0).round(2)} KB)"

      Pathname.new(output_path)
    end

    def render_error(message, status)
      render json: { error: message }, status: status
    end
  end
end

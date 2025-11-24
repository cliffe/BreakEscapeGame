module BreakEscape
  class Game < ApplicationRecord
    self.table_name = 'break_escape_games'

    # Associations
    belongs_to :player, polymorphic: true
    belongs_to :mission, class_name: 'BreakEscape::Mission'

    # Validations
    validates :player, presence: true
    validates :mission, presence: true
    validates :status, inclusion: { in: %w[in_progress completed abandoned] }

    # Scopes
    scope :active, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }

    # Callbacks
    before_create :generate_scenario_data
    before_create :initialize_player_state
    before_create :set_started_at

    # Room management
    def unlock_room!(room_id)
      player_state['unlockedRooms'] ||= []
      player_state['unlockedRooms'] << room_id unless player_state['unlockedRooms'].include?(room_id)
      save!
    end

    def room_unlocked?(room_id)
      player_state['unlockedRooms']&.include?(room_id) || start_room?(room_id)
    end

    def start_room?(room_id)
      scenario_data['startRoom'] == room_id
    end

    # Object management
    def unlock_object!(object_id)
      player_state['unlockedObjects'] ||= []
      player_state['unlockedObjects'] << object_id unless player_state['unlockedObjects'].include?(object_id)
      save!
    end

    def object_unlocked?(object_id)
      player_state['unlockedObjects']&.include?(object_id)
    end

    # Inventory management
    def add_inventory_item!(item)
      player_state['inventory'] ||= []
      player_state['inventory'] << item
      save!
    end

    def remove_inventory_item!(item_id)
      player_state['inventory']&.reject! { |item| item['id'] == item_id }
      save!
    end

    # Check if player has a specific key in inventory
    def has_key_in_inventory?(key_id)
      inventory = player_state['inventory'] || []
      
      Rails.logger.info "[BreakEscape] Checking for key #{key_id} in inventory (#{inventory.length} items)"
      
      # Check for key with matching key_id
      found = inventory.any? do |item|
        is_match = item['scenarioData']&.dig('key_id') == key_id || 
                   item['scenarioData']&.dig('id') == key_id ||
                   item['key_id'] == key_id ||
                   item['id'] == key_id
        
        item_key_id = item['scenarioData']&.dig('key_id') || item['key_id']
        item_name = item['scenarioData']&.dig('name') || item['name']
        Rails.logger.debug "[BreakEscape] Inventory item: name=#{item_name}, key_id=#{item_key_id}, is_match=#{is_match}"
        is_match
      end
      
      Rails.logger.info "[BreakEscape] Key #{key_id} found in inventory: #{found}"
      found
    end

    # Check if player has a lockpick in inventory
    def has_lockpick_in_inventory?
      inventory = player_state['inventory'] || []
      
      Rails.logger.info "[BreakEscape] Checking for lockpick in inventory (#{inventory.length} items)"
      
      # Check for lockpick item in scenarioData or at top level
      found = inventory.any? do |item|
        is_lockpick = item['scenarioData']&.dig('type') == 'lockpick' ||
                      item['type'] == 'lockpick'
        Rails.logger.debug "[BreakEscape] Inventory item: type=#{item['type']}, scenarioData.type=#{item['scenarioData']&.dig('type')}, is_lockpick=#{is_lockpick}"
        is_lockpick
      end
      
      Rails.logger.info "[BreakEscape] Lockpick found in inventory: #{found}"
      found
    end

    # NPC tracking
    def encounter_npc!(npc_id)
      player_state['encounteredNPCs'] ||= []
      player_state['encounteredNPCs'] << npc_id unless player_state['encounteredNPCs'].include?(npc_id)
      save!
    end

    # Global variables (synced with client)
    def update_global_variables!(variables)
      player_state['globalVariables'] ||= {}
      player_state['globalVariables'].merge!(variables)
      save!
    end

    # Minigame state
    def add_biometric_sample!(sample)
      player_state['biometricSamples'] ||= []
      player_state['biometricSamples'] << sample
      save!
    end

    def add_bluetooth_device!(device)
      player_state['bluetoothDevices'] ||= []
      unless player_state['bluetoothDevices'].any? { |d| d['mac'] == device['mac'] }
        player_state['bluetoothDevices'] << device
      end
      save!
    end

    def add_note!(note)
      player_state['notes'] ||= []
      player_state['notes'] << note
      save!
    end

    # Health management
    def update_health!(value)
      player_state['health'] = value.clamp(0, 100)
      save!
    end

    # Scenario data access
    def room_data(room_id)
      scenario_data.dig('rooms', room_id)
    end

    def filtered_scenario_for_bootstrap
      # Returns scenario data without room contents for lazy-loading
      # This significantly reduces initial payload by only sending metadata
      filtered = scenario_data.deep_dup
      
      # Remove all room contents - they'll be lazy-loaded via /room/:room_id endpoint
      if filtered['rooms'].present?
        filtered['rooms'].each do |room_id, room_data|
          # Keep only essential fields for navigation and metadata
          # keyPins MUST be included: Door locks need pin configuration at interaction time,
          # before the connected room is lazy-loaded. Without keyPins here, lockpicking uses random pins.
          kept_fields = {}
          %w[type connections locked lockType requires difficulty door_sign keyPins].each do |field|
            kept_fields[field] = room_data[field] if room_data.key?(field)
          end
          
          # Replace room data with filtered version
          filtered['rooms'][room_id] = kept_fields
        end
      end
      
      filtered
    end

    def filtered_room_data(room_id)
      room = room_data(room_id)&.deep_dup
      return nil unless room

      # Remove ONLY the 'requires' field (the solution) and locked 'contents'
      # Keep lockType, locked, observations visible to client
      filter_requires_and_contents_recursive(room)

      room
    end

    # Unlock validation
    def validate_unlock(target_type, target_id, attempt, method)
      Rails.logger.info "[BreakEscape] validate_unlock: type=#{target_type}, id=#{target_id}, attempt=#{attempt}, method=#{method}"

      if target_type == 'door'
        # Check if already unlocked in player state (grants access regardless of method)
        if room_unlocked?(target_id)
          Rails.logger.info "[BreakEscape] Door already unlocked in player state, granting access"
          return true
        end

        room = room_data(target_id)
        return false unless room

        Rails.logger.debug "[BreakEscape] Room data: locked=#{room['locked']}, lockType=#{room['lockType']}, requires=#{room['requires']}"

        # If room is LOCKED, it requires validation
        if room['locked']
          Rails.logger.info "[BreakEscape] Room is LOCKED, method must be valid: #{method}"
          
          # Handle method='unlocked' - REJECT for locked doors
          if method == 'unlocked'
            Rails.logger.warn "[BreakEscape] SECURITY VIOLATION: Client sent method='unlocked' for LOCKED door: #{target_id}"
            return false
          end

          # NPC unlock: Validate NPC has been encountered and has permission to unlock this door
          if method == 'npc'
            npc_id = attempt  # NPC id is passed as 'attempt'
            return validate_npc_unlock(npc_id, target_id)
          end

          result = case method
          when 'key'
            # Server validates player has the correct key in inventory
            is_valid = room['requires'].present? && has_key_in_inventory?(room['requires'])
            Rails.logger.info "[BreakEscape] Key validation result: #{is_valid}"
            is_valid
          when 'lockpick'
            # Server validates player has lockpick in inventory
            # Lockpick can bypass any key-based lock
            is_valid = has_lockpick_in_inventory?
            Rails.logger.info "[BreakEscape] Lockpick validation result: #{is_valid}"
            is_valid
          when 'biometric', 'bluetooth', 'rfid'
            # Client validated these - trust it
            # (player had fingerprint, had bluetooth device, had RFID card)
            Rails.logger.info "[BreakEscape] #{method} validation passed (trusted client)"
            true
          when 'pin', 'password'
            # Server validates password/PIN attempts
            is_valid = room['requires'].to_s == attempt.to_s
            Rails.logger.info "[BreakEscape] #{method} validation result: #{is_valid}"
            is_valid
          else
            Rails.logger.warn "[BreakEscape] SECURITY VIOLATION: No valid unlock method for LOCKED door: #{target_id}, method=#{method}"
            false
          end

          Rails.logger.info "[BreakEscape] validate_unlock returning: #{result}"
          return result
        else
          # Room is unlocked
          if method == 'unlocked'
            Rails.logger.info "[BreakEscape] Door is unlocked in scenario data, granting access"
            return true
          else
            Rails.logger.warn "[BreakEscape] Client sent method='#{method}' for UNLOCKED door: #{target_id}, but room has no lock"
            return true # Still allow access since room is unlocked
          end
        end
      else
        # Check if already unlocked in player state (grants access regardless of method)
        if object_unlocked?(target_id)
          Rails.logger.info "[BreakEscape] Object already unlocked in player state, granting access"
          return true
        end

        # Find object in all rooms - check both id and name
        scenario_data['rooms'].each do |_room_id, room_data|
          object = room_data['objects']&.find { |obj|
            obj['id'] == target_id || obj['name'] == target_id
          }

          if object
            Rails.logger.info "[BreakEscape] Found object: id=#{object['id']}, name=#{object['name']}, locked=#{object['locked']}, requires=#{object['requires']}"

            # Handle method='unlocked' - verify against scenario data
            if method == 'unlocked'
              if !object['locked']
                Rails.logger.info "[BreakEscape] Object is unlocked in scenario data, granting access"
                return true
              else
                Rails.logger.warn "[BreakEscape] SECURITY VIOLATION: Client sent method='unlocked' for LOCKED object: #{target_id}"
                return false
              end
            end

            # NPC unlock: Validate NPC has been encountered and has permission to unlock this object
            if method == 'npc'
              npc_id = attempt  # NPC id is passed as 'attempt'
              return validate_npc_unlock(npc_id, target_id)
            end

            case method
            when 'key', 'lockpick', 'biometric', 'bluetooth', 'rfid'
              # Client validated the unlock - trust it
              return true
            when 'pin', 'password'
              result = object['requires'].to_s == attempt.to_s
              Rails.logger.info "[BreakEscape] Password validation: required='#{object['requires']}', attempt='#{attempt}', result=#{result}"
              return result
            end
          end
        end
        Rails.logger.warn "[BreakEscape] Object not found: #{target_id}"
        false
      end
    end

    # Validate NPC unlock permission
    def validate_npc_unlock(npc_id, target_id)
      Rails.logger.info "[BreakEscape] Validating NPC unlock: npc=#{npc_id}, target=#{target_id}"

      # Find NPC in scenario data
      npc = find_npc_in_scenario(npc_id)
      unless npc
        Rails.logger.warn "[BreakEscape] NPC not found: #{npc_id}"
        return false
      end

      # Check if player has encountered this NPC
      unless player_state['encounteredNPCs']&.include?(npc_id)
        Rails.logger.warn "[BreakEscape] Player has not encountered NPC: #{npc_id}"
        return false
      end

      # Check if NPC has permission to unlock this target
      unlockable = npc['unlockable']
      unless unlockable.is_a?(Array) && unlockable.include?(target_id)
        Rails.logger.warn "[BreakEscape] NPC #{npc_id} does not have permission to unlock #{target_id}"
        return false
      end

      Rails.logger.info "[BreakEscape] NPC unlock validated: #{npc_id} can unlock #{target_id}"
      true
    end

    # Find NPC in scenario data
    def find_npc_in_scenario(npc_id)
      scenario_data['rooms']&.each do |_room_id, room_data|
        room_data['npcs']&.each do |npc|
          return npc if npc['id'] == npc_id
        end
      end
      nil
    end

    private

    def filter_requires_and_contents_recursive(obj)
      case obj
      when Hash
        # Remove 'requires' for exploitable lock types (key/pin/password/rfid)
        # Keep it for biometric/bluetooth since they reference collectible items, not answers
        lock_type = obj['lockType']
        if lock_type && !%w[biometric bluetooth].include?(lock_type)
          obj.delete('requires')
        end

        # Remove 'contents' if locked (lazy-loaded via separate endpoint)
        obj.delete('contents') if obj['locked']

        # Keep lockType - client needs it to show correct UI
        # Keep locked - client needs it to show lock status

        # Recursively filter nested objects and NPCs
        obj['objects']&.each { |o| filter_requires_and_contents_recursive(o) }
        obj['npcs']&.each { |n| filter_requires_and_contents_recursive(n) }

      when Array
        obj.each { |item| filter_requires_and_contents_recursive(item) }
      end
    end

    def generate_scenario_data
      # Only generate scenario data if it's not already set (e.g., in tests)
      self.scenario_data ||= mission.generate_scenario_data
    end

    def initialize_player_state
      # Ensure player_state is always a hash
      self.player_state = {} unless self.player_state.is_a?(Hash)
      
      self.player_state['currentRoom'] ||= scenario_data['startRoom']
      self.player_state['unlockedRooms'] ||= [scenario_data['startRoom']]
      self.player_state['unlockedObjects'] ||= []
      
      # Ensure inventory is always an array, even if it was corrupted
      unless self.player_state['inventory'].is_a?(Array)
        self.player_state['inventory'] = []
      end

      # Initialize starting items from scenario
      if scenario_data && scenario_data['startItemsInInventory']
        start_items = scenario_data['startItemsInInventory']
        if start_items.is_a?(Array)
          # Use dup instead of deep_dup to avoid issues with ActiveSupport extensions
          start_items.each do |item|
            self.player_state['inventory'] << (item.is_a?(Hash) ? item.dup : item)
          end
        else
          Rails.logger.warn "[BreakEscape] startItemsInInventory is not an Array: #{start_items.class}"
        end
      end

      self.player_state['encounteredNPCs'] ||= []
      self.player_state['globalVariables'] ||= {}
      self.player_state['biometricSamples'] ||= []
      self.player_state['biometricUnlocks'] ||= []
      self.player_state['bluetoothDevices'] ||= []
      self.player_state['notes'] ||= []
      self.player_state['health'] ||= 100
    end

    def set_started_at
      self.started_at ||= Time.current
    end
  end
end

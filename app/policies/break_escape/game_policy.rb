module BreakEscape
  class GamePolicy < ApplicationPolicy
    def show?
      # Owner or admin/account_manager
      record.player == user || user&.admin? || user&.account_manager?
    end

    def update?
      show?
    end

    def scenario?
      show?
    end

    def ink?
      show?
    end

    def bootstrap?
      show?
    end

    def sync_state?
      show?
    end

    def unlock?
      show?
    end

    def inventory?
      show?
    end

    class Scope < Scope
      def resolve
        if user&.admin? || user&.account_manager?
          scope.all
        else
          scope.where(player: user)
        end
      end
    end
  end
end

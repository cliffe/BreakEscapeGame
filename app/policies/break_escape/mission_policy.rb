module BreakEscape
  class MissionPolicy < ApplicationPolicy
    def index?
      true  # Everyone can see mission list
    end

    def show?
      # Published missions or admin
      record.published? || user&.admin? || user&.account_manager?
    end

    class Scope < Scope
      def resolve
        if user&.admin? || user&.account_manager?
          scope.all
        else
          scope.published
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  class MembershipPolicy < ApplicationPolicy
    def ready_status?
      check?(:user_is_member?)
    end

    def ready_toggle?
      check?(:user_is_member?)
    end

    def destroy?
      check?(:user_is_creator?)
    end

    def user_is_member?
      record.user == user
    end

    def user_is_creator?
      user.memberships.find_by(board_id: record.board.id, role: 'creator') ? true : false
    end
  end
end
# frozen_string_literal: true

#
# Service object to update special (drawless) groups
class DrawlessGroupUpdater < GroupUpdater
  private

  # Note that this occurs within the transaction
  def remove_users # rubocop:disable Metrics/AbcSize
    ids = pending_users[:remove].map(&:id)
    group.memberships.joins(:draw_membership)
         .where(draw_memberships: { user_id: ids }).delete_all
    # rubocop:disable Rails/SkipsModelValidations
    group.decrement!(:memberships_count, ids.size)
    # rubocop:enable Rails/SkipsModelValidations
    group.update_status!
    pending_users[:remove].each do |user|
      user.draw_membership.restore_draw.save!
    end
  end

  # Note that this occurs within the transaction
  def update_added_user(user)
    user.draw_membership.remove_draw.update!(intent: 'on_campus')
  end

  def success
    {
      redirect_object: group, record: group,
      msg: { success: 'Group successfully updated!' }
    }
  end

  # Note that this overrides the inherited validation in GroupUpdater
  def suite_size_exists
    return if SuiteSizesQuery.call.include? params[:size].to_i
    errors.add :size, 'must be a valid suite size'
  end
end

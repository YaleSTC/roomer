# frozen_string_literal: true
#
# Form / service object to handle the updating of draw students
class DrawStudentsUpdate
  include ActiveModel::Model

  attr_reader :class_year

  # permit :update to be called on the parent class
  def self.update(**params)
    new(**params).update
  end

  # Initialize a new DrawStudentsUpdate
  #
  # @param draw [Draw] the draw to be updated
  # @param params [#to_h] the parameters from the form
  def initialize(draw:, params: nil)
    @draw = draw
    process_params(params) if params
  end

  # Execute the suites update, remove all suites to be removed and add all
  # suites to be added. Occurs in a transaction for safety.
  #
  # @return [Hash{Symbol=>String,Hash,Nil,DrawStringUpdate] a result hash
  #   containing the appropriate path to redirect to, a flash message to set,
  #   and the DrawStudentsUpdate object if there were any failures.
  def update
    return no_action_warning if students_to_add.empty?
    ActiveRecord::Base.transaction do
      # update_all doesn't work since we have a left outer join in our ungrouped
      # students query
      students_to_add.each { |s| s.update(draw: draw) }
    end
    success
  rescue ActiveRecord::RecordInvalid => error
    error(error)
  end

  private

  attr_reader :draw, :params, :students_to_add

  def process_params(params)
    @params = params.to_h.transform_keys(&:to_sym)
    @params[:class_year] = nil if @params[:class_year].empty?
    @class_year = set_class_year
    @students_to_add = find_students_to_add
  end

  def set_class_year
    return nil unless params[:class_year]
    params[:class_year].to_i
  end

  def find_students_to_add
    return [] unless class_year
    UngroupedStudentsQuery.call.where(draw_id: nil, class_year: class_year)
  end

  def no_action_warning
    { object: nil, update_object: self, msg: { alert: 'No changes selected' } }
  end

  def success
    {
      object: nil, update_object: nil,
      msg: { success: 'Students successfully updated' }
    }
  end

  def error(error)
    {
      object: nil, update_object: self,
      msg: { error: "Students update failed: #{error}" }
    }
  end
end

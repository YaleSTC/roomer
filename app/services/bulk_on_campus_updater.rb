# frozen_string_literal: true
#
# Service object to set all undeclared students in a draw to on_campus intent
class BulkOnCampusUpdater
  # allow calling :update on the base class
  def self.update(**params)
    new(**params).update
  end

  # Initialize a new instance of BulkOnCampusUpdater
  #
  # @param draw [Draw] the draw in question
  def initialize(draw:)
    @draw = draw
  end

  # Perform the bulk intent update
  #
  # @return [Hash{Symbol=>Draw,Hash}] a results hash with the draw assigned to
  #   :object and a success flash message
  def update
    put_all_undeclared_students_on_campus
    success
  end

  private

  attr_reader :draw

  def put_all_undeclared_students_on_campus
    draw.students.where(intent: 'undeclared').update_all(intent: 'on_campus')
  end

  def success
    { object: draw,
      msg: { success: 'All undeclared students set to live on-campus' } }
  end
end

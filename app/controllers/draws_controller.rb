# frozen_string_literal: true
#
# Controller for Draws
class DrawsController < ApplicationController # rubocop:disable ClassLength
  prepend_before_action :set_draw, except: %i(index new create)
  before_action :calculate_metrics, only: %i(show activate start_lottery
                                             start_selection
                                             lottery_confirmation)

  def show; end

  def index
    @draws = Draw.all.order(:name)
  end

  def new
    @draw = Draw.new
  end

  def create
    result = DrawCreator.new(draw_params).create!
    @draw = result[:record]
    handle_action(action: 'new', **result)
  end

  def edit
  end

  def update
    result = Updater.new(object: @draw, name_method: :name,
                         params: draw_params).update
    @draw = result[:record]
    handle_action(action: 'edit', **result)
  end

  def destroy
    result = Destroyer.new(object: @draw, name_method: :name).destroy
    handle_action(path: draws_path, **result)
  end

  def activate
    result = DrawActivator.activate(draw: @draw)
    handle_action(action: 'show', **result)
  end

  def intent_report
    @filter = IntentReportFilter.new
    @students = @draw.students.order(:intent)
  end

  def filter_intent_report
    @filter = IntentReportFilter.new(filter_params)
    @students = @filter.filter(@draw.students)
    render action: 'intent_report'
  end

  def bulk_on_campus
    result = BulkOnCampusUpdater.update(draw: @draw)
    # note that BulkOnCampusUpdater.update always returns a success hash with
    # :object set to @draw, so we don't need to handle a fallback case via
    # handle_action
    handle_action(**result)
  end

  def suite_summary
    @all_sizes = SuiteSizesQuery.new(@draw.suites.available).call
    @suites_by_size = SuitesBySizeQuery.new(@draw.suites.available).call
    @suites_by_size.default = []
  end

  def suites_edit
    prepare_suites_edit_data
  end

  def suites_update
    result = DrawSuitesUpdate.update(draw: @draw, params: suites_update_params)
    @suites_update = result[:update_object]
    if @suites_update
      prepare_suites_edit_data
      result[:action] = 'suites_edit'
    else
      result[:path] = suite_summary_draw_path(@draw)
    end
    handle_action(**result)
  end

  def student_summary
    prepare_students_edit_data
  end

  def students_update
    result = if !students_update_params.empty?
               process_bulk_assignment
             elsif !student_assignment_params.empty?
               process_student_assignment
             else
               prepare_students_edit_data
               { object: nil, action: 'student_summary',
                 msg: { error: 'Invalid update submission' } }
             end
    handle_action(**result)
  end

  def lottery_confirmation; end

  def start_lottery
    @lottery_starter = DrawLotteryStarter.new(draw: @draw)
    result = @lottery_starter.start
    handle_action(action: 'lottery_confirmation', **result)
  end

  def lottery
    @groups = @draw.groups.includes(:leader).order('users.last_name')
  end

  def oversubscription
    calculate_suite_metrics
    calculate_group_metrics
    calculate_oversub_metrics
  end

  def toggle_size_lock
    result = DrawSizeLockToggler.toggle(draw: @draw, size: params[:size])
    handle_action(path: params[:redirect_path], **result)
  end

  def lock_all_sizes
    @draw.locked_sizes = @draw.suite_sizes
    msg_hash = if @draw.save
                 { success: 'All group sizes locked.' }
               else
                 errors = @draw.errors.full_messages.join(', ')
                 { error: "Size locking failed: #{errors}" }
               end
    handle_action(object: nil, path: params[:redirect_path], msg: msg_hash)
  end

  def start_selection
    result = DrawSelectionStarter.start(draw: @draw)
    handle_action(action: 'show', **result)
  end

  def select_suites
    @groups = @draw.next_groups
    if @groups.empty?
      @draw.update!(status: 'results')
      flash[:success] = 'All groups have suites!'
      redirect_to draw_path(@draw)
    end
    @suite_selector = BulkSuiteSelectionForm.new(groups: @groups)
    draw_suites = @draw.suites.available.where(size: @groups.map(&:size))
    @suites_by_size = SuitesBySizeQuery.new(draw_suites).call
  end

  def assign_suites
    @groups = @draw.next_groups
    @suite_selector = BulkSuiteSelectionForm.new(groups: @groups)
    @suite_selector.prepare(params: suite_selector_params)
    result = @suite_selector.submit
    handle_action(**result, path: select_suites_draw_path(@draw))
  end

  private

  def authorize!
    if @draw
      authorize @draw
    else
      authorize Draw
    end
  end

  def draw_params
    params.require(:draw).permit(:name, :intent_deadline, :intent_locked,
                                 suite_ids: [], student_ids: [],
                                 locked_sizes: [])
  end

  def suites_update_params
    params.require(:draw_suites_update).permit(suite_edit_param_hash)
  end

  def students_update_params
    params.fetch(:draw_students_update, {}).permit(:class_year)
  end

  def student_assignment_params
    params.fetch(:draw_student_assignment_form, {}).permit(%i(username adding))
  end

  def filter_params
    params.fetch(:intent_report_filter, {}).permit(intents: [])
  end

  def suite_selector_params
    params.require(:bulk_suite_selection_form)
          .permit(@suite_selector.valid_field_ids)
  end

  def set_draw
    @draw = Draw.includes(:groups, :suites).find(params[:id])
  end

  def calculate_metrics
    calculate_sizes
    calculate_suite_metrics
    calculate_group_metrics
    calculate_oversub_metrics
    calculate_ungrouped_students_metrics
  end

  def calculate_sizes
    @suite_sizes ||= @draw.suite_sizes
    @group_sizes ||= @draw.group_sizes
    @sizes ||= (@suite_sizes + @group_sizes).uniq.sort
  end

  def calculate_suite_metrics
    @suite_counts = @draw.suites.available.group(:size).count
    @suite_counts.default = 0
  end

  def calculate_group_metrics
    @groups = @draw.groups.includes(:leader)
    @groups_by_size = @groups.sort_by { |g| Group.statuses[g.status] }
                             .group_by(&:size)
    @groups_by_size.default = []
  end

  def calculate_oversub_metrics
    return unless policy(@draw).oversub_report?
    calculate_sizes
    @group_counts = @groups.group(:size).count
    @group_counts.default = 0
    @locked_counts = @groups.where(status: 'locked').group(:size).count
    @locked_counts.default = 0
    @diff = @sizes.map do |size|
      [size, @suite_counts[size] - @group_counts[size]]
    end.to_h
  end

  def calculate_ungrouped_students_metrics
    @ungrouped_students = UngroupedStudentsQuery.new(@draw.students).call
                                                .group_by(&:intent)
    @ungrouped_students.delete('off_campus')
  end

  def prepare_suites_edit_data # rubocop:disable AbcSize, MethodLength
    @suite_sizes ||= SuiteSizesQuery.new(Suite.available).call
    @suites_update ||= DrawSuitesUpdate.new(draw: @draw)
    base_suites = Suite.available.order(:number)
    empty_suite_hash = @suite_sizes.map { |s| [s, []] }.to_h
    @current_suites = empty_suite_hash.merge(
      @draw.suites.available.includes(:draws).order(:number).group_by(&:size)
    )
    @drawless_suites = empty_suite_hash.merge(
      DrawlessSuitesQuery.new(base_suites).call.group_by(&:size)
    )
    @drawn_suites = empty_suite_hash.merge(
      SuitesInOtherDrawsQuery.new(base_suites).call(draw: @draw)
                             .group_by(&:size)
    )
  end

  def prepare_students_edit_data
    @students_update ||= DrawStudentsUpdate.new(draw: @draw)
    @student_assignment_form ||= DrawStudentAssignmentForm.new(draw: @draw)
    @class_years = AvailableStudentClassYearsQuery.call
    @students = @draw.students.order(:last_name)
    @available_students_count = UngroupedStudentsQuery.call.where(draw_id: nil)
                                                      .count
  end

  def process_bulk_assignment
    result = DrawStudentsUpdate.update(draw: @draw,
                                       params: students_update_params)
    @students_update = result[:update_object]
    if @students_update
      prepare_students_edit_data
      result[:action] = 'student_summary'
    else
      result[:path] = student_summary_draw_path(@draw)
    end
    result
  end

  def process_student_assignment
    result = DrawStudentAssignmentForm.submit(draw: @draw,
                                              params: student_assignment_params)
    @student_assignment_form = result[:update_object]
    if @student_assignment_form
      prepare_students_edit_data
      result[:action] = 'student_summary'
    else
      result[:path] = student_summary_draw_path(@draw)
    end
    result
  end

  def suite_edit_param_hash
    suite_edit_sizes.flat_map do |s|
      DrawSuitesUpdate::CONSOLIDATED_ATTRS.map { |p| ["#{p}_#{s}".to_sym, []] }
    end.to_h
  end

  def suite_edit_sizes
    @suite_edit_sizes ||= SuiteSizesQuery.new(Suite.available).call
  end
end

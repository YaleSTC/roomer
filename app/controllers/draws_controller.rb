# frozen_string_literal: true

# Controller for Draws
class DrawsController < ApplicationController # rubocop:disable ClassLength
  prepend_before_action :set_draw, except: %i(new create)
  before_action :calculate_metrics, only: %i(show activate start_lottery
                                             proceed_to_group_formation
                                             start_selection
                                             lottery_confirmation
                                             oversubscription prune)

  def show
    @suites_by_size =
      @draw.suites_by_size
           .transform_values! { |v| v.map { |s| SuiteDecorator.new(s) } }
  end

  def new
    @draw = Draw.new
  end

  def create
    result = Creator.create!(params: draw_params, klass: Draw,
                             name_method: :name)
    @draw = result[:record]
    handle_action(action: 'new', **result)
  end

  def edit; end

  def update
    result = Updater.update(object: @draw, name_method: :name,
                            params: draw_params)
    @draw = result[:record]
    handle_action(action: 'edit', **result)
  end

  def destroy
    result = Destroyer.destroy(object: @draw, name_method: :name)
    handle_action(path: root_path, **result)
  end

  def archive
    result = DrawArchiver.archive(draw: @draw)
    handle_action(path: root_path, **result)
  end

  def activate
    result = DrawActivator.activate(draw: @draw.__getobj__)
    handle_action(action: 'show', **result)
  end

  def duplicate
    result = DrawDuplicator.duplicate(draw: @draw)
    handle_action(action: 'show', **result)
  end

  def proceed_to_group_formation
    result = DrawGroupFormationStarter.start(draw: @draw.__getobj__)
    handle_action(action: 'show', **result)
  end

  def bulk_on_campus
    result = BulkOnCampusUpdater.update(draw: @draw)
    # note that BulkOnCampusUpdater.update always returns a success hash with
    # :redirect_object set to nil, so we need to provide a redirect path
    handle_action(**result.merge(path: report_draw_intents_path(@draw)))
  end

  def lottery_confirmation; end

  def start_lottery
    @lottery_starter = DrawLotteryStarter.new(draw: @draw.__getobj__)
    result = @lottery_starter.start
    handle_action(action: 'lottery_confirmation', **result)
  end

  def oversubscription; end

  def toggle_size_restrict
    result = DrawSizeRestrictToggler.toggle(draw: @draw, size: params[:size])
    handle_action(path: params[:redirect_path], **result)
  end

  def restrict_all_sizes
    result = Updater.update(object: @draw, name_method: :name,
                            params: { restricted_sizes: @draw.suite_sizes })

    handle_action(**result.merge!(redirect_object: nil,
                                  path: params[:redirect_path]))
  end

  def lock_all_groups
    result = BulkGroupLocker.update(draw: @draw)
    handle_action(**result)
  end

  def prune
    sizes = if prune_params[:prune_size] == 'all'
              @draw.oversubscribed_sizes
            else
              [prune_params[:prune_size].to_i]
            end
    result = OversubscriptionPruner.prune(draw_report: @draw, sizes: sizes)
    handle_action(path: request.referer, **result)
  end

  def start_selection
    result = DrawSelectionStarter.start(draw: @draw.__getobj__)
    handle_action(action: 'show', **result)
  end

  def reminder
    # note that this will always redirect to draw show
    result = ReminderQueuer.queue(draw: @draw, type: draw_params['email_type'])
    handle_action(**result)
  end

  def results
    @suites_with_results =
      SuitesWithRoomsAssignedQuery.new(@draw.suites).call
                                  .map { |suite| SuiteDecorator.new(suite) }
  end

  def group_export
    @groups = @draw.groups.includes(:lottery_assignment)
                   .order('lottery_assignments.number')
    attributes = %i(name lottery_number suite_number)
    result = CSVGenerator.generate(data: @groups, attributes: attributes,
                                   name: 'groups')
    handle_file_action(**result)
  end

  private

  def authorize!
    if @draw
      authorize @draw, :browsable?
      authorize @draw
    else
      authorize Draw
    end
  end

  def draw_params
    params.require(:draw).permit(:name, :intent_deadline, :intent_locked,
                                 :email_type, :locking_deadline,
                                 restricted_sizes: [])
  end

  def prune_params
    {
      id: params.fetch(:id, ''),
      prune_size: params.fetch(:prune_size, '')
    }
  end

  def set_draw
    @draw = Draw.includes(suites: :draws,
                          groups: [:lottery_assignment, leader: :room,
                                                        suite: :building])
                .find(params[:id])
  end

  def calculate_metrics
    @draw = DrawReport.new(@draw)
  end
end

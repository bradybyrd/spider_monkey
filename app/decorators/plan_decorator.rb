class PlanDecorator < ApplicationDecorator
  decorates :plan

  delegate_all

  def plan_button
    h.link_to(
      h.image_tag('plan.png', title: 'Plan the RP'),
      h.update_state_plan_path(plan, state: 'plan_it'),
      class: 'plan_plan'
    ).html_safe + separator
  end

  def start_button
    h.link_to(
      h.image_tag('start_plans.png', title: 'Start the RP'),
      h.update_state_plan_path(plan, state: 'start'),
      class: 'start_plan'
    ).html_safe + separator
  end

  def cancel_button
    h.link_to(
      h.image_tag('life_c_cancel.png', title: 'Cancel the RP'),
      h.update_state_plan_path(plan, state: 'cancel'),
      confirm: 'Are you sure you want to cancel the Plan?',
      class: 'cancel_plan'
    ).html_safe + separator
  end

  def delete_button
    h.link_to(
      h.image_tag('life_c_delete.png', title: 'Delete the RP'),
      h.update_state_plan_path(plan, state: 'delete'),
      confirm: 'Are you sure you want to delete the Release Plan?',
      class: 'delete_plan'
    ).html_safe + separator
  end

  def lock_button
    h.link_to(
      h.image_tag('lock.png', title: 'Lock the RP'),
      h.update_state_plan_path(plan, state: 'lock'),
      class: 'lock_plan'
    ).html_safe + separator
  end

  def hold_button
    h.link_to(
      h.image_tag('hold.png', title: 'Hold the RP'),
      h.update_state_plan_path(plan, state: 'hold'),
      class: 'hold_plan'
    ).html_safe + separator
  end

  def complete_button
    h.link_to(
      h.image_tag('complete.png', title: 'Complete the RP'),
      h.update_state_plan_path(plan, state: 'finish'),
      class: 'complete_plan'
    ).html_safe + separator
  end

  def reopen_button
    h.link_to(
      h.image_tag('btn-reopen-plan.png', title: 'Reopen Plan'),
      h.update_state_plan_path(plan, state: 'reopen'),
      confirm: 'Are you sure you want to reopen the Plan?',
      class: 'reopen_plan'
    ).html_safe + separator
  end

  def archive_button
    h.link_to(
      h.image_tag('archive.png', title: 'Archive the RP'),
      h.update_state_plan_path(plan, state: 'archived'),
      confirm: 'Archived plan cannot be edited. Are you sure you want to archive the Plan?',
      class: 'archive_plan'
    ).html_safe + separator
  end

  def unarchive_button
    h.link_to(
      h.image_tag('btn-unarchive-plan.png', title: 'Unarchive the RP'),
      h.update_state_plan_path(plan, state: 'finish'),
      class: 'unarchive_plan'
    ).html_safe + separator
  end

  private

  def separator
    "<br class='clear'/><br class='clear'/>".html_safe
  end

end

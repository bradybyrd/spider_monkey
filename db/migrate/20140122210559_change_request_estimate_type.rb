class ChangeRequestEstimateType < ActiveRecord::Migration
  def up
    estimates = Request.pluck :estimate

    remove_column :requests, :estimate
    add_column :requests, :estimate, :integer

    requests_est_to_int estimates
  end


  def down
    remove_column :requests, :estimate
    add_column :requests, :estimate, :text
  end

  def requests_est_to_int(estimates)
    request_estimates_items = {
        '1 hour' => 60, '1/2 day' => 720, '1 day' => 1440,
        '2 days'=> 48*60, '1 week'=> 168*60, 'weeks'=> 504*60, 'months'=> 1440*60
    }
    Request.transaction do
      Request.all.each_with_index do |r, i|
        estimate = request_estimates_items[estimates[i]] rescue nil
        r.update_column :estimate, estimate
      end
    end
  end

end

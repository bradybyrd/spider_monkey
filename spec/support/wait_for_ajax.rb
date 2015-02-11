# source: http://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
# https://coderwall.com/p/aklybw
module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    return_value = page.evaluate_script <<-SCRIPT.strip.gsub(/\s+/,' ')
      (function () {
        if (typeof jQuery != 'undefined') {
          return jQuery.active;
        }
        else {
          console.log("Failed on the page: " + document.URL);
          console.error("An error occurred when checking for `jQuery.active`.");
        }
      })()
    SCRIPT
    return_value and return_value.zero?
  end
end
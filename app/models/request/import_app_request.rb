class Request < ActiveRecord::Base

  class << self

    def import_app(reqs_xml_hash, app, importing_user)
      if reqs_xml_hash.present?
        reqs_xml_hash.each do |key, val|
          reqtemplatename = key["request_template"]["name"]
          unless reqtemplatename.blank?
            @reqtemplate = RequestTemplate.find_by_name(reqtemplatename)
            if @reqtemplate.nil?
              @reqtemplate = RequestTemplate.create(name: reqtemplatename)
              @request = Request.create(name: key["name"], app_ids: [app.id])
            else
              @request = find_by_request_template_id(@reqtemplate.id)
            end
            @reqtemplate.aasm_state = key["request_template"]["aasm_state"]
            @reqtemplate.save(:validate => false)
            if key['request_template']['automation_scripts_for_export']
              ResourceAutomationsImporter.new(key).import
              automation_scripts = key['request_template']['automation_scripts_for_export'].compact
              AutomationsImporter.new(automation_scripts).import
            end
            build_request_template_association(@request, @reqtemplate, key, app, importing_user)
          end
        end
      end
    end

    def build_request_template_association(request, reqtemplate, reqs_components_xml_hash, app, importing_user)
      build_request_attributes(request, reqs_components_xml_hash)
      request.save(:validate => false)
      request.request_template_id = reqtemplate.id
      build_request_associations(@request, reqs_components_xml_hash, app, importing_user)
      request.save(:validate => false)
      build_change_notification_options(request, reqs_components_xml_hash)
    end

    def build_request_attributes(request, reqs_components_xml_hash)
      request.name = reqs_components_xml_hash["name"]
      if reqs_components_xml_hash["description"] && reqs_components_xml_hash["description"].kind_of?(String)
        request.description = reqs_components_xml_hash["description"]
      end
      request.auto_start = reqs_components_xml_hash["auto_start"]
      request.rescheduled = reqs_components_xml_hash["rescheduled"]
      if reqs_components_xml_hash["wiki_url"] && reqs_components_xml_hash["wiki_url"].kind_of?(String)
        request.wiki_url = reqs_components_xml_hash["wiki_url"]
      end
      request.estimate = reqs_components_xml_hash["estimate"]
      request.scheduled_at = reqs_components_xml_hash["scheduled_at"]
      request.target_completion_at = reqs_components_xml_hash["target_completion_at"]
      request.deployment_coordinator_id = User.current_user.id
      build_email_addresses(request, reqs_components_xml_hash)
    end

    def build_change_notification_options(request, xml_hash)
      request_params = xml_hash.select { |key| key.match(/^notify_on_/) }
      request.update_attributes!(request_params)
    end

    def build_request_associations(request, reqs_components_xml_hash, app, importing_user)
      build_requestor(request, reqs_components_xml_hash,)
      build_owner(request, reqs_components_xml_hash)
      EmailRecipient.import_app(request, reqs_components_xml_hash)
      Note.import_app(request, reqs_components_xml_hash, 'Request')
      RequestPackageContent.import_app(request, reqs_components_xml_hash)
      request.environment_id = Environment.import_app_request(reqs_components_xml_hash)
      request.release_id = Release.import_app(reqs_components_xml_hash)
      request.business_process_id = BusinessProcess.import_app_request(reqs_components_xml_hash)
      Step.import_app(request, reqs_components_xml_hash, app, importing_user)
    end

    def build_requestor(request, reqs_components_xml_hash)
      if reqs_components_xml_hash["requestor"]
        name = reqs_components_xml_hash["requestor"]["name"].split(',')
        obj = User.find_by_last_name_and_first_name(name[0].squish, name[1].squish)
        if obj
          request.requestor_id = obj.id
        else
          request.requestor_id = User.current_user.id
        end
      end
    end

    def build_owner(request, reqs_components_xml_hash)
      if reqs_components_xml_hash["owner"]
        name = reqs_components_xml_hash["owner"]["name"].split(',')
        obj = User.find_by_last_name_and_first_name(name[0].squish, name[1].squish)
        if obj
          request.owner_id = obj.id
        else
          request.owner_id = User.current_user.id
        end
      end
    end

    def build_email_addresses(request, reqs_components_xml_hash)
      emailaddresses = reqs_components_xml_hash["additional_email_addresses"]
      if emailaddresses.present?
        request.additional_email_addresses = emailaddresses.join(",")
      end
    end
  end

  def is_exportable?(request)
    request.created? && request.request_template_id.present? &&
    request.request_template["aasm_state"] != "draft" && request.request_template["aasm_state"] != "archived_state"
  end
end

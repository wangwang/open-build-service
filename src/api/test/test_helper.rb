ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'action_controller/integration'
# uncomment to enable tests which currently are known to fail, but where either the test
# or the code has to be fixed
#$ENABLE_BROKEN_TEST=true

module ActionController
  module Integration #:nodoc:
    class Session
      def add_auth(headers)
        headers = Hash.new if headers.nil?
        if !headers.has_key? "HTTP_AUTHORIZATION" and IntegrationTest.basic_auth
          headers["HTTP_AUTHORIZATION"] = IntegrationTest.basic_auth
        end
        return headers
      end

      alias_method :real_process, :process
      def process(method, path, parameters, rack_env)
        ActiveXML::Config.global_write_through = true
        self.accept = "text/xml,application/xml"
        real_process(method, path, parameters, add_auth(rack_env))
      end

    end
  end

  class IntegrationTest

    @@auth = nil

    def self.reset_auth
      @@auth = nil
    end

    def self.basic_auth
      return @@auth
    end

    def prepare_request_with_user( user, passwd )
      re = 'Basic ' + Base64.encode64( user + ':' + passwd )
      @@auth = re
    end
  
    # will provide a user without special permissions
    def prepare_request_valid_user 
      prepare_request_with_user 'tom', 'thunder'
    end
  
    def prepare_request_invalid_user
      prepare_request_with_user 'tom123', 'thunder123'
    end

    def load_backend_file(path)
      File.open(ActionController::TestCase.fixture_path + "/backend/#{path}").read()
    end

    def assert_xml_tag(conds)
      node = ActiveXML::Base.new(@response.body)
      ret = node.find_matching(NodeMatcher::Conditions.new(conds))
      assert ret, "expected tag, but no tag found matching #{conds.inspect} in:\n#{node.dump_xml}" unless ret
    end

    def assert_no_xml_tag(conds)
     node = ActiveXML::Base.new(@response.body)
     ret = node.find_matching(NodeMatcher::Conditions.new(conds))
     assert !ret, "expected no tag, but found tag matching #{conds.inspect} in:\n#{node.dump_xml}" if ret
    end
  end 
end

module ActiveSupport
  class TestCase
    def assert_xml_tag(data, conds)
      node = ActiveXML::Base.new(data)
      ret = node.find_matching(NodeMatcher::Conditions.new(conds))
      assert ret, "expected tag, but no tag found matching #{conds.inspect} in:\n#{node.dump_xml}" unless ret
    end

    def assert_no_xml_tag(data, conds)
      node = ActiveXML::Base.new(data)
      ret = node.find_matching(NodeMatcher::Conditions.new(conds))
      assert !ret, "expected no tag, but found tag matching #{conds.inspect} in:\n#{node.dump_xml}" if ret
    end

  end
end


# The MIT License (MIT)
#
# Copyright (c) 2015 Chris Zeeb <chris.zeeb@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

require 'aws-sdk'
require 'yaml'
require_relative '../integrationtest_finder'

# comment goes here
class IntegrationtestFinder
  # comment goes here
  class Opsworks < IntegrationtestFinder
    attr_accessor :client
    def initialize
      super
      @instance_agent_config = '/etc/aws/opsworks/instance-agent.yml'
      @lifecycles = %i(setup configure deploy undeploy shutdown)
      @client = Aws::OpsWorks::Client.new(region: 'us-east-1')
    end

    def find_serverspecs
      instance_resp = describe_instance

      instance_resp[:instances][0][:layer_ids].each do |instance|
        layer_resp = client.describe_layers(layer_ids: ["#{instance}"])
        @lifecycles.each do |lifecycle|
          lifecycle_element = layer_resp[:layers][0][:custom_recipes][lifecycle]
          recipes_from_opsworks_lifecycle(lifecycle_element)
        end
      end
      fetch_targets
    end

    private

    def describe_instance
      opsworks_instance_agent_config ||= YAML.load_file(@instance_agent_config)

      instance_resp = client.describe_instances(
        instance_ids: ["#{opsworks_instance_agent_config[:identity]}"]
      )

      instance_resp
    end

    def parse_recipename(full_recipe)
      cookbook = ''
      suite = ''
      if full_recipe =~ /^([A-Za-z0-9\-]+)$/
        cookbook = Regexp.last_match(1)
        suite = 'default'
      elsif full_recipe =~ /^([A-Za-z0-9\-]+)\:\:(\w+)$/
        cookbook = Regexp.last_match(1)
        suite = Regexp.last_match(2)
      end

      [cookbook, suite]
    end

    def recipes_from_opsworks_lifecycle(lifecycle)
      lifecycle.each do |full_recipe|
        cookbook, suite = parse_recipename(full_recipe)

        next if cookbook.nil?

        serverspec_dir = '/opt/aws/opsworks/current/merged-cookbooks/' +
                         cookbook + '/test/integration/' +
                         suite + '/serverspec/'

        add_to_targets(serverspec_dir)
      end
    end
  end
end

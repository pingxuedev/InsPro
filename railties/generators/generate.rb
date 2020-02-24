#!/usr/local/bin/ruby
require File.dirname(__FILE__) + '/../config/environment'
require 'rails_generator'

unless ARGV.empty?
  begin
    name = ARGV.shift
    Rails::Generator.instance(name, ARGV).generate
  rescue Rails::Generator::UsageError => e
    puts e.message
  end
else
  builtin_generators = Rails::Generator.builtin_generators.join(', ')
  contrib_generators = Rails::Generator.contrib_generators.join(', ')

  $stderr.puts <<end_usage
  #{$0} generator [args]

  Rails comes with #{builtin_generators} generators.
    #{$0} controller Login login logout
    #{$0} model Account
    #{$0} mailer AccountMailer
    #{$0} scaffold Account action another_action

end_usage

  unless contrib_generators.empty?
    $stderr.puts "  Installed generators (in #{RAILS_ROOT}/generators):"
    $stderr.puts "    #{contrib_generators}"
    $stderr.puts
  end

  $stderr.puts <<end_usage
  More generators are available at http://rubyonrails.org
    1. Download, for example, auth_controller.zip
    2. Unzip to directory #{RAILS_ROOT}/generators/auth_controller
    3. Generate without args for usage information
         #{$0} auth_controller
end_usage
  exit 0
end
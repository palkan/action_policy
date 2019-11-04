# frozen_string_literal: true

require "spec_helper"
require "generators/action_policy/install/install_generator"

describe ActionPolicy::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:args) { [] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe "application policy" do
    subject { file("app/policies/application_policy.rb") }

    it { is_expected_to exist }
    it { is_expected_to contain(/class ApplicationPolicy < ActionPolicy::Base/) }
  end
end

require_relative '../../lib/slack'
require_relative '../../lib/features'

RSpec.describe Slack do
  around do |ex|
    ClimateControl.modify SLACK_WEBHOOK_URL: 'https://example.com' do
      ex.run
    end
  end

  describe '.post_deployers_for_today' do
    it 'sends a message to slack' do
      deployers = %w[A B C]

      slack_request = stub_request(:post, 'https://example.com')

      Timecop.freeze('2020-05-27') do
        Slack.post_deployers_for_today(deployers)
      end

      expect(slack_request.with(body: hash_including(text: 'Today’s deployer is *A*. Reserves: *B*, *C*')))
        .to have_been_made
    end

    it 'takes the weekend off' do
      deployers = %w[A B C]

      slack_request = stub_request(:post, 'https://example.com')

      Timecop.freeze('2020-05-24') do
        Slack.post_deployers_for_today(deployers)
      end

      expect(slack_request).not_to have_been_made
    end
  end

  describe '.post_confused_features' do
    it 'sends a message when features are confused' do
      confused_features = [
        Features::Feature.new(name: 'Wonky feature', production: true, staging: false, sandbox: false, qa: false),
      ]

      slack_request = stub_request(:post, 'https://example.com')

      Slack.post_confused_features(confused_features)

      expect(slack_request.with(body: hash_including(text: /Uh-oh!.*?Wonky feature/m)))
        .to have_been_made
    end

    it 'sends a message when features are OK' do
      slack_request = stub_request(:post, 'https://example.com')

      Slack.post_confused_features([])

      expect(slack_request.with(body: hash_including(text: /Feature flags are consistent/)))
        .to have_been_made
    end
  end
end

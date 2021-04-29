---
title: Service Objects for Good
date: 2018-04-18
categories:
  - Development
tags:
  - ruby
  - rails
---

Service objects are a handy tool to use in any ruby application, that has
complex logic that needs to be extracted out of a controller or model. There are
some nice benefits to extracting complex things into a more testable interface.

To avoid providing a contrived example, I will use similar code to how uploads
on [rubyfm](https://ruby.fm) are handled.

```ruby
class UploadService
  attr_reader :user, :logger, :upload

  def initialize(user, options = {})
    @user   = user
    @logger = options[:logger] || NullObject.new
    @errors = {}
  end

  def start(params)
    @upload = build_from_params(params)

    unless @upload.save
      logger.error { 'failed to save the upload' }
      # more logging info on why
      return false
    end

    unless transcode
      logger.error { 'failed to transcode upload' }
      return false
    end

    true
  end

  def transcode
    AmazonTranscodeService.new(@upload).start
  end
end
```

And the `UploadsController` that utilizes the `UploadService` with the
following.

```ruby
class UploadsController < AuthorizedController
  def create
    service = UploadService.new(current_user, logger: Rails.logger)

    if upload_params[:episode_id]
      episode = Episode.find_by(id: upload_params[:episode_id])
      authorize!(episode, :update?)
    end

    if service.start(upload_params)
      flash[:info] = I18n.t('upload.processing_started')
      redirect_to(upload_url(service.upload.id))
    else
      flash[:error] = I18n.t('upload.failed')
      redirect_to(new_channel_episode_url(primary_channel))
    end
  end
end
```

Attempting to shove all of that logic into a controller action would simply be
unmantainable and probably not well tested. With this setup you can isolate the
service object from the request / controller tests and really excercise it at
all of the potential fail points.

For example, we use Amazon to handle transcoding and I needed a test to ensure
all issues would be caught and wrapped appropriately.

```ruby
RSpec.describe UploadService, '#start', type: :service do
  let(:user)    { Fabricate(:user) }
  let(:service) { described_class.new(user) }

  context 'when amazon fails to transcode' do
    it 'returns false' do
      allow(service).to receive(:transcode).and_return(false)

      expect(service.start(episode_id: SecureRandom.uuid)).to eq(false)
    end
  end

  context 'when amazon transcode is successful' do
    it 'returns true' do
      allow(service).to receive(:transcode).and_return(true)

      expect(service.start(episode_id: SecureRandom.uuid)).to eq(true)
    end
  end
end
```

Go forth and use services where complex controller actions exist.

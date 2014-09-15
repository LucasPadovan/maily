module Maily
  class EmailsController < ApplicationController
    before_filter :allowed_action?, only: [:edit, :update, :deliver]
    before_filter :load_mailers, only: [:index, :show, :edit]
    before_filter :load_mailer_and_email, except: [:index]
    before_filter :setup_locale, only: [:show, :raw, :deliver]
    around_filter :perform_with_locale, only: [:show, :raw, :deliver]

    def index
    end

    def show
    end

    def raw
      content = if @email.parts.present?
        params[:part] == 'text' ? @email.text_part.body : @email.html_part.body
      else
        @email.body
      end

      render text: content, layout: false
    end

    def attachment
      attachment = @email.attachments.find { |elem| elem.filename == params[:attachment] }
      send_data attachment.body, filename: attachment.filename, type: attachment.content_type
    end

    def edit
      @template = @maily_email.template(params[:part])
    end

    def update
      @maily_email.update_template(params[:body], params[:part])

      redirect_to maily_email_path(mailer: params[:mailer], email: params[:email], part: params[:part])
    end

    def deliver
      @email.to = params[:to]

      @email.deliver

      redirect_to maily_email_path(mailer: params[:mailer], email: params[:email])
    end

    private

    def allowed_action?
      Maily.allowed_action?(action_name) || raise("Maily: action #{action_name} not allowed!")
    end

    def load_mailers
      @mailers = Maily::Mailer.all
    end

    def load_mailer_and_email
      mailer = Maily::Mailer.find(params[:mailer])
      @maily_email = mailer.find_email(params[:email])
      @email = @maily_email.call
    end

    def perform_with_locale
      I18n.with_locale(params[:locale]) do
        yield
      end
    end

    def setup_locale
      $locale = params[:locale] || case request.domain(0)
                                     when 'br' then :pt
                                     else           :es
                                   end
    end
  end
end

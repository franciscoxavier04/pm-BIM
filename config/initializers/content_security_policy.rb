# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.config.after_initialize do
  Rails.application.configure do
    config.content_security_policy do |policy|
      # Valid for assets
      assets_src = ["'self'"]
      asset_host = OpenProject::Configuration.rails_asset_host
      assets_src << asset_host if asset_host.present?

      # Valid for iframes
      frame_src = %w['self' https://player.vimeo.com https://www.youtube.com] # rubocop:disable Lint/PercentStringArray
      frame_src << OpenProject::Configuration[:security_badge_url]

      # Default src
      default_src = %w('self') # rubocop:disable Lint/PercentStringArray

      # Attachment uploaders
      default_src += OpenProject::Configuration.remote_storage_hosts

      # Chargebee self-service
      chargebee_src = [
        "https://js.chargebee.com/",
        "#{OpenProject::Configuration.enterprise_chargebee_site}.chargebee.com"
      ]

      assets_src += chargebee_src
      frame_src += chargebee_src
      default_src += chargebee_src

      # Allow requests to CLI in dev mode
      connect_src = default_src + [OpenProject::Configuration.enterprise_trial_creation_host]

      # Rules for media (e.g. video sources)
      media_src = default_src
      media_src << asset_host if asset_host.present?

      if OpenProject::Configuration.appsignal_frontend_key
        connect_src += ["https://appsignal-endpoint.net"]
      end

      # Allow connections to S3 for BIM
      if OpenProject::Configuration.fog_directory.present?
        connect_src += [
          "#{OpenProject::Configuration.fog_directory}.s3-#{OpenProject::Configuration.fog_credentials[:region]}.amazonaws.com"
        ]
      end

      # Add proxy configuration for Angular CLI to csp
      if FrontendAssetHelper.assets_proxied?
        proxied = ["ws://#{Setting.host_name}", "http://#{Setting.host_name}",
                   FrontendAssetHelper.cli_proxy.sub("http", "ws"), FrontendAssetHelper.cli_proxy]
        connect_src += proxied
        assets_src += proxied
        media_src += proxied
      end

      # Allow to extend the script-src in specific situations
      script_src = assets_src + %w(js.chargebee.com)

      # Allow unsafe-eval for rack-mini-profiler
      if Rails.env.development? && ENV.fetch("OPENPROJECT_RACK_PROFILER_ENABLED", false)
        script_src += %w('unsafe-eval') # rubocop:disable Lint/PercentStringArray
      end

      # Allow ANDI bookmarklet to run in development mode
      # https://www.ssa.gov/accessibility/andi/help/install.html
      if Rails.env.development?
        script_src += ["https://www.ssa.gov"]
        assets_src += ["https://www.ssa.gov"]
      end

      form_action = default_src

      # Allow test s3 bucket for direct uploads in tests
      if Rails.env.test?
        connect_src += ["test-bucket.s3.amazonaws.com"]
        form_action += ["test-bucket.s3.amazonaws.com"]
      end

      # Configure CSP directives
      policy.default_src(*default_src)
      policy.base_uri("'self'")
      policy.font_src(*assets_src, "data:", "'self'")
      policy.form_action(*form_action)
      policy.frame_src(*frame_src, "'self'")
      policy.frame_ancestors("'self'")
      policy.img_src("*", "data:", "blob:")
      policy.script_src(*script_src)
      policy.script_src_attr("'none'")
      policy.style_src(*assets_src, "'unsafe-inline'")
      policy.object_src(OpenProject::Configuration[:security_badge_url])
      policy.connect_src(*connect_src)
      policy.media_src(*media_src)
    end

    # Generate session nonces for permitted importmap, inline scripts, and inline styles.
    # This handles Turbo integration natively
    config.content_security_policy_nonce_generator = lambda do |request|
      # Use Turbo nonce if available (for Turbo navigation)
      if request.env["HTTP_TURBO_REFERRER"].present? && request.env["HTTP_X_TURBO_NONCE"].present?
        request.env["HTTP_X_TURBO_NONCE"]
      else
        # Generate a new nonce based on session
        SecureRandom.base64(16)
      end
    end

    config.content_security_policy_nonce_directives = %w(script-src)
  end
end

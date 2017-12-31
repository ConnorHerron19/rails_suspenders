require 'rails/generators'
require 'rails/generators/rails/app/app_generator'

module Suspenders
  class AppGenerator < Rails::Generators::AppGenerator
    hide!

    class_option :database, type: :string, aliases: "-d", default: "postgresql",
      desc: "Configure for selected database (options: #{DATABASES.join("/")})"

    class_option :heroku, type: :boolean, aliases: "-H", default: false,
      desc: "Create staging and production Heroku apps"

    class_option :heroku_flags, type: :string, default: "",
      desc: "Set extra Heroku flags"

    class_option :github, type: :string, default: nil,
      desc: "Create Github repository and add remote origin pointed to repo"

    class_option :version, type: :boolean, aliases: "-v", group: :suspenders,
      desc: "Show Suspenders version number and quit"

    class_option :help, type: :boolean, aliases: '-h', group: :suspenders,
      desc: "Show this help message and quit"

    class_option :path, type: :string, default: nil,
      desc: "Path to the gem"

    class_option :skip_test, type: :boolean, default: true,
      desc: "Skip Test Unit"

    class_option :skip_system_test,
                 type: :boolean, default: true, desc: "Skip system test files"

    class_option :skip_turbolinks,
                 type: :boolean, default: true, desc: "Skip turbolinks gem"

    def finish_template
      invoke :suspenders_customization
      super
    end

    def suspenders_customization
      invoke :customize_gemfile
      invoke :setup_development_environment
      invoke :setup_test_environment
      invoke :setup_production_environment
      invoke :setup_secret_token
      invoke :create_suspenders_views
      invoke :configure_app
      invoke :copy_miscellaneous_files
      invoke :customize_error_pages
      invoke :remove_config_comment_lines
      invoke :remove_routes_comment_lines
      invoke :setup_dotfiles
      invoke :setup_database
      invoke :create_github_repo
      invoke :setup_segment
      invoke :setup_bundler_audit
      invoke :setup_spring
      invoke :generate_default
      invoke :setup_default_directories
      invoke :create_local_heroku_setup
      invoke :create_heroku_apps
      invoke :outro
    end

    def customize_gemfile
      build :replace_gemfile, options[:path]
      build :set_ruby_to_version_being_used
      bundle_command 'install'
    end

    def setup_database
      say 'Setting up database'

      if 'postgresql' == options[:database]
        build :use_postgres_config_template
      end

      build :create_database
    end

    def setup_development_environment
      say 'Setting up the development environment'
      build :raise_on_missing_assets_in_test
      build :raise_on_delivery_errors
      build :set_test_delivery_method
      build :raise_on_unpermitted_parameters
      build :provide_setup_script
      build :configure_generators
      build :configure_i18n_for_missing_translations
      build :configure_quiet_assets
    end

    def setup_test_environment
      say 'Setting up the test environment'
      build :set_up_factory_bot_for_rspec
      build :generate_factories_file
      build :generate_rspec
      build :configure_rspec
      build :configure_background_jobs_for_rspec
      build :provide_shoulda_matchers_config
      build :configure_spec_support_features
      build :configure_ci
      build :configure_i18n_for_test_environment
      build :configure_action_mailer_in_specs
      build :configure_capybara_webkit
    end

    def setup_production_environment
      say 'Setting up the production environment'
      build :configure_smtp
      build :configure_rack_timeout
      build :enable_rack_canonical_host
      build :enable_rack_deflater
      build :setup_asset_host
    end

    def setup_secret_token
      say 'Moving secret token out of version control'
      build :setup_secret_token
    end

    def create_suspenders_views
      say 'Creating suspenders views'
      build :create_partials_directory
      build :create_shared_flashes
      build :create_shared_javascripts
      build :create_shared_css_overrides
      build :create_application_layout
    end

    def configure_app
      say 'Configuring app'
      build :configure_action_mailer
      build :configure_active_job
      build :configure_time_formats
      build :setup_default_rake_task
      build :replace_default_puma_configuration
      build :set_up_forego
      build :setup_rack_mini_profiler
    end

    def create_local_heroku_setup
      say "Creating local Heroku setup"
      build :create_review_apps_setup_script
      build :create_deploy_script
      build :create_heroku_application_manifest_file
    end

    def create_heroku_apps
      if options[:heroku]
        say "Creating Heroku apps"
        build :create_heroku_apps, options[:heroku_flags]
        build :set_heroku_remotes
        build :set_heroku_rails_secrets
        build :set_heroku_application_host
        build :set_heroku_honeybadger_env
        build :set_heroku_backup_schedule
        build :create_heroku_pipeline
        build :configure_automatic_deployment
      end
    end

    def create_github_repo
      if !options[:skip_git] && options[:github]
        say 'Creating Github repo'
        build :create_github_repo, options[:github]
      end
    end

    def setup_segment
      say 'Setting up Segment'
      build :setup_segment
    end

    def setup_dotfiles
      build :copy_dotfiles
    end

    def setup_default_directories
      build :setup_default_directories
    end

    def setup_bundler_audit
      say "Setting up bundler-audit"
      build :setup_bundler_audit
    end

    def setup_spring
      say "Springifying binstubs"
      build :setup_spring
    end

    def copy_miscellaneous_files
      say 'Copying miscellaneous support files'
      build :copy_miscellaneous_files
    end

    def customize_error_pages
      say 'Customizing the 500/404/422 pages'
      build :customize_error_pages
    end

    def remove_config_comment_lines
      build :remove_config_comment_lines
    end

    def remove_routes_comment_lines
      build :remove_routes_comment_lines
    end

    def generate_default
      run("spring stop")
      generate("suspenders:initialize_active_job")
      generate("suspenders:enforce_ssl")
      generate("suspenders:static")
      generate("suspenders:stylesheet_base")
      generate("suspenders:ci")
      generate("suspenders:forms")
      generate("suspenders:db_optimizations")
      generate("suspenders:factories")
      generate("suspenders:lint")
      generate("suspenders:ci")
      generate("suspenders:forms")
    end

    def outro
      say 'Congratulations! You just pulled our suspenders.'
      say honeybadger_outro
    end

    def self.banner
      "suspenders #{arguments.map(&:usage).join(' ')} [options]"
    end

    protected

    def get_builder_class
      Suspenders::AppBuilder
    end

    def using_active_record?
      !options[:skip_active_record]
    end

    private

    def honeybadger_outro
      "Run 'bundle exec honeybadger heroku install' with your API key#{honeybadger_message_suffix}."
    end

    def honeybadger_message_suffix
      if options[:heroku]
        " unless you're using the Heroku Honeybadger add-on"
      end
    end
  end
end

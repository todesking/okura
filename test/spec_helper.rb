if ENV['COVERAGE'] == '1'
  require 'simplecov'
  # カバレッジ測定のためには､ PROJECT_ROOT/.simplecov 内で
  # SimpleCov.start すること
end

